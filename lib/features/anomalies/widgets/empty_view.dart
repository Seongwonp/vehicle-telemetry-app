import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AnomalyEmptyView extends StatelessWidget {
  const AnomalyEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 40, color: AppTheme.success),
          ),
          const SizedBox(height: 16),
          const Text('이상 이벤트 없음',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('차량이 정상 범위로 주행 중입니다.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
