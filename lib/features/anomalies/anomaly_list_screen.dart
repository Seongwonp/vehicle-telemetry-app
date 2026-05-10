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
    try {
      final data = await ApiClient().getAnomalies(widget.vehicleId);
      setState(() {
        _anomalies = data
            .map((e) => Anomaly.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('이상 이력 — ${widget.vehicleId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _anomalies.isEmpty
              ? const Center(child: Text('이상 이벤트가 없습니다'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _anomalies.length,
                    itemBuilder: (context, index) {
                      final a = _anomalies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            Icons.warning_amber,
                            color: a.isHigh ? Colors.redAccent : Colors.orange,
                          ),
                          title: Text(a.description),
                          subtitle: Text(timeago.format(a.detectedAt, locale: 'ko')),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: a.isHigh
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a.severity,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    a.isHigh ? Colors.redAccent : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
