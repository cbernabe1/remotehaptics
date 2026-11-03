# lib/pages/remote_page.dart

## Purpose

UI for pairing two phones over the relay.

## Host UI

- Enter display name and relay URL, then create a six-digit room.
- Shows the room code with copy and cancel actions.
- Shows the incoming controller name and requires Accept or Decline.
- Active host view shows the remote strength, playback state, message, and End session.

## Controller UI

- Enter the room code, display name, and relay URL, then join.
- Waits for host approval.
- Active controller view provides a hold-to-vibrate graph, remote playback status, and End session.

## Inputs and outputs

Watches `remoteControllerProvider`, `settingsControllerProvider`, and `capabilityProvider`. Commands go through the remote controller; no WebSocket code lives in the page.

## Safety

- The host must approve every session.
- Hosting is disabled if app haptics are off or no actuator is reported.
- An `AppLifecycleListener` disconnects active or pending sessions when the app is hidden.
- The page shows a persistent note that only this app vibrates the phone and either side can leave.

## Error handling

Invalid code, name, or URL shows a snackbar. Connection, rejection, relay, and disconnect errors are shown in the status card with a Start again action.
