import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AnomalyEmptyView extends StatelessWidget {
  // 필터 때문에 0건인 경우(filtered)와 진짜 이상 이벤트가 없는 경우를
  // 다른 문구로 구분한다 — 전자를 "정상 주행 중"으로 오인하지 않도록.
  final bool filtered;

  const AnomalyEmptyView({this.filtered = false, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: (filtered ? colors.textSecondary : colors.success)
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              filtered ? Icons.filter_alt_off_outlined : Icons.check_circle_outline,
              size: 40,
              color: filtered ? colors.textSecondary : colors.success,
            ),
          ),
          const SizedBox(height: 16),
          Text(filtered ? '조건에 맞는 이벤트 없음' : '이상 이벤트 없음',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            filtered ? '필터를 조정해보세요.' : '차량이 정상 범위로 주행 중입니다.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
