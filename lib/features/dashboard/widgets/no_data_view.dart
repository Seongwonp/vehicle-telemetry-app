import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NoDataView extends StatelessWidget {
  final String vehicleId;
  const NoDataView({required this.vehicleId, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sensors_off, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          const Text('데이터 없음',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('시뮬레이터 또는 OBD-II 동글을 연결하세요.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
