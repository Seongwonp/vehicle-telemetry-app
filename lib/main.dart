import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/auth/auth_provider.dart';
import 'core/navigation/navigator_key.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/landing_screen.dart';
import 'features/vehicle_list/vehicle_list_screen.dart';
import 'core/api/api_client.dart';

void main() {
  ApiClient.validateConfiguration();
  timeago.setLocaleMessages('ko', timeago.KoMessages());
  runApp(const ProviderScope(child: TelemetryApp()));
}

class TelemetryApp extends ConsumerWidget {
  const TelemetryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'TELEMETRIX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: switch (authStatus) {
        AuthStatus.initializing => const _AuthInitializingScreen(),
        AuthStatus.authenticated => const VehicleListScreen(),
        AuthStatus.unauthenticated => const LandingScreen(),
      },
    );
  }
}

class _AuthInitializingScreen extends StatelessWidget {
  const _AuthInitializingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: '로그인 상태 확인 중',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
