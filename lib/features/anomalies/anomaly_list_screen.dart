import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/anomaly.dart';
import '../../core/providers/anomaly_providers.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/anomaly_card.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';

enum _PeriodFilter { all, day, week }

class AnomalyListScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  const AnomalyListScreen({required this.vehicleId, super.key});

  @override
  ConsumerState<AnomalyListScreen> createState() => _AnomalyListScreenState();
}

class _AnomalyListScreenState extends ConsumerState<AnomalyListScreen> {
  String _severityFilter = '전체';
  _PeriodFilter _periodFilter = _PeriodFilter.all;

  List<Anomaly> _applyFilters(List<Anomaly> anomalies) {
    final now = DateTime.now();
    return anomalies.where((a) {
      if (_severityFilter != '전체' && a.severity != _severityFilter) {
        return false;
      }
      switch (_periodFilter) {
        case _PeriodFilter.day:
          return now.difference(a.detectedAt).inHours <= 24;
        case _PeriodFilter.week:
          return now.difference(a.detectedAt).inDays <= 7;
        case _PeriodFilter.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final anomaliesAsync = ref.watch(anomaliesProvider(widget.vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이상 이력',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.vehicleId,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          // 로딩/에러 중엔 건수 배지를 안 보여준다 — 로딩 중엔 아직 값이 없고,
          // 에러 중엔 0건처럼 보이면 "정상"으로 오인될 수 있다.
          anomaliesAsync.maybeWhen(
            data: (anomalies) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: anomalies.isEmpty
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${anomalies.length}건',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: anomalies.isEmpty
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      // 조회 실패(error)와 "이상 이벤트 없음"(data가 빈 리스트, 정상)을
      // AsyncValue가 애초에 서로 다른 상태로 분리해주기 때문에, 예전처럼 catch에서
      // 빈 리스트로 남겨둬 실패가 "정상"으로 위장되는 실수 자체가 구조적으로 불가능하다.
      body: anomaliesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AnomalyErrorView(
          onRetry: () => ref.invalidate(anomaliesProvider(widget.vehicleId)),
        ),
        data: (anomalies) {
          final filtered = _applyFilters(anomalies);
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(anomaliesProvider(widget.vehicleId).future),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    if (anomalies.isNotEmpty) _FilterBar(
                      severity: _severityFilter,
                      period: _periodFilter,
                      onSeverityChanged: (v) =>
                          setState(() => _severityFilter = v),
                      onPeriodChanged: (v) =>
                          setState(() => _periodFilter = v),
                    ),
                    Expanded(
                      child: anomalies.isEmpty
                          ? const AnomalyEmptyView()
                          : filtered.isEmpty
                              ? const AnomalyEmptyView(filtered: true)
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 4, 16, 32),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) =>
                                      AnomalyCard(anomaly: filtered[i]),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final option in _severityOptions) ...[
              _FilterChip(
                label: option,
                selected: severity == option,
                onTap: () => onSeverityChanged(option),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: AppTheme.border,
            ),
            for (final entry in _periodLabels.entries) ...[
              _FilterChip(
                label: entry.value,
                selected: period == entry.key,
                onTap: () => onPeriodChanged(entry.key),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
