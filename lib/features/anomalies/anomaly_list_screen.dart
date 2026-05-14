import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/api/api_client.dart';
import '../../core/models/anomaly.dart';

class AnomalyListScreen extends StatefulWidget {
  final String vehicleId;
  const AnomalyListScreen({required this.vehicleId, super.key});

  @override
  State<AnomalyListScreen> createState() => _AnomalyListScreenState();
}

class _AnomalyListScreenState extends State<AnomalyListScreen> {
  List<Anomaly> _anomalies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient().getAnomalies(widget.vehicleId);
      if (mounted) {
        setState(() {
          _anomalies = data
              .map((e) => Anomaly.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이상 이력',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.vehicleId,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _anomalies.isEmpty
                        ? Colors.green.withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_anomalies.length}건',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _anomalies.isEmpty
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _anomalies.isEmpty
              ? _EmptyView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _anomalies.length,
                    itemBuilder: (context, i) =>
                        _AnomalyCard(anomaly: _anomalies[i]),
                  ),
                ),
    );
  }
}

// ── 이상 이벤트 카드 ──────────────────────────────────────────

class _AnomalyCard extends StatelessWidget {
  final Anomaly anomaly;
  const _AnomalyCard({required this.anomaly});

  Color get _severityColor =>
      anomaly.isHigh ? Colors.redAccent : Colors.orange;

  IconData get _anomalyIcon {
    final type = anomaly.anomalyType.toLowerCase();
    if (type.contains('과열') || type.contains('온도')) return Icons.thermostat;
    if (type.contains('rpm') || type.contains('과부하')) return Icons.rotate_right;
    if (type.contains('배터리') || type.contains('전압')) return Icons.battery_alert;
    if (type.contains('속도') || type.contains('과속')) return Icons.speed;
    if (type.contains('dtc') || type.contains('진단')) return Icons.build_circle;
    return Icons.warning_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 왼쪽 심각도 바
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),

            // 아이콘
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_anomalyIcon, color: color, size: 20),
              ),
            ),

            // 내용
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anomaly.anomalyType,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      anomaly.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 11, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          timeago.format(anomaly.detectedAt, locale: 'ko'),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 심각도 뱃지
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  anomaly.severity,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 이상 없을 때 ──────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 40, color: Colors.greenAccent),
          ),
          const SizedBox(height: 16),
          const Text('이상 이벤트 없음',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('차량이 정상 범위로 주행 중입니다.',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
