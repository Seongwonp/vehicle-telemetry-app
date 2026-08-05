import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/telemetry.dart';
import '../../../core/theme/app_theme.dart';

// 텔레메트리 스펙에 원래부터 lat/lng가 있었는데 화면 어디에서도 안 쓰고
// 있었다 — 대시보드 히스토리(최근 20건)를 그대로 경로 선으로 그려서
// "지금 어디를 달리고 있는지"를 보여준다.
class RouteMap extends StatelessWidget {
  final List<Telemetry> history;
  const RouteMap({required this.history, super.key});

  @override
  Widget build(BuildContext context) {
    // history는 최신순(내림차순)이라 지도에 그릴 땐 오래된 순으로 뒤집는다.
    final points = history.reversed
        .where((t) => t.lat != null && t.lng != null)
        .map((t) => LatLng(t.lat!, t.lng!))
        .toList();

    if (points.length < 2) return const SizedBox.shrink();

    final latest = points.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.map_outlined, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            const Text('주행 경로',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: latest,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.telemetrix',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: latest,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                              border: Border.all(
                                  color: AppTheme.bg, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
