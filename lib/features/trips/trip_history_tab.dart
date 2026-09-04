import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/trip.dart';
import '../../core/providers/trip_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

// 차량 상세 화면(VehicleDetailScreen)의 네 번째 탭 — 주행 히스토리를
// 트립(연속 주행 구간) 단위로 보여준다. 백엔드가 수신 간격(3분) 기준으로
// 알아서 구간을 나눠주므로 여기선 조회 기간만 고르고 결과를 렌더링한다.
class TripHistoryTab extends ConsumerStatefulWidget {
  final String vehicleId;
  const TripHistoryTab({required this.vehicleId, super.key});

  @override
  ConsumerState<TripHistoryTab> createState() => _TripHistoryTabState();
}

class _TripHistoryTabState extends ConsumerState<TripHistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _hourOptions = [1, 3, 6];

  int _hours = 1;
  List<Trip> _lastTrips = const [];

  TripQuery get _query => TripQuery(vehicleId: widget.vehicleId, hours: _hours);

  Future<void> _refresh() => ref.refresh(tripsProvider(_query).future);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tripsAsync = ref.watch(tripsProvider(_query));
    if (tripsAsync.hasValue) {
      _lastTrips = tripsAsync.requireValue;
    }

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '주행 기록',
                style: TextStyle(
                    fontSize: FontSizes.body, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final h in _hourOptions)
                    _PeriodChip(
                      label: '$h시간',
                      selected: _hours == h,
                      onTap: () => setState(() => _hours = h),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Expanded(child: _buildBody(tripsAsync)),
      ],
    );
  }

  Widget _buildBody(AsyncValue<List<Trip>> tripsAsync) {
    final isInitialLoading = tripsAsync.isLoading && _lastTrips.isEmpty;
    final initialError = tripsAsync.hasError && _lastTrips.isEmpty;

    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final children = <Widget>[];
    if (tripsAsync.hasError) {
      children.add(_TripError(
        message: tripErrorMessage(tripsAsync.error!),
        onRetry: _refresh,
        compact: !initialError,
      ));
      children.add(const SizedBox(height: Spacing.sm));
    }

    if (_lastTrips.isEmpty && !initialError) {
      children.add(const _EmptyTrips());
    } else {
      for (var i = 0; i < _lastTrips.length; i++) {
        if (i > 0) children.add(const SizedBox(height: Spacing.sm));
        children.add(_TripCard(trip: _lastTrips[i]));
      }
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                Spacing.md, Spacing.xxs, Spacing.md, Spacing.xl),
            children: children,
          ),
        ),
        if (tripsAsync.isLoading && _lastTrips.isNotEmpty)
          const Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

String tripErrorMessage(Object error) {
  if (error is TripParsingException) {
    return '주행 기록 데이터 형식을 확인할 수 없습니다.';
  }
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return '로그인이 만료되었습니다. 다시 로그인해 주세요.';
    }
    if (status == 429) {
      return '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (status != null && status >= 500) {
      return '서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return '서버 응답 시간이 초과되었습니다. 네트워크를 확인해 주세요.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return '네트워크 연결을 확인한 뒤 다시 시도해 주세요.';
    }
  }
  return '주행 기록을 불러오지 못했습니다. 잠시 후 다시 시도하세요.';
}

class _TripError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final bool compact;

  const _TripError({
    required this.message,
    required this.onRetry,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (compact) {
      return Material(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.md),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.error_outline, color: AppTheme.danger),
          title: Text(message,
              style: const TextStyle(fontSize: FontSizes.caption)),
          trailing: IconButton(
            tooltip: '다시 시도',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppTheme.danger),
          const SizedBox(height: Spacing.sm),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: Spacing.md),
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

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.route_outlined,
                size: 36, color: colors.textSecondary),
          ),
          const SizedBox(height: Spacing.md),
          const Text('이 기간엔 주행 기록이 없어요',
              style: TextStyle(
                  fontSize: FontSizes.body, fontWeight: FontWeight.w500)),
          const SizedBox(height: Spacing.xs),
          Text('조회 기간을 늘려보세요.', style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm, vertical: Spacing.xs),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: selected ? primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: FontSizes.caption,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  String _timeRange() {
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final start = trip.startTime.toLocal();
    final end = trip.endTime.toLocal();
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final datePart = '${start.month}/${start.day}';
    return sameDay
        ? '$datePart  ${fmt(start)} ~ ${fmt(end)}'
        : '$datePart ${fmt(start)} ~ ${end.month}/${end.day} ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_outlined,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(_timeRange(),
                    style: const TextStyle(
                        fontSize: FontSizes.caption,
                        fontWeight: FontWeight.w600)),
              ),
              Text('${trip.durationMinutes}분',
                  style: TextStyle(
                      fontSize: FontSizes.caption,
                      color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              _Stat(
                  label: '거리',
                  value: '${trip.distanceKm.toStringAsFixed(1)}km'),
              _Stat(
                  label: '평균속도',
                  value: '${trip.avgSpeedKmh.toStringAsFixed(0)}km/h'),
              _Stat(
                  label: '최고속도',
                  value: '${trip.maxSpeedKmh.toStringAsFixed(0)}km/h'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: FontSizes.badge, color: colors.textTertiary)),
          const SizedBox(height: Spacing.xxs),
          Text(value,
              style: AppTheme.gaugeNumberStyle(
                  fontSize: FontSizes.body, color: colors.textPrimary)),
        ],
      ),
    );
  }
}
