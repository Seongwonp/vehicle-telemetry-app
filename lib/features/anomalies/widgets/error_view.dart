import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AnomalyErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const AnomalyErrorView({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          const Text('이상 이력을 불러오지 못했습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          // "이상 이벤트 없음"(정상)과 절대 혼동되면 안 되므로 실패는 명시적으로
          // 다른 문구/아이콘으로 보여준다 — 조회 실패를 "정상 주행 중"으로 잘못 안내하지 않기 위함.
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
