import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_provider.dart';
import 'features/login/login_screen.dart';
import 'features/vehicle_list/vehicle_list_screen.dart';

void main() {
  runApp(const ProviderScope(child: TelemetryApp()));
}

class TelemetryApp extends ConsumerWidget {
  const TelemetryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);

    return MaterialApp(
      title: 'Vehicle Telemetry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const VehicleListScreen() : const LoginScreen(),
    );
  }
}
