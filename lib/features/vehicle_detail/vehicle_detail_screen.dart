import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../anomalies/anomaly_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../diagnosis/diagnosis_screen.dart';
import '../trips/trip_history_tab.dart';
import '../../core/models/vehicle.dart';
import 'widgets/vehicle_title.dart';

// 예전엔 대시보드 앱바에 경고/뇌 아이콘 두 개만 달아두고 각각 이상 이력·AI
// 진단으로 push했는데, 아이콘만으로는 뭘 누르는 건지 알기 어렵다는 피드백을
// 받았다. TabBar(라벨 있는 탭) + TabBarView로 바꿔서 스와이프도 되고 각 탭이
// 뭘 보여주는지 이름으로 바로 보이게 했다.
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScaler = MediaQuery.textScalerOf(context);
    final compactTabs =
        screenWidth < 400 || textScaler.scale(FontSizes.badge) > 14;
    final name = vehicle?.name.trim().isNotEmpty == true ? vehicle!.name : null;
    final titleLayout = name == null
        ? null
        : VehicleTitleLayout.measure(
            name: name,
            screenWidth: screenWidth,
            textScaler: textScaler,
            baseStyle: Theme.of(context).appBarTheme.titleTextStyle,
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
              : VehicleTitle(name: name, vehicleId: vehicleId),
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
