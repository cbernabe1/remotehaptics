# lib/providers/remote_control_controller.dart

## Purpose

Owns the remote-session state machine and bridges relay events to local haptic playback.

## Providers

- `remoteServiceFactoryProvider`: creates a `RemoteControlService`; tests override it with a fake.
- `remoteControllerProvider`: exposes `RemoteState` and the controller commands.

## Host flow

1. Connect to the relay and create a room.
2. Wait for a controller join request.
3. Only `approve()` allows the session to become active; `decline()` rejects it.
4. Remote `start` and `update` commands play local app haptics with the same 5-second cap as Home.
5. Remote `stop`, disconnect, approval failure, or session end stops local playback.
6. Host playback status is sent back to the controller.

## Controller flow

1. Connect and join with a six-digit code.
2. Wait for host approval.
3. `setStrength` sends throttled `update` commands.
4. `startHold` sends `start`; `stopHold` sends `stop`; both are capped at 5 seconds.
5. Session end or disconnect cancels pending timers.

## Safety and concurrency

- Every connect attempt has a token so a cancelled connection cannot overwrite newer state.
- A haptic token prevents an older async play result from reporting status after a newer stop.
- Strength updates are debounced by 90 ms to avoid flooding the relay.
- `AppLifecycleListener` in the Remote page disconnects when the app is hidden.
- The host's app-haptics setting still controls whether local playback is allowed.

## Dependencies

- `flutter_riverpod`
- `lib/config/remote_config.dart`
- `lib/models/remote_models.dart`
- `lib/models/vibration_models.dart`
- `lib/services/remote_control_service.dart`
- `lib/services/websocket_remote_control_service.dart`
- `lib/providers/app_state.dart`
