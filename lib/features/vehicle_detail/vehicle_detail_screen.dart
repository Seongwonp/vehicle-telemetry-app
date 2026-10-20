import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../anomalies/anomaly_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../diagnosis/diagnosis_screen.dart';
import '../trips/trip_history_tab.dart';
import '../../core/models/vehicle.dart';
import 'widgets/vehicle_title.dart';

// 차량 상세 — 라벨 있는 탭으로 현재 상태·이상 이력·주행 기록·보조 진단을 나눈다.
class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  /// 목록에서 넘겨받은 차량. 없으면 제목에 차량 ID만 쓴다(목록 외 진입 경로 대비).
  final Vehicle? vehicle;

  /// 테스트가 네트워크 없이 '현재 상태' 탭을 넣을 때만 쓴다.
  @visibleForTesting
  final Widget? dashboardOverride;

  const VehicleDetailScreen({
    required this.vehicleId,
    this.vehicle,
    this.dashboardOverride,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final textScaler = MediaQuery.textScalerOf(context);
    final compactTabs =
        screenWidth < 400 || textScaler.scale(FontSizes.badge) > 14;
    // 가로 모드 폰에서는 본문 공간을 위해 이름을 한 줄로 줄인다('전체 이름' 버튼 규칙은 유지).
    final titleMaxLines = screenSize.height < Heights.compactLandscape ? 1 : 2;
    final name = vehicle?.name.trim().isNotEmpty == true ? vehicle!.name : null;
    final titleLayout = name == null
        ? null
        : VehicleTitleLayout.measure(
            name: name,
            screenWidth: screenWidth,
            textScaler: textScaler,
            baseStyle: Theme.of(context).appBarTheme.titleTextStyle,
            maxLines: titleMaxLines,
          );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: titleLayout?.toolbarHeight,
          title: name == null
              ? Text(vehicleId,
                  style: const TextStyle(
                      fontSize: FontSizes.subtitle,
                      fontWeight: FontWeight.bold))
              : VehicleTitle(
                  name: name,
                  vehicleId: vehicleId,
                  maxLines: titleMaxLines,
                ),
          actions: [
            if (titleLayout?.clipped == true)
              VehicleFullNameButton(name: name!, vehicleId: vehicleId),
          ],
          bottom: TabBar(
            isScrollable: compactTabs,
            tabAlignment: compactTabs ? TabAlignment.start : TabAlignment.fill,
            tabs: const [
              Tab(icon: Icon(Icons.speed_outlined), text: '현재 상태'),
              Tab(icon: Icon(Icons.warning_amber_outlined), text: '이상 이력'),
              Tab(icon: Icon(Icons.route_outlined), text: '주행 기록'),
              Tab(icon: Icon(Icons.psychology_outlined), text: '보조 진단'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: colors.textSecondary,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(fontSize: FontSizes.badge),
            unselectedLabelStyle: const TextStyle(fontSize: FontSizes.badge),
          ),
        ),
        body: TabBarView(
          children: [
            dashboardOverride ?? DashboardTab(vehicleId: vehicleId),
            AnomalyListTab(vehicleId: vehicleId),
            TripHistoryTab(vehicleId: vehicleId),
            DiagnosisTab(vehicleId: vehicleId),
          ],
        ),
      ),
    );
  }
}
