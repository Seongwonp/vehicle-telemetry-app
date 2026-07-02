import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/auth/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/landing_screen.dart';
import 'features/vehicle_list/vehicle_list_screen.dart';

void main() {
  timeago.setLocaleMessages('ko', timeago.KoMessages());
  runApp(const ProviderScope(child: TelemetryApp()));
}

class TelemetryApp extends ConsumerWidget {
  const TelemetryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);

    return MaterialApp(
      title: 'TELEMETRIX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: isLoggedIn ? const VehicleListScreen() : const LandingScreen(),
    );
  }
}
