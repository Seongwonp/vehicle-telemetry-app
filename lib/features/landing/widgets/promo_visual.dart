import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 실제 대시보드처럼 보이는 "라이브" 데이터 카드는 로그인 전 화면인데도
/// 로그인된 것 같은 착각을 줄 수 있어서 뺐다. 대신 숫자/실데이터 없이
/// 순수하게 컨셉만 전달하는 홍보용 그래픽으로 교체 — 토스 스타일의
/// 널찍하고 단순한 비주얼을 지향한다.
class PromoVisual extends StatelessWidget {
  const PromoVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.18),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.directions_car_filled_rounded,
                size: 48, color: Colors.white),
          ),
          const SizedBox(height: 28),
          const Text(
            '차량의 지금 상태를\n한눈에',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.4,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '속도부터 이상 징후까지, 로그인하면 바로 확인할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textSecondary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _Pill(label: '실시간 모니터링'),
              _Pill(label: 'AI 진단'),
              _Pill(label: '이상 감지'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
