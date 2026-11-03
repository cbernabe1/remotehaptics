import { randomInt, randomUUID } from 'node:crypto';
import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';

import { WebSocket, WebSocketServer } from 'ws';

const DEFAULTS = {
  port: Number(process.env.PORT ?? 8080),
  host: process.env.HOST ?? '0.0.0.0',
  path: '/ws',
  waitingRoomMs: 10 * 60 * 1000,
  approvalMs: 60 * 1000,
  sessionMaxMs: 30 * 60 * 1000,
  maxRooms: 1000,
  maxNameLength: 24,
  trustProxy: process.env.TRUST_PROXY === '1',
  rateWindowMs: 60 * 1000,
  createRoomLimit: 10,
  joinRoomLimit: 20,
  log: (message) => console.log(message),
};

const HAPTIC_ACTIONS = new Set(['start', 'update', 'stop']);

export function createRelayServer(overrides = {}) {
  const config = { ...DEFAULTS, ...overrides };
  const rooms = new Map();
  const clients = new Map();
  const attempts = new Map();

  const httpServer = createServer((request, response) => {
    if (request.url === '/healthz') {
      response.writeHead(200, { 'content-type': 'application/json' });
      response.end(JSON.stringify({ ok: true, rooms: rooms.size }));
      return;
    }

    response.writeHead(404, { 'content-type': 'application/json' });
    response.end(JSON.stringify({ error: 'not_found' }));
  });

  const wss = new WebSocketServer({
    server: httpServer,
    path: config.path,
    maxPayload: 4096,
  });

  wss.on('connection', (socket, request) => {
    const client = {
      id: randomUUID(),
      socket,
      role: null,
      roomCode: null,
      name: 'Phone',
      ip: clientIp(request, config),
    };
    clients.set(client.id, client);
    socket.isAlive = true;

    socket.on('pong', () => {
      socket.isAlive = true;
    });
    socket.on('message', (data) => handleMessage(client, data));
    socket.on('close', () => handleClose(client));
    socket.on('error', () => {});
  });

  const heartbeat = setInterval(() => {
    for (const socket of wss.clients) {
      if (socket.isAlive === false) {
        socket.terminate();
        continue;
      }
      socket.isAlive = false;
      socket.ping();
    }
  }, 30 * 1000);
  heartbeat.unref();

  const sweep = setInterval(() => {
    const now = Date.now();
    for (const [key, bucket] of attempts) {
      if (now - bucket.start >= config.rateWindowMs) {
        attempts.delete(key);
      }
    }
  }, 60 * 1000);
  sweep.unref();

  function handleMessage(client, data) {
    let message;
    try {
      const parsed = JSON.parse(data.toString());
      if (!isObject(parsed)) {
        throw new Error('Message must be an object.');
      }
      message = parsed;
    } catch {
      sendError(client, 'invalid_json', 'Send a valid JSON object.');
      return;
    }

    switch (message.type) {
      case 'create_room':
        createRoom(client, message);
        break;
      case 'join_room':
        joinRoom(client, message);
        break;
      case 'join_decision':
        decideJoin(client, message);
        break;
      case 'haptic':
        relayHaptic(client, message);
        break;
      case 'haptic_status':
        relayHapticStatus(client, message);
        break;
      case 'leave':
        leave(client);
        break;
      case 'ping':
        send(client, { type: 'pong' });
        break;
      default:
        sendError(client, 'unknown_type', 'Unknown message type.');
    }
  }

  function createRoom(client, message) {
    if (client.roomCode != null) {
      sendError(client, 'already_in_room', 'Leave the current room first.');
      return;
    }
    if (!allowAttempt(client.ip, 'create')) {
      sendError(client, 'rate_limited', 'Too many room attempts. Wait a minute.');
      return;
    }
    if (rooms.size >= config.maxRooms) {
      sendError(client, 'relay_full', 'The relay is busy. Try again shortly.');
      return;
    }

    const code = uniqueRoomCode();
    const room = {
      code,
      host: client,
      controller: null,
      pendingController: null,
      state: 'waiting',
      createdAt: Date.now(),
      expiresAt: 0,
      timer: null,
    };
    rooms.set(code, room);
    client.role = 'host';
    client.roomCode = code;
    client.name = cleanName(message.name, config.maxNameLength, 'Host phone');
    armRoom(room, config.waitingRoomMs, () =>
      expireRoom(room, 'This room expired. Create a new one.'),
    );
    send(client, { type: 'room_created', code });
  }

  function joinRoom(client, message) {
    if (client.roomCode != null) {
      sendError(client, 'already_in_room', 'Leave the current room first.');
      return;
    }
    if (!allowAttempt(client.ip, 'join')) {
      sendError(client, 'rate_limited', 'Too many join attempts. Wait a minute.');
      return;
    }

    const code = normalizeCode(message.code);
    const room = rooms.get(code);
    if (code.length !== 6 || !/^\d{6}$/.test(code) || room == null) {
      sendError(client, 'room_not_found', 'That room code is not active.');
      return;
    }
    if (room.state !== 'waiting' || room.pendingController != null) {
      sendError(client, 'room_busy', 'That room is already in use.');
      return;
    }

    room.pendingController = client;
    room.state = 'pending';
    client.role = 'pending';
    client.roomCode = code;
    client.name = cleanName(
      message.name,
      config.maxNameLength,
      'Controller phone',
    );

    send(room.host, { type: 'join_request', name: client.name });
    send(client, { type: 'join_waiting' });
    armRoom(room, config.approvalMs, () => expireApproval(room));
  }

  function decideJoin(client, message) {
    const room = roomFor(client);
    if (room == null || room.host !== client || room.state !== 'pending') {
      sendError(client, 'not_host', 'Only the host can answer this request.');
      return;
    }

    const pending = room.pendingController;
    if (pending == null || pending.socket.readyState !== WebSocket.OPEN) {
      room.pendingController = null;
      room.state = 'waiting';
      armRoom(room, config.waitingRoomMs, () =>
        expireRoom(room, 'This room expired. Create a new one.'),
      );
      sendError(client, 'join_expired', 'The join request expired.');
      return;
    }

    if (message.approved !== true) {
      send(pending, {
        type: 'join_declined',
        message: 'The host declined the request.',
      });
      detach(pending);
      room.pendingController = null;
      room.state = 'waiting';
      armRoom(room, config.waitingRoomMs, () =>
        expireRoom(room, 'This room expired. Create a new one.'),
      );
      send(client, { type: 'join_cancelled', message: 'Request declined.' });
      return;
    }

    room.pendingController = null;
    room.controller = pending;
    room.state = 'active';
    pending.role = 'controller';
    armRoom(room, config.sessionMaxMs, () =>
      expireRoom(room, 'The remote session reached its time limit.'),
    );

    send(room.host, {
      type: 'session_started',
      role: 'host',
      peerName: pending.name,
      code: room.code,
    });
    send(pending, {
      type: 'session_started',
      role: 'controller',
      peerName: room.host.name,
      code: room.code,
    });
  }

  function relayHaptic(client, message) {
    const room = roomFor(client);
    if (
      room == null ||
      room.state !== 'active' ||
      room.controller !== client
    ) {
      sendError(client, 'not_controller', 'Only the paired controller can do that.');
      return;
    }

    const action = message.action;
    if (!HAPTIC_ACTIONS.has(action)) {
      sendError(client, 'invalid_action', 'Use start, update, or stop.');
      return;
    }

    const outgoing = { type: 'haptic', action };
    if (action !== 'stop') {
      if (!isStrength(message.strength)) {
        sendError(client, 'invalid_strength', 'Strength must be 1-100.');
        return;
      }
      outgoing.strength = message.strength;
    }

    send(room.host, outgoing);
  }

  function relayHapticStatus(client, message) {
    const room = roomFor(client);
    if (room == null || room.state !== 'active' || room.host !== client) {
      sendError(client, 'not_host', 'Only the paired host can report status.');
      return;
    }
    if (typeof message.playing !== 'boolean') {
      sendError(client, 'invalid_status', 'Status must include playing.');
      return;
    }

    send(room.controller, {
      type: 'haptic_status',
      playing: message.playing,
      strength: isStrength(message.strength) ? message.strength : 0,
      message: cleanMessage(message.message),
    });
  }

  function leave(client) {
    const room = roomFor(client);
    if (room != null) {
      closeRoom(room, client, 'The other phone left the session.');
    }
    detach(client);
    send(client, { type: 'left' });
  }

  function handleClose(client) {
    clients.delete(client.id);
    const room = roomFor(client);
    if (room != null) {
      closeRoom(room, client, 'The other phone disconnected.');
    }
    detach(client);
  }

  function closeRoom(room, except, message) {
    for (const peer of [room.host, room.controller, room.pendingController]) {
      if (peer != null && peer !== except) {
        send(peer, { type: 'peer_left', message });
        detach(peer);
      }
    }
    clearRoom(room);
  }

  function expireApproval(room) {
    if (room.state !== 'pending') {
      return;
    }
    const pending = room.pendingController;
    room.pendingController = null;
    room.state = 'waiting';
    if (pending != null) {
      send(pending, {
        type: 'join_declined',
        message: 'The host did not respond. Try again.',
      });
      detach(pending);
    }
    send(room.host, {
      type: 'join_cancelled',
      message: 'The join request expired.',
    });
    armRoom(room, config.waitingRoomMs, () =>
      expireRoom(room, 'This room expired. Create a new one.'),
    );
  }

  function expireRoom(room, message) {
    for (const peer of [room.host, room.controller, room.pendingController]) {
      if (peer != null) {
        send(peer, { type: 'session_ended', message });
        detach(peer);
      }
    }
    clearRoom(room);
  }

  function clearRoom(room) {
    clearTimeout(room.timer);
    room.timer = null;
    rooms.delete(room.code);
  }

  function armRoom(room, delayMs, onExpire) {
    clearTimeout(room.timer);
    room.expiresAt = Date.now() + delayMs;
    room.timer = setTimeout(onExpire, delayMs);
    room.timer.unref?.();
  }

  function roomFor(client) {
    if (client.roomCode == null) {
      return undefined;
    }
    return rooms.get(client.roomCode);
  }

  function uniqueRoomCode() {
    for (let attempt = 0; attempt < 30; attempt++) {
      const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
      if (!rooms.has(code)) {
        return code;
      }
    }
    throw new Error('Could not allocate a room code.');
  }

  function allowAttempt(ip, action) {
    const now = Date.now();
    const key = `${ip}:${action}`;
    const limit =
      action === 'create' ? config.createRoomLimit : config.joinRoomLimit;
    let bucket = attempts.get(key);
    if (bucket == null || now - bucket.start >= config.rateWindowMs) {
      bucket = { start: now, count: 0 };
      attempts.set(key, bucket);
    }
    bucket.count += 1;
    return bucket.count <= limit;
  }

  function send(client, payload) {
    if (client?.socket.readyState === WebSocket.OPEN) {
      client.socket.send(JSON.stringify(payload));
    }
  }

  function sendError(client, code, message) {
    send(client, { type: 'error', code, message });
  }

  function detach(client) {
    if (client == null) {
      return;
    }
    client.role = null;
    client.roomCode = null;
  }

  function listen(port = config.port, host = config.host) {
    return new Promise((resolve, reject) => {
      const onError = (error) => {
        httpServer.off('listening', onListening);
        reject(error);
      };
      const onListening = () => {
        httpServer.off('error', onError);
        resolve(httpServer.address().port);
      };
      httpServer.once('error', onError);
      httpServer.once('listening', onListening);
      httpServer.listen(port, host);
    });
  }

  async function close() {
    clearInterval(heartbeat);
    clearInterval(sweep);
    for (const room of rooms.values()) {
      clearTimeout(room.timer);
    }
    rooms.clear();
    for (const socket of wss.clients) {
      socket.terminate();
    }
    await new Promise((resolve) => wss.close(() => resolve()));
    if (httpServer.listening) {
      await new Promise((resolve) => httpServer.close(() => resolve()));
    }
  }

  return {
    config,
    httpServer,
    wss,
    rooms,
    listen,
    close,
  };
}

function normalizeCode(value) {
  return typeof value === 'string' ? value.replace(/\s+/g, '') : '';
}

function cleanName(value, maxLength, fallback) {
  if (typeof value !== 'string') {
    return fallback;
  }
  const cleaned = value
    .replace(/[\u0000-\u001F\u007F]/g, '')
    .trim()
    .slice(0, maxLength);
  return cleaned.length > 0 ? cleaned : fallback;
}

function cleanMessage(value) {
  if (typeof value !== 'string') {
    return '';
  }
  return value
    .replace(/[\u0000-\u001F\u007F]/g, '')
    .trim()
    .slice(0, 160);
}

function isObject(value) {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isStrength(value) {
  return Number.isInteger(value) && value >= 1 && value <= 100;
}

function clientIp(request, config) {
  if (config.trustProxy) {
    const forwarded = request.headers['x-forwarded-for'];
    if (typeof forwarded === 'string' && forwarded.length > 0) {
      return forwarded.split(',')[0].trim();
    }
  }
  return request.socket.remoteAddress ?? 'unknown';
}

const isMain =
  process.argv[1] != null &&
  import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMain) {
  const relay = createRelayServer();
  relay
    .listen()
    .then((port) => {
      relay.config.log(
        `Vibration Control relay listening on ${relay.config.host}:${port}${relay.config.path}`,
      );
    })
    .catch((error) => {
      console.error(`Relay failed to start: ${error.message}`);
      process.exitCode = 1;
    });

  const shutdown = async () => {
    await relay.close();
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}
