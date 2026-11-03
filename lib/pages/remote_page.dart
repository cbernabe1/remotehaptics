import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/remote_config.dart';
import '../models/remote_models.dart';
import '../models/vibration_models.dart';
import '../providers/app_state.dart';
import '../providers/remote_control_controller.dart';
import '../utils/remote_validator.dart';
import '../widgets/app_widgets.dart';
import '../widgets/vibration_graph.dart';

class RemotePage extends ConsumerStatefulWidget {
  const RemotePage({super.key});

  @override
  ConsumerState<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends ConsumerState<RemotePage> {
  late final TextEditingController _relayController;
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final AppLifecycleListener _lifecycle;
  RemoteRole _mode = RemoteRole.host;

  @override
  void initState() {
    super.initState();
    _relayController = TextEditingController(
      text: RemoteConfig.defaultRelayUrl,
    );
    _nameController = TextEditingController(
      text: RemoteConfig.defaultDisplayName,
    );
    _codeController = TextEditingController();
    _lifecycle = AppLifecycleListener(onHide: _handleLifecycleHide);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _relayController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(remoteControllerProvider);
    final capability = ref.watch(capabilityProvider);
    final capabilityReport = capability.asData?.value;
    final settings = ref.watch(settingsControllerProvider);
    final canHost =
        (capabilityReport?.hasActuator ?? false) && settings.appHapticsEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Remote control')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (capabilityReport?.isPreview ?? false) const PreviewNotice(),
          if (remote.phase == RemotePhase.idle)
            _buildSetup(context, capabilityReport, settings, canHost)
          else if (remote.phase == RemotePhase.connecting)
            _buildConnecting(remote)
          else if (remote.phase == RemotePhase.waitingForRoom)
            _buildWaitingRoom(remote)
          else if (remote.phase == RemotePhase.awaitingApproval)
            remote.isHost
                ? _buildApproval(remote)
                : _buildControllerWaiting(remote)
          else if (remote.phase == RemotePhase.active)
            remote.isHost
                ? _buildHostActive(remote)
                : _buildControllerActive(remote)
          else
            _buildFinished(remote),
          const SizedBox(height: 4),
          const _RemoteSafetyNote(),
        ],
      ),
    );
  }

  Widget _buildSetup(
    BuildContext context,
    CapabilityReport? capabilityReport,
    AppSettings settings,
    bool canHost,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect two phones.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'One phone hosts; the other controls app haptics after the host approves.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<RemoteRole>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: RemoteRole.host,
                icon: Icon(Icons.wifi_tethering_rounded),
                label: Text('Host'),
              ),
              ButtonSegment(
                value: RemoteRole.controller,
                icon: Icon(Icons.touch_app_rounded),
                label: Text('Control'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.first);
            },
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: _mode == RemoteRole.host
              ? 'Host this phone'
              : 'Control a phone',
          subtitle: _mode == RemoteRole.host
              ? 'The other phone can adjust this phone after you approve.'
              : 'Enter the room code shown on the host phone.',
          icon: _mode == RemoteRole.host
              ? Icons.phone_android_rounded
              : Icons.touch_app_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_mode == RemoteRole.controller) ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      RemoteValidator.codeLength,
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Room code',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _nameController,
                maxLength: RemoteValidator.maxDisplayNameLength,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  helperText: 'Shown on the other phone',
                  counterText: '',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _relayController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Relay server',
                  helperText:
                      'Both phones must use the same ws:// or wss:// URL',
                  prefixIcon: Icon(Icons.dns_rounded),
                ),
              ),
              if (_mode == RemoteRole.host) ...[
                const SizedBox(height: 14),
                if (settings.appHapticsEnabled == false)
                  _InlineNotice(
                    icon: Icons.volume_off_rounded,
                    message:
                        'App haptics are disabled. Enable them before hosting.',
                    action: TextButton(
                      onPressed: () =>
                          ref.read(selectedTabProvider.notifier).select(2),
                      child: const Text('Open Settings'),
                    ),
                  )
                else if (capabilityReport?.hasActuator != true)
                  const _InlineNotice(
                    icon: Icons.sensors_off_rounded,
                    message:
                        'This environment does not report a haptic actuator.',
                  ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _mode == RemoteRole.host
                      ? canHost
                            ? _startHost
                            : null
                      : _joinRoom,
                  icon: Icon(
                    _mode == RemoteRole.host
                        ? Icons.wifi_tethering_rounded
                        : Icons.login_rounded,
                  ),
                  label: Text(
                    _mode == RemoteRole.host ? 'Create room code' : 'Join room',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnecting(RemoteState remote) {
    return _StatusCard(
      icon: Icons.sync_rounded,
      title: 'Connecting',
      message: remote.message ?? 'Connecting to the relay...',
      action: OutlinedButton(
        onPressed: _disconnect,
        child: const Text('Cancel'),
      ),
      child: const LinearProgressIndicator(),
    );
  }

  Widget _buildWaitingRoom(RemoteState remote) {
    final theme = Theme.of(context);
    final code = remote.roomCode ?? '------';
    return SectionCard(
      title: 'Room code',
      subtitle: 'Share it only with the person you want to control this phone.',
      icon: Icons.tag_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            _formatCode(code),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remote.message ?? 'Waiting for someone to join.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _copyCode(code),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy code'),
              ),
              OutlinedButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel room'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApproval(RemoteState remote) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Approve connection',
      subtitle: 'Every new controller needs your approval.',
      icon: Icons.shield_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person_pin_circle_rounded,
              size: 32,
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${remote.peerName ?? 'The other phone'} wants to control app haptics on this phone.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Only accept if you know this person. You can end the session at any time.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    ref.read(remoteControllerProvider.notifier).approve(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Accept'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(remoteControllerProvider.notifier).decline(),
                icon: const Icon(Icons.block_rounded),
                label: const Text('Decline'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControllerWaiting(RemoteState remote) {
    return _StatusCard(
      icon: Icons.hourglass_top_rounded,
      title: 'Waiting for approval',
      message:
          'Room ${_formatCode(remote.roomCode ?? '------')}. The host must accept before you can send haptics.',
      action: OutlinedButton(
        onPressed: _disconnect,
        child: const Text('Cancel'),
      ),
      child: const LinearProgressIndicator(),
    );
  }

  Widget _buildHostActive(RemoteState remote) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Remote session active',
      subtitle: '${remote.peerName ?? 'The controller'} can adjust haptics.',
      icon: Icons.wifi_tethering_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                remote.remotePlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.pause_circle_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remote.remotePlaying
                      ? 'Vibrating at ${remote.strengthPercent}%'
                      : 'Remote is idle',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${remote.strengthPercent}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: remote.strengthPercent / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
          if (remote.message != null) ...[
            const SizedBox(height: 10),
            Text(
              remote.message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.stop_circle_rounded),
              label: const Text('End remote session'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerActive(RemoteState remote) {
    final theme = Theme.of(context);
    final peer = remote.peerName ?? 'the host';
    return SectionCard(
      title: 'Controlling $peer',
      subtitle:
          'Press and hold the graph to vibrate; slide to change strength.',
      icon: Icons.touch_app_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                remote.remotePlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.pause_circle_outline_rounded,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remote.remotePlaying
                      ? '$peer is vibrating at ${remote.strengthPercent}%'
                      : '$peer is idle',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VibrationGraph(
            value: remote.strengthPercent,
            onChanged: (value) =>
                ref.read(remoteControllerProvider.notifier).setStrength(value),
            onHoldStart: () =>
                ref.read(remoteControllerProvider.notifier).startHold(),
            onHoldEnd: () =>
                ref.read(remoteControllerProvider.notifier).stopHold(),
          ),
          const SizedBox(height: 12),
          Text(
            'The pulse runs for as long as you hold, up to 5 seconds. Internet delay can affect timing.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (remote.message != null) ...[
            const SizedBox(height: 10),
            Text(
              remote.message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.stop_circle_rounded),
              label: const Text('End remote session'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished(RemoteState remote) {
    final isError = remote.phase == RemotePhase.error;
    return _StatusCard(
      icon: isError ? Icons.error_outline_rounded : Icons.link_off_rounded,
      title: isError ? 'Connection problem' : 'Session ended',
      message: remote.message ?? 'The remote session is no longer active.',
      action: FilledButton.icon(
        onPressed: () => ref.read(remoteControllerProvider.notifier).reset(),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Start again'),
      ),
    );
  }

  Future<void> _startHost() async {
    FocusScope.of(context).unfocus();
    final error = _validateFields(requireCode: false);
    if (error != null) {
      _showMessage(error);
      return;
    }
    await ref
        .read(remoteControllerProvider.notifier)
        .host(
          relayUrl: _relayController.text.trim(),
          displayName: _nameController.text.trim(),
        );
  }

  Future<void> _joinRoom() async {
    FocusScope.of(context).unfocus();
    final error = _validateFields(requireCode: true);
    if (error != null) {
      _showMessage(error);
      return;
    }
    await ref
        .read(remoteControllerProvider.notifier)
        .join(
          relayUrl: _relayController.text.trim(),
          code: RemoteValidator.normalizeCode(_codeController.text),
          displayName: _nameController.text.trim(),
        );
  }

  String? _validateFields({required bool requireCode}) {
    final nameError = RemoteValidator.validateDisplayName(_nameController.text);
    if (nameError != null) {
      return nameError;
    }
    final relayError = RemoteValidator.validateRelayUrl(_relayController.text);
    if (relayError != null) {
      return relayError;
    }
    if (requireCode) {
      return RemoteValidator.validateCode(_codeController.text);
    }
    return null;
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) {
      return;
    }
    _showMessage('Room code copied.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _disconnect() async {
    await ref.read(remoteControllerProvider.notifier).disconnect();
  }

  void _handleLifecycleHide() {
    final remote = ref.read(remoteControllerProvider);
    if (remote.isActive || remote.isBusy) {
      unawaited(ref.read(remoteControllerProvider.notifier).disconnect());
    }
  }

  String _formatCode(String code) {
    if (code.length != 6) {
      return code;
    }
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.child,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 34,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (child != null) ...[const SizedBox(height: 18), child!],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          action ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _RemoteSafetyNote extends StatelessWidget {
  const _RemoteSafetyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Every session needs the host\'s approval. Only this app can vibrate the phone. Sessions end when either app leaves the foreground.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
