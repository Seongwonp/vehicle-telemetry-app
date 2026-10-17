import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/vehicle.dart';
import '../../core/providers/vehicle_providers.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../vehicle_detail/vehicle_detail_screen.dart';
import '../login/login_screen.dart';
import 'add_vehicle_screen.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/vehicle_card.dart';
import 'widgets/info_chip.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/theme/design_tokens.dart';

class VehicleListScreen extends ConsumerWidget {
  final bool requireLogin;

  const VehicleListScreen({this.requireLogin = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requireLogin) {
      return const _LoginRequiredHome();
    }

    final vehiclesAsync = ref.watch(vehiclesProvider);
    final canRegister =
        ref.watch(canRegisterVehiclesProvider).valueOrNull == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 차량'),
        centerTitle: false,
        actions: [
          if (canRegister)
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
            onPressed: () {
              ref.invalidate(vehiclesProvider);
              ref.invalidate(canRegisterVehiclesProvider);
            },
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
            ? EmptyView(
                canRegister: canRegister,
                onRetry: () {
                  ref.invalidate(vehiclesProvider);
                  ref.invalidate(canRegisterVehiclesProvider);
                })
            : Column(
                children: [
                  _FleetOverview(vehicles: vehicles),
                  const _SignalCriteriaGuide(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref.refresh(vehiclesProvider.future),
                      child: _VehicleGrid(
                        vehicles: vehicles,
                        canManage: canRegister,
                        onOpen: (vehicle) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VehicleDetailScreen(
                              vehicleId: vehicle.vehicleId,
                              vehicle: vehicle,
                            ),
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

class _LoginRequiredHome extends StatelessWidget {
  const _LoginRequiredHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 차량'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Spacing.md, Spacing.sm, Spacing.md, Spacing.xl),
        children: [
          const _GuestFleetOverview(),
          const _SignalCriteriaGuide(),
          const SizedBox(height: Spacing.sm),
          const _GuestVehicleCard(),
          const SizedBox(height: Spacing.md),
          _LoginPrompt(
              onLogin: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  )),
        ],
      ),
    );
  }
}

class _GuestFleetOverview extends StatelessWidget {
  const _GuestFleetOverview();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '차량 상태',
            style: TextStyle(
              fontSize: context.isMobile
                  ? FontSizes.displayCompact
                  : FontSizes.display,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.xxs),
          Text(
            '로그인하면 등록된 차량의 실시간 데이터를 확인할 수 있습니다.',
            style: TextStyle(
              fontSize: FontSizes.body,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Radii.mdAll,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: primary),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    '로그인 전 미리보기',
                    style: TextStyle(
                      fontSize: FontSizes.subtitle,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '로그인 후 확인',
                  style: TextStyle(
                    fontSize: FontSizes.body,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestVehicleCard extends StatelessWidget {
  const _GuestVehicleCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: Radii.mdAll,
                  ),
                  child: Icon(
                    Icons.directions_car_outlined,
                    color: primary,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    '내 차량',
                    style: TextStyle(
                      fontSize: FontSizes.subtitle,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                StatusPill(
                  label: '로그인 필요',
                  icon: Icons.lock_outline,
                  color: colors.textTertiary,
                  semanticsLabel: '로그인 필요',
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: _GuestMetric(
                    icon: Icons.speed_outlined,
                    label: '현재 속도',
                    value: '—',
                  ),
                ),
                Container(width: 1, height: 34, color: colors.border),
                Expanded(
                  child: _GuestMetric(
                    icon: Icons.warning_amber_outlined,
                    label: '이상 이력',
                    value: '로그인 후 확인',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.xs,
              runSpacing: Spacing.xxs,
              children: const [
                InfoChip(label: '차량 ID —', icon: Icons.tag),
                InfoChip(label: '마지막 수신 —', icon: Icons.schedule_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GuestMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: Spacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: FontSizes.badge, color: colors.textTertiary)),
            const SizedBox(height: Spacing.xxs),
            Text(value,
                style: TextStyle(
                    fontSize: FontSizes.body,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginPrompt({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.mdAll,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.textSecondary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              '차량 데이터를 보려면 로그인해 주세요.',
              style: TextStyle(
                fontSize: FontSizes.body,
                color: colors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: onLogin,
            child: const Text('로그인'),
          ),
        ],
      ),
    );
  }
}

class _FleetOverview extends StatelessWidget {
  final List<Vehicle> vehicles;

  const _FleetOverview({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final recent = vehicles
        .where((v) =>
            fleetSignalState(v.lastSeenAt, now) == FleetSignalState.recent)
        .length;
    final anomalyVehicles =
        vehicles.where((v) => v.highAnomalyCount > 0).length;
    final staleVehicles = vehicles.where((v) {
      final state = fleetSignalState(v.lastSeenAt, now);
      return state == FleetSignalState.delayed ||
          state == FleetSignalState.offline;
    }).length;
    final attention = vehicles.where((v) {
      final state = fleetSignalState(v.lastSeenAt, now);
      return state == FleetSignalState.delayed ||
          state == FleetSignalState.offline ||
          v.highAnomalyCount > 0;
    }).length;
    final label = attention == 0 ? '모든 차량 정상' : '$attention대 확인 필요';
    final tone = attention == 0 ? colors.success : colors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.sm, Spacing.md, Spacing.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ContentWidths.grid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '차량 상태',
              style: TextStyle(
                fontSize: context.isMobile
                    ? FontSizes.displayCompact
                    : FontSizes.display,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.xxs),
            Text(
              '등록된 차량의 현재 신호와 이상 상태를 한눈에 확인하세요.',
              style: TextStyle(
                fontSize: FontSizes.body,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: Radii.mdAll,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.10),
                      borderRadius: Radii.smAll,
                    ),
                    child: Icon(
                      attention == 0
                          ? Icons.verified_outlined
                          : Icons.warning_amber_rounded,
                      color: tone,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: FontSizes.subtitle,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: Spacing.xxs),
                        Text(
                          '$recent/${vehicles.length}대 최근 수신 · 마지막 수신 시각 기준',
                          style: TextStyle(
                            fontSize: FontSizes.caption,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (attention > 0) ...[
                          const SizedBox(height: Spacing.xs),
                          Wrap(
                            spacing: Spacing.xs,
                            runSpacing: Spacing.xxs,
                            children: [
                              if (anomalyVehicles > 0)
                                _FleetStat(
                                  icon: Icons.warning_amber_rounded,
                                  label: '이상 $anomalyVehicles대',
                                  color: colors.danger,
                                ),
                              if (staleVehicles > 0)
                                _FleetStat(
                                  icon: Icons.schedule_outlined,
                                  label: '수신 확인 $staleVehicles대',
                                  color: colors.warning,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.textTertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FleetStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FleetStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacing.xxs),
          Text(
            label,
            style: TextStyle(
              fontSize: FontSizes.badge,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드의 신호 알약이 무엇을 기준으로 정해지는지 한 줄로 알려준다.
///
/// 문구는 [FleetSignalState]의 알약 문구와 같은 낱말을 써야 한다 — 상세 화면의
/// "데이터 지연"(10초 기준)과 섞이지 않도록 양쪽 모두 "수신"을 붙인다.
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
              '마지막 수신 시각 기준  ·  '
              '${recentSignalThreshold.inMinutes}분 이내 최근 수신  ·  '
              '${recentSignalThreshold.inMinutes}~${delayedSignalThreshold.inMinutes}분 오래전 수신  ·  '
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
  final void Function(Vehicle vehicle) onOpen;
  final VoidCallback onDeleted;
  final bool canManage;

  const _VehicleGrid(
      {required this.vehicles,
      required this.onOpen,
      required this.onDeleted,
      required this.canManage});

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
          onTap: () => onOpen(vehicles[index]),
          onDeleted: onDeleted,
          canManage: canManage,
        ),
      );
    }

    final columns = context.isDesktop ? 3 : 2;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ContentWidths.grid),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(
              Spacing.lg, Spacing.md, Spacing.lg, Spacing.xl),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: context.isDesktop ? 236 : 250,
          ),
          itemCount: vehicles.length,
          itemBuilder: (context, index) => VehicleCard(
            vehicle: vehicles[index],
            onTap: () => onOpen(vehicles[index]),
            onDeleted: onDeleted,
            canManage: canManage,
          ),
        ),
      ),
    );
  }
}
