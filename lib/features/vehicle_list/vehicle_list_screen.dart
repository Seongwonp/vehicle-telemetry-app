import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/vehicle.dart';
import '../../core/responsive/breakpoints.dart';
import '../dashboard/dashboard_screen.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/vehicle_card.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  List<Vehicle> _vehicles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient().getVehicles();
      if (mounted) {
        setState(() {
          _vehicles = data
              .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '차량 목록을 불러올 수 없습니다.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 차량'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _loadVehicles,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? VehicleListErrorView(message: _error!, onRetry: _loadVehicles)
              : _vehicles.isEmpty
                  ? EmptyView(onRetry: _loadVehicles)
                  : RefreshIndicator(
                      onRefresh: _loadVehicles,
                      child: _VehicleGrid(
                        vehicles: _vehicles,
                        onOpen: (vehicleId) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DashboardScreen(vehicleId: vehicleId),
                          ),
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

  const _VehicleGrid({required this.vehicles, required this.onOpen});

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
            childAspectRatio: 2.6,
          ),
          itemCount: vehicles.length,
          itemBuilder: (context, index) => VehicleCard(
            vehicle: vehicles[index],
            onTap: () => onOpen(vehicles[index].vehicleId),
          ),
        ),
      ),
    );
  }
}
