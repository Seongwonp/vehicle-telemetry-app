import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

class NoDataView extends StatelessWidget {
  final String vehicleId;
  const NoDataView({required this.vehicleId, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors_off, size: 64, color: colors.textTertiary),
          const SizedBox(height: Spacing.md),
          const Text('데이터 없음',
              style: TextStyle(
                  fontSize: FontSizes.subtitle, fontWeight: FontWeight.w500)),
          const SizedBox(height: Spacing.xs),
          Text('시뮬레이터 또는 OBD-II 동글을 연결하세요.',
              style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
