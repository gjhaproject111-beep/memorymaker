import 'package:flutter/material.dart';

import 'core/state/services.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'widgets/app_widgets.dart';
import 'widgets/nav_shell.dart';

class PhotographicMemoryApp extends StatelessWidget {
  const PhotographicMemoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photographic Memory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const _StartupGate(),
    );
  }
}

/// Routes to onboarding on a genuine first run, or straight to the
/// dashboard otherwise — decided once, from local settings.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<bool> _hasSeenOnboarding = _check();

  Future<bool> _check() async {
    final settings = await Services.settings.load();
    return settings.hasSeenOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: GradientBackground(child: LoadingView()));
        }
        return snapshot.data! ? const RootShell() : const OnboardingScreen();
      },
    );
  }
}
