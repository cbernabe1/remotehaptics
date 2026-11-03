import assert from 'node:assert/strict';
import test from 'node:test';

import WebSocket from 'ws';

import { createRelayServer } from '../server.js';

async function startRelay(t) {
  const relay = createRelayServer({
    host: '127.0.0.1',
    port: 0,
    waitingRoomMs: 5000,
    approvalMs: 1000,
    sessionMaxMs: 10000,
    log: () => {},
  });
  const port = await relay.listen();
  t.after(() => relay.close());
  return { relay, url: `ws://127.0.0.1:${port}/ws` };
}

function openSocket(url) {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(url);
    socket.once('open', () => resolve(socket));
    socket.once('error', reject);
  });
}

function watch(socket) {
  const queue = [];
  const waiters = [];

  socket.on('message', (data) => {
    const message = JSON.parse(data.toString());
    const waiter = waiters.shift();
    if (waiter != null) {
      waiter.resolve(message);
    } else {
      queue.push(message);
    }
  });
  socket.on('close', () => {
    while (waiters.length > 0) {
      waiters.shift().reject(new Error('Socket closed while waiting.'));
    }
  });

  return function next(timeoutMs = 3000) {
    if (queue.length > 0) {
      return Promise.resolve(queue.shift());
    }
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        const index = waiters.findIndex((waiter) => waiter.timer === timer);
        if (index >= 0) {
          waiters.splice(index, 1);
        }
        reject(new Error('Timed out waiting for a relay message.'));
      }, timeoutMs);
      waiters.push({
        timer,
        resolve: (message) => {
          clearTimeout(timer);
          resolve(message);
        },
        reject: (error) => {
          clearTimeout(timer);
          reject(error);
        },
      });
    });
  };
}

async function pairPhones(t, relayUrl) {
  const host = await openSocket(relayUrl);
  const hostNext = watch(host);
  host.send(JSON.stringify({ type: 'create_room', name: 'Host phone' }));
  const created = await hostNext();
  assert.equal(created.type, 'room_created');

  const controller = await openSocket(relayUrl);
  const controllerNext = watch(controller);
  controller.send(
    JSON.stringify({
      type: 'join_room',
      code: created.code,
      name: 'Controller phone',
    }),
  );

  const joinRequest = await hostNext();
  assert.equal(joinRequest.type, 'join_request');
  assert.equal(joinRequest.name, 'Controller phone');
  assert.equal((await controllerNext()).type, 'join_waiting');

  host.send(JSON.stringify({ type: 'join_decision', approved: true }));
  const hostStarted = await hostNext();
  const controllerStarted = await controllerNext();
  assert.equal(hostStarted.type, 'session_started');
  assert.equal(hostStarted.role, 'host');
  assert.equal(hostStarted.peerName, 'Controller phone');
  assert.equal(controllerStarted.type, 'session_started');
  assert.equal(controllerStarted.role, 'controller');

  t.after(() => {
    controller.close();
    host.close();
  });

  return { host, hostNext, controller, controllerNext, code: created.code };
}

test('pairs phones, relays haptics, and relays host status', async (t) => {
  const { url } = await startRelay(t);
  const { host, hostNext, controller, controllerNext } = await pairPhones(t, url);

  controller.send(
    JSON.stringify({ type: 'haptic', action: 'start', strength: 64 }),
  );
  const start = await hostNext();
  assert.deepEqual(start, { type: 'haptic', action: 'start', strength: 64 });

  host.send(
    JSON.stringify({
      type: 'haptic_status',
      playing: true,
      strength: 64,
      message: 'Playing',
    }),
  );
  assert.deepEqual(await controllerNext(), {
    type: 'haptic_status',
    playing: true,
    strength: 64,
    message: 'Playing',
  });

  controller.send(JSON.stringify({ type: 'haptic', action: 'stop' }));
  assert.deepEqual(await hostNext(), { type: 'haptic', action: 'stop' });

  host.send(
    JSON.stringify({
      type: 'haptic_status',
      playing: false,
      strength: 64,
      message: 'Stopped',
    }),
  );
  assert.equal((await controllerNext()).playing, false);
});

test('declines a request without closing the host room', async (t) => {
  const { url } = await startRelay(t);
  const host = await openSocket(url);
  const hostNext = watch(host);
  host.send(JSON.stringify({ type: 'create_room', name: 'Host' }));
  const created = await hostNext();

  const first = await openSocket(url);
  const firstNext = watch(first);
  first.send(
    JSON.stringify({ type: 'join_room', code: created.code, name: 'First' }),
  );
  assert.equal((await hostNext()).type, 'join_request');
  assert.equal((await firstNext()).type, 'join_waiting');

  host.send(JSON.stringify({ type: 'join_decision', approved: false }));
  assert.equal((await firstNext()).type, 'join_declined');
  assert.equal((await hostNext()).type, 'join_cancelled');

  const second = await openSocket(url);
  const secondNext = watch(second);
  second.send(
    JSON.stringify({ type: 'join_room', code: created.code, name: 'Second' }),
  );
  const secondRequest = await hostNext();
  assert.equal(secondRequest.type, 'join_request');
  assert.equal(secondRequest.name, 'Second');
  assert.equal((await secondNext()).type, 'join_waiting');

  t.after(() => {
    second.close();
    first.close();
    host.close();
  });
});

test('rejects haptic messages from the host and approvals from a controller', async (t) => {
  const { url } = await startRelay(t);
  const { host, hostNext, controller, controllerNext } = await pairPhones(t, url);

  host.send(
    JSON.stringify({ type: 'haptic', action: 'start', strength: 50 }),
  );
  const hostError = await hostNext();
  assert.equal(hostError.type, 'error');
  assert.equal(hostError.code, 'not_controller');

  controller.send(JSON.stringify({ type: 'join_decision', approved: true }));
  const controllerError = await controllerNext();
  assert.equal(controllerError.type, 'error');
  assert.equal(controllerError.code, 'not_host');
});

test('ends the session when the controller disconnects', async (t) => {
  const { url } = await startRelay(t);
  const { host, hostNext, controller } = await pairPhones(t, url);

  controller.close();
  const left = await hostNext();
  assert.equal(left.type, 'peer_left');
  assert.match(left.message, /disconnected/i);
});
