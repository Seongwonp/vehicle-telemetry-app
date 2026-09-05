import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_theme.dart';

class VehicleListErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const VehicleListErrorView(
      {required this.message, required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 64, color: colors.textTertiary),
          const SizedBox(height: Spacing.md),
          Text(message,
              style: const TextStyle(fontSize: FontSizes.subtitle),
              textAlign: TextAlign.center),
          const SizedBox(height: Spacing.xs),
          Text('백엔드 서버가 실행 중인지 확인하세요.',
              style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('재시도'),
          ),
        ],
      ),
    );
  }
}
