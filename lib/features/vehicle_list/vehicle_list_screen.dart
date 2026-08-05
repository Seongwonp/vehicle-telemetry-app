import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/vehicle.dart';
import '../../core/providers/vehicle_providers.dart';
import '../../core/responsive/breakpoints.dart';
import '../settings/settings_screen.dart';
import '../vehicle_detail/vehicle_detail_screen.dart';
import 'add_vehicle_screen.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/vehicle_card.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 차량'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '차량 추가',
            onPressed: () async {
              final registered = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
              );
              if (registered == true) ref.invalidate(vehiclesProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: () => ref.invalidate(vehiclesProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      // AsyncValue.when이 loading/error/data 3상태를 그대로 매핑해준다 — 예전엔
      // _loading/_error/_vehicles 3개 필드를 직접 관리하고 실수로 상태 하나를
      // 빠뜨릴 여지가 있었다(코덱스 리뷰에서 대시보드/이상이력 화면이 실제로 그
      // 실수를 했었다).
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => VehicleListErrorView(
          message: '차량 목록을 불러올 수 없습니다.',
          onRetry: () => ref.invalidate(vehiclesProvider),
        ),
        data: (vehicles) => vehicles.isEmpty
            ? EmptyView(onRetry: () => ref.invalidate(vehiclesProvider))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(vehiclesProvider.future),
                child: _VehicleGrid(
                  vehicles: vehicles,
                  onOpen: (vehicleId) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleDetailScreen(vehicleId: vehicleId),
                    ),
                  ),
                  onDeleted: () => ref.invalidate(vehiclesProvider),
                ),
              ),
      ),
    );
  }
}

// 모바일에서는 세로 리스트, 데스크톱 폭에서는 2~3열 그리드로 전환한다.
// 차량이 여러 대인 포트폴리오 데모에서 넓은 화면 공간을 그냥 낭비하지 않도록.
class _VehicleGrid extends StatelessWidget {
  final List<Vehicle> vehicles;
  final void Function(String vehicleId) onOpen;
  final VoidCallback onDeleted;

  const _VehicleGrid(
      {required this.vehicles, required this.onOpen, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: vehicles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => VehicleCard(
          vehicle: vehicles[index],
          onTap: () => onOpen(vehicles[index].vehicleId),
          onDeleted: onDeleted,
        ),
      );
    }

    final columns = context.isDesktop ? 3 : 2;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            // 카드 안의 fleet 배지가 줄바꿈되어도 세로 공간이 보장되도록
            // 너비 비율 대신 명시적인 높이를 사용한다.
            mainAxisExtent: context.isDesktop ? 190 : 220,
          ),
          itemCount: vehicles.length,
          itemBuilder: (context, index) => VehicleCard(
            vehicle: vehicles[index],
            onTap: () => onOpen(vehicles[index].vehicleId),
            onDeleted: onDeleted,
          ),
        ),
      ),
    );
  }
}
