import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_theme.dart';

class AnomalyErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const AnomalyErrorView({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 64, color: colors.textTertiary),
          const SizedBox(height: Spacing.md),
          const Text('이상 이력을 불러오지 못했습니다',
              style: TextStyle(
                  fontSize: FontSizes.subtitle, fontWeight: FontWeight.w500)),
          const SizedBox(height: Spacing.xs),
          // 조회 실패가 "이상 없음"으로 읽히지 않게 다른 문구·아이콘을 쓴다.
          Text('네트워크 연결 또는 로그인 상태를 확인하세요.',
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
