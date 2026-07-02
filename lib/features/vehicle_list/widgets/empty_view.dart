import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmptyView extends StatelessWidget {
  final VoidCallback onRetry;
  const EmptyView({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car_outlined,
              size: 72, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          const Text('등록된 차량이 없습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('백엔드에 차량을 등록하거나\n시뮬레이터를 실행해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
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
