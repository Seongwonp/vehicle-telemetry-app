import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../add_vehicle_screen.dart';

class EmptyView extends StatelessWidget {
  final VoidCallback onRetry;
  const EmptyView({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 72, color: colors.textTertiary),
          const SizedBox(height: Spacing.md),
          const Text('등록된 차량이 없습니다',
              style: TextStyle(
                  fontSize: FontSizes.subtitle, fontWeight: FontWeight.w500)),
          const SizedBox(height: Spacing.xs),
          Text('차량을 추가하고 OBD-II 동글/시뮬레이터를 연결해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () async {
              final registered = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
              );
              if (registered == true) onRetry();
            },
            icon: const Icon(Icons.add),
            label: const Text('차량 추가'),
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
