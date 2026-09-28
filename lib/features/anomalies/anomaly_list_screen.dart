import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/anomaly_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/choice_chip.dart';
import 'widgets/anomaly_card.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import '../../core/theme/design_tokens.dart';

enum _PeriodFilter { all, day, week }

// 차량 상세 화면(VehicleDetailScreen)의 두 번째 탭 — 자체 Scaffold/AppBar 없이
// 본문만 그린다.
class AnomalyListTab extends ConsumerStatefulWidget {
  final String vehicleId;
  const AnomalyListTab({required this.vehicleId, super.key});

  @override
  ConsumerState<AnomalyListTab> createState() => _AnomalyListTabState();
}

class _AnomalyListTabState extends ConsumerState<AnomalyListTab>
    with AutomaticKeepAliveClientMixin {
  // TabBarView가 멀리 스와이프하면 탭을 언마운트해버려 필터 선택이나 목록
  // 스크롤 위치가 초기화되는 것을 막는다.
  @override
  bool get wantKeepAlive => true;

  String _severityFilter = '전체';
  _PeriodFilter _periodFilter = _PeriodFilter.all;
  int _page = 0;

  AnomalyQuery get _query => AnomalyQuery(
        vehicleId: widget.vehicleId,
        severity: _severityFilter == '전체' ? null : _severityFilter,
        period: _periodFilter.name,
        page: _page,
      );

  /// 필터가 걸려 있는지. 0건일 때 "차량이 정상 범위로 주행 중"과
  /// "조건에 맞는 이벤트 없음"을 가르는 값이다.
  bool get _filtered =>
      _severityFilter != '전체' || _periodFilter != _PeriodFilter.all;

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수 호출
    final anomaliesAsync = ref.watch(anomalyPageProvider(_query));
    final colors = context.appColors;

    // 조회 실패(error)와 "이상 이벤트 없음"(data가 빈 리스트, 정상)을
    // AsyncValue가 애초에 서로 다른 상태로 분리해주기 때문에, 예전처럼 catch에서
    // 빈 리스트로 남겨둬 실패가 "정상"으로 위장되는 실수 자체가 구조적으로 불가능하다.
    return anomaliesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => AnomalyErrorView(
        onRetry: () => ref.invalidate(anomalyPageProvider(_query)),
      ),
      data: (result) {
        final anomalies = result.content;
        return RefreshIndicator(
          onRefresh: () => ref.refresh(anomalyPageProvider(_query).future),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: ContentWidths.feed),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.md, Spacing.sm, Spacing.md, 0),
                    child: Row(
                      children: [
                        const Text('이상 이력',
                            style: TextStyle(
                                fontSize: FontSizes.body,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm, vertical: Spacing.xxs),
                          decoration: BoxDecoration(
                            color: (anomalies.isEmpty
                                    ? colors.success
                                    : colors.danger)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(Radii.lg),
                          ),
                          child: Text(
                            '${result.totalElements}건',
                            style: TextStyle(
                              fontSize: FontSizes.caption,
                              fontWeight: FontWeight.bold,
                              color: anomalies.isEmpty
                                  ? colors.success
                                  : colors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _FilterBar(
                    severity: _severityFilter,
                    period: _periodFilter,
                    onSeverityChanged: (v) => setState(() {
                      _severityFilter = v;
                      _page = 0;
                    }),
                    onPeriodChanged: (v) => setState(() {
                      _periodFilter = v;
                      _page = 0;
                    }),
                  ),
                  Expanded(
                    // 예전에는 `anomalies.isEmpty`를 두 번 중첩해 물어서 두 번째
                    // 분기(필터 때문에 0건)에 **도달할 수 없었다.** 필터가 걸려
                    // 있어도 "차량이 정상 범위로 주행 중"이라고 말하고 있었다.
                    child: anomalies.isEmpty
                        ? AnomalyEmptyView(filtered: _filtered)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(Spacing.md,
                                Spacing.xxs, Spacing.md, Spacing.xl),
                            itemCount: anomalies.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: Spacing.sm),
                            itemBuilder: (context, i) {
                              if (i < anomalies.length) {
                                return AnomalyCard(anomaly: anomalies[i]);
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: _page == 0
                                        ? null
                                        : () => setState(() => _page--),
                                    child: const Text('이전'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Spacing.sm),
                                    child: Text('${result.page + 1}페이지'),
                                  ),
                                  TextButton(
                                    onPressed: result.hasNext
                                        ? () => setState(() => _page++)
                                        : null,
                                    child: const Text('다음'),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 심각도/기간 필터를 칩으로 보여준다 — 서버가 아직 기간 range 쿼리를 지원하지
// 않아, 넉넉히(최대 100건) 받아온 데이터를 클라이언트에서 걸러낸다.
class _FilterBar extends StatelessWidget {
  final String severity;
  final _PeriodFilter period;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<_PeriodFilter> onPeriodChanged;

  const _FilterBar({
    required this.severity,
    required this.period,
    required this.onSeverityChanged,
    required this.onPeriodChanged,
  });

  static const _severityOptions = ['전체', 'HIGH', 'MEDIUM'];
  static const _periodLabels = {
    _PeriodFilter.all: '전체 기간',
    _PeriodFilter.day: '24시간',
    _PeriodFilter.week: '7일',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.xs, Spacing.md, Spacing.xxs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final option in _severityOptions) ...[
              AppChoiceChip(
                label: option,
                selected: severity == option,
                onTap: () => onSeverityChanged(option),
              ),
              const SizedBox(width: Spacing.xs),
            ],
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
              color: colors.border,
            ),
            for (final entry in _periodLabels.entries) ...[
              AppChoiceChip(
                label: entry.value,
                selected: period == entry.key,
                onTap: () => onPeriodChanged(entry.key),
              ),
              const SizedBox(width: Spacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}
