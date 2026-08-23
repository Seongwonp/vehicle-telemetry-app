import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/telemetry.dart';
import '../../../core/theme/app_theme.dart';

// 텔레메트리 스펙에 원래부터 lat/lng가 있었는데 화면 어디에서도 안 쓰고
// 있었다 — 대시보드 히스토리(최근 20건)를 그대로 경로 선으로 그려서
// "지금 어디를 달리고 있는지"를 보여준다.
class RouteMap extends StatefulWidget {
  final List<Telemetry> history;
  const RouteMap({required this.history, super.key});

  @override
  State<RouteMap> createState() => _RouteMapState();
}

List<LatLng> validRoutePoints(List<Telemetry> history) => history.reversed
    .where((telemetry) =>
        telemetry.lat != null &&
        telemetry.lng != null &&
        telemetry.lat!.isFinite &&
        telemetry.lng!.isFinite &&
        telemetry.lat! >= -90 &&
        telemetry.lat! <= 90 &&
        telemetry.lng! >= -180 &&
        telemetry.lng! <= 180)
    .map((telemetry) => LatLng(telemetry.lat!, telemetry.lng!))
    .toList(growable: false);

class _RouteMapState extends State<RouteMap> {
  static final _copyrightUri =
      Uri.parse('https://www.openstreetmap.org/copyright');
  static const _packageName = 'com.example.telemetrix';

  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _tileError = false;

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPoints = validRoutePoints(oldWidget.history);
    final newPoints = validRoutePoints(widget.history);
    if (newPoints.length < 2) {
      _mapReady = false;
    } else if (oldPoints.length >= 2 && oldPoints.last != newPoints.last) {
      _scheduleFit(newPoints);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _scheduleFit(List<LatLng> points) {
    if (!_mapReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(28),
          maxZoom: 16,
        ),
      );
    });
  }

  Future<void> _openCopyright() async {
    final opened = await launchUrl(
      _copyrightUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenStreetMap 저작권 페이지를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    // history는 최신순(내림차순)이라 지도에 그릴 땐 오래된 순으로 뒤집는다.
    final points = validRoutePoints(widget.history);
    final coordinateCount = widget.history
        .where((telemetry) => telemetry.lat != null && telemetry.lng != null)
        .length;

    if (points.length < 2) {
      if (coordinateCount >= 2) {
        return const _InvalidRouteNotice();
      }
      return const SizedBox.shrink();
    }

    final latest = points.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.map_outlined, size: 16, color: primary),
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
              border: Border.all(color: colors.border),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: latest,
                    initialZoom: 15,
                    onMapReady: () {
                      _mapReady = true;
                      _scheduleFit(points);
                    },
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
                      userAgentPackageName: _packageName,
                      errorTileCallback: (_, __, ___) {
                        if (mounted && !_tileError) {
                          setState(() => _tileError = true);
                        }
                      },
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4,
                          color: primary,
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
                              color: primary,
                              border:
                                  Border.all(color: colors.background, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.5),
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
                          onTap: _openCopyright,
                        ),
                      ],
                    ),
                  ],
                ),
                if (_tileError)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Material(
                      color: colors.danger.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.map_outlined,
                                size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '지도 타일을 불러오지 못했습니다.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InvalidRouteNotice extends StatelessWidget {
  const _InvalidRouteNotice();

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.1),
        border: Border.all(color: warning),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, color: warning),
          const SizedBox(width: 10),
          const Expanded(
              child: Text('유효하지 않은 GPS 좌표로 경로를 표시할 수 없습니다.')),
        ],
      ),
    );
  }
}
