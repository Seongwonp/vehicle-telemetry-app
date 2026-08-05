import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../anomalies/anomaly_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../diagnosis/diagnosis_screen.dart';
import '../trips/trip_history_tab.dart';

// 예전엔 대시보드 앱바에 경고/뇌 아이콘 두 개만 달아두고 각각 이상 이력·AI
// 진단으로 push했는데, 아이콘만으로는 뭘 누르는 건지 알기 어렵다는 피드백을
// 받았다. TabBar(라벨 있는 탭) + TabBarView로 바꿔서 스와이프도 되고 각 탭이
// 뭘 보여주는지 이름으로 바로 보이게 했다.
class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;
  const VehicleDetailScreen({required this.vehicleId, super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vehicleId,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.speed_outlined), text: '대시보드'),
              Tab(icon: Icon(Icons.warning_amber_outlined), text: '이상 이력'),
              Tab(icon: Icon(Icons.psychology_outlined), text: 'AI 진단'),
              Tab(icon: Icon(Icons.route_outlined), text: '주행 기록'),
            ],
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            labelStyle: TextStyle(fontSize: 11.5),
            unselectedLabelStyle: TextStyle(fontSize: 11.5),
          ),
        ),
        body: TabBarView(
          children: [
            DashboardTab(vehicleId: vehicleId),
            AnomalyListTab(vehicleId: vehicleId),
            DiagnosisTab(vehicleId: vehicleId),
            TripHistoryTab(vehicleId: vehicleId),
          ],
        ),
      ),
    );
  }
}
