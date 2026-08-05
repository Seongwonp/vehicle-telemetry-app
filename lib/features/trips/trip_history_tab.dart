import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/trip.dart';
import '../../core/theme/app_theme.dart';

// 차량 상세 화면(VehicleDetailScreen)의 네 번째 탭 — 주행 히스토리를
// 트립(연속 주행 구간) 단위로 보여준다. 백엔드가 수신 간격(3분) 기준으로
// 알아서 구간을 나눠주므로 여기선 조회 기간만 고르고 결과를 렌더링한다.
class TripHistoryTab extends StatefulWidget {
  final String vehicleId;
  final ApiClient? apiClient;
  const TripHistoryTab({required this.vehicleId, this.apiClient, super.key});

  @override
  State<TripHistoryTab> createState() => _TripHistoryTabState();
}

class _TripHistoryTabState extends State<TripHistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _hourOptions = [1, 3, 6];

  int _hours = 1;
  bool _loading = true;
  String? _error;
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await (widget.apiClient ?? ApiClient()).getTrips(widget.vehicleId, hours: _hours);
      final trips = data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _trips = trips;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '주행 기록을 불러오지 못했습니다. 잠시 후 다시 시도하세요.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Text('주행 기록',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              for (final h in _hourOptions) ...[
                _PeriodChip(
                  label: '$h시간',
                  selected: _hours == h,
                  onTap: () {
                    setState(() => _hours = h);
                    _load();
                  },
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppTheme.danger),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.route_outlined,
                  size: 36, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('이 기간엔 주행 기록이 없어요',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('조회 기간을 늘려보세요.',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: _trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _TripCard(trip: _trips[i]),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
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
    final datePart =
        '${start.month}/${start.day}';
    return sameDay
        ? '$datePart  ${fmt(start)} ~ ${fmt(end)}'
        : '$datePart ${fmt(start)} ~ ${end.month}/${end.day} ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_timeRange(),
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              Text('${trip.durationMinutes}분',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(label: '거리', value: '${trip.distanceKm.toStringAsFixed(1)}km'),
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: AppTheme.textTertiary)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTheme.gaugeNumberStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
