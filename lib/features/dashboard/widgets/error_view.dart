import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DashboardErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const DashboardErrorView({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          const Text('센서 데이터를 불러오지 못했습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('네트워크 연결 또는 로그인 상태를 확인하세요.',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
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
