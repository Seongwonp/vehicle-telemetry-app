import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../dashboard_view_state.dart';

/// 탭 맨 위의 결론 한 덩어리 — 연결 상태와 기준 초과를 **한곳에서** 말한다.
///
/// 예전에는 연결 띠와 '이상 값 감지됨' 배너가 따로 있어, 재연결 중에도 지난 프레임의 배너가
/// 현재 이상처럼 남았다. 색은 역할별로 하나만 쓴다: 기준 초과 danger, 재연결 warning,
/// 데이터 지연 중립(textSecondary) — 빨강을 기준 초과 전용으로 남긴다.
class StatusSummary extends StatelessWidget {
  final DashboardViewState state;

  /// "방금 업데이트" / "14초 전 업데이트"
  final String lastUpdatedText;

  const StatusSummary({
    required this.state,
    required this.lastUpdatedText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final overCount = state.overCount;
    final received = '마지막 수신 ${state.receivedClock} · $lastUpdatedText';

    final (IconData icon, Color tone, String title, String detail) =
        switch (state.connection) {
      DashboardConnectionState.connected when overCount > 0 => (
          Icons.warning_rounded,
          colors.danger,
          '방금 받은 데이터에서 기준 초과 $overCount건',
          _overDetail(),
        ),
      DashboardConnectionState.connected => (
          Icons.check_circle_outline,
          colors.success,
          '현재 수신 데이터에서 감지된 이상 없음',
          '실시간 수신 중 · $lastUpdatedText',
        ),
      DashboardConnectionState.reconnecting => (
          Icons.sync_problem,
          colors.warning,
          '재연결 중 — 지금 상태를 알 수 없음',
          received,
        ),
      // 받은 값이 있는 상태에서는 DashboardTab이 connecting을 쓰지 않는다(재연결로 둔다).
      // 첫 값 전에는 이 위젯이 아니라 로딩·오류·데이터 없음 화면이 나온다. 방어용 분기다.
      DashboardConnectionState.connecting => (
          Icons.sync,
          colors.warning,
          '연결 확인 중 — 지금 상태를 알 수 없음',
          received,
        ),
      DashboardConnectionState.stale => (
          Icons.schedule,
          colors.textSecondary,
          '데이터 지연 — 지금 상태를 알 수 없음',
          received,
        ),
    };

    final live = state.isLive;
    return Semantics(
      container: true,
      liveRegion: !live || overCount > 0,
      label: '$title. $detail',
      excludeSemantics: true,
      child: Container(
        key: const Key('status_summary'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: state.connection == DashboardConnectionState.stale
              ? colors.surface
              : tone.withValues(alpha: 0.08),
          borderRadius: Radii.mdAll,
          border: Border.all(
            color: state.connection == DashboardConnectionState.stale
                ? colors.borderStrong
                : tone.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: tone),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: FontSizes.body,
                      fontWeight: FontWeight.w700,
                      color: live && overCount == 0 ? colors.textPrimary : tone,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: FontSizes.caption,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _overDetail() {
    final parts = [
      for (final r in state.readings)
        if (r.over) r.label,
      if (state.dtcCodes.isNotEmpty) 'DTC ${state.dtcCodes.length}개',
    ];
    return '${parts.join(' · ')} · $lastUpdatedText';
  }
}
