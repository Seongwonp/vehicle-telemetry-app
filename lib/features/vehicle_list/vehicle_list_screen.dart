import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/vehicle.dart';
import '../../core/providers/vehicle_providers.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../vehicle_detail/vehicle_detail_screen.dart';
import 'add_vehicle_screen.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/vehicle_card.dart';
import '../../core/theme/design_tokens.dart';

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
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => VehicleListErrorView(
          message: '차량 목록을 불러올 수 없습니다.',
          onRetry: () => ref.invalidate(vehiclesProvider),
        ),
        data: (vehicles) => vehicles.isEmpty
            ? EmptyView(onRetry: () => ref.invalidate(vehiclesProvider))
            : Column(
                children: [
                  const _SignalCriteriaGuide(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref.refresh(vehiclesProvider.future),
                      child: _VehicleGrid(
                        vehicles: vehicles,
                        onOpen: (vehicleId) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VehicleDetailScreen(vehicleId: vehicleId),
                          ),
                        ),
                        onDeleted: () => ref.invalidate(vehiclesProvider),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SignalCriteriaGuide extends StatelessWidget {
  const _SignalCriteriaGuide();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Text(
              '마지막 신호 기준  ·  '
              '${recentSignalThreshold.inMinutes}분 이내 정상  ·  '
              '${recentSignalThreshold.inMinutes}~${delayedSignalThreshold.inMinutes}분 지연  ·  '
              '${delayedSignalThreshold.inMinutes}분 초과 오프라인',
              style: TextStyle(
                  fontSize: FontSizes.caption, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.fromLTRB(
            Spacing.md, Spacing.sm, Spacing.md, Spacing.lg),
        itemCount: vehicles.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
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
          padding: const EdgeInsets.fromLTRB(
              Spacing.lg, Spacing.md, Spacing.lg, Spacing.xl),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
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
