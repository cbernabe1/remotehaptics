import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_strings.dart';
import 'pages/home_page.dart';
import 'pages/remote_page.dart';
import 'pages/settings_page.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';

class VibrationControlApp extends StatelessWidget {
  const VibrationControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = [HomePage(), RemotePage(), SettingsPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.35 : 0.08,
                ),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: ref
                  .read(selectedTabProvider.notifier)
                  .select,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: AppStrings.home,
                ),
                NavigationDestination(
                  icon: Icon(Icons.wifi_tethering_outlined),
                  selectedIcon: Icon(Icons.wifi_tethering_rounded),
                  label: AppStrings.remote,
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: AppStrings.settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
