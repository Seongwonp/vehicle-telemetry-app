import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/api/api_client.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import 'info_chip.dart';

/// 차량 목록의 카드.
///
/// 예전 구조는 바깥 [Row]에 `[아이콘][Expanded 정보][오른쪽 열]`을 나란히 뒀는데,
/// 오른쪽 열(상태 배지 + 메뉴 + chevron)에 폭 제약이 없어서 좁은 화면에서 밀렸다.
/// 자동 검사로 재보니 **320px에서는 기본 글자 크기로도 99px가 넘쳐** 잘리고 있었다
/// (test/responsive_overflow_test.dart).
///
/// 그래서 가로로 경쟁하는 열을 없애고 세 줄로 쌓는다.
///
/// ```
/// [아이콘] 차량 이름                    ● 정상  [⋮]
///          #KR-GA-1234  홍길동
///          118 km/h · HIGH 12 · 5분 전 수신
/// ```
///
/// 마지막 줄은 [Wrap]이라 폭이 모자라면 줄바꿈된다 — 잘리지 않는다.
/// chevron은 없앴다. 카드 전체가 눌리는데 화살표까지 두면 어포던스가 셋이 되고,
/// 그 화살표가 좁은 화면에서 폭을 가장 많이 잡아먹고 있었다.
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onDeleted;
  final ApiClient? apiClient;

  const VehicleCard({
    required this.vehicle,
    required this.onTap,
    required this.onDeleted,
    this.apiClient,
    super.key,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final danger = context.appColors.danger;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('차량 삭제'),
        content: Text('${vehicle.name}(${vehicle.vehicleId})을(를) 삭제하시겠습니까?\n'
            '기존 텔레메트리/이상 이력은 보존되지만 목록에서는 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('삭제', style: TextStyle(color: danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await (apiClient ?? ApiClient()).deactivateVehicle(vehicle.vehicleId);
      onDeleted();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차량 삭제에 실패했습니다. 잠시 후 다시 시도하세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final signalState = fleetSignalState(vehicle.lastSeenAt, DateTime.now());
    final signalColor = signalState.color(colors);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VehicleAvatar(color: cs.primary),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: const TextStyle(
                            fontSize: FontSizes.subtitle,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!vehicle.active) ...[
                          const SizedBox(height: Spacing.xxs),
                          Text(
                            '비활성 차량',
                            style: TextStyle(
                              fontSize: FontSizes.badge,
                              fontWeight: FontWeight.w600,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.xs),
                  _SignalPill(state: signalState, color: signalColor),
                  _DeleteMenuButton(onDelete: () => _confirmDelete(context)),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.xs,
                runSpacing: Spacing.xxs,
                children: [
                  InfoChip(label: vehicle.vehicleId, icon: Icons.tag),
                  InfoChip(label: vehicle.owner, icon: Icons.person_outline),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              _MetaLine(
                vehicle: vehicle,
                colors: colors,
                primary: cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleAvatar extends StatelessWidget {
  final Color color;
  const _VehicleAvatar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: Radii.mdAll,
      ),
      child: Icon(Icons.directions_car_outlined, size: 24, color: color),
    );
  }
}

/// 상태 배지. 한 줄짜리 알약으로 줄였다.
///
/// 예전에는 상태와 마지막 수신 시각을 세로로 쌓은 두 줄 배지였는데, 그 폭이
/// 좁은 화면에서 이름 영역을 밀어냈다. 시각은 아래 [_MetaLine]으로 옮겼다 —
/// 줄바꿈이 가능한 자리다.
class _SignalPill extends StatelessWidget {
  final FleetSignalState state;
  final Color color;
  const _SignalPill({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '데이터 상태 ${state.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs,
          vertical: Spacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: Radii.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(state.icon, size: 12, color: color),
            const SizedBox(width: Spacing.xxs),
            Text(
              state.label,
              style: TextStyle(
                fontSize: FontSizes.badge,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 삭제 메뉴. 아이콘은 작아 보이지만 눌리는 영역은 [TouchTarget.min]을 지킨다.
class _DeleteMenuButton extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteMenuButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: TouchTarget.min,
      height: TouchTarget.min,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 20, color: colors.textTertiary),
        tooltip: '차량 관리',
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: colors.danger),
                const SizedBox(width: Spacing.xs),
                Text('삭제', style: TextStyle(color: colors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 속도·이상 건수·마지막 수신 시각을 한 줄에 흘린다.
///
/// [Wrap]이라 폭이 모자라면 다음 줄로 넘어간다. 예전에는 이 정보들이 서로 다른
/// 자리에 흩어져 있어서(배지는 왼쪽 열, 시각은 오른쪽 배지 안) 눈이 두 번 움직여야 했다.
class _MetaLine extends StatelessWidget {
  final Vehicle vehicle;
  final AppSemanticColors colors;
  final Color primary;

  const _MetaLine({
    required this.vehicle,
    required this.colors,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final lastSeen = vehicle.lastSeenAt == null
        ? '수신 이력 없음'
        : '${timeago.format(vehicle.lastSeenAt!, locale: 'ko')} 수신';

    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (vehicle.latestSpeed != null)
          _Badge(
            icon: Icons.speed_outlined,
            label: '${vehicle.latestSpeed!.toStringAsFixed(0)} km/h',
            color: primary,
          ),
        if (vehicle.highAnomalyCount > 0)
          _Badge(
            icon: Icons.warning_amber_rounded,
            label: 'HIGH ${vehicle.highAnomalyCount}',
            color: colors.danger,
          ),
        Text(
          lastSeen,
          style: TextStyle(
            fontSize: FontSizes.badge,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

enum FleetSignalState { recent, delayed, offline, noData }

const recentSignalThreshold = Duration(minutes: 5);
const delayedSignalThreshold = Duration(minutes: 15);

FleetSignalState fleetSignalState(DateTime? lastSeenAt, DateTime now) {
  if (lastSeenAt == null) return FleetSignalState.noData;

  final age = now.toUtc().difference(lastSeenAt.toUtc());
  if (age <= recentSignalThreshold) return FleetSignalState.recent;
  if (age <= delayedSignalThreshold) return FleetSignalState.delayed;
  return FleetSignalState.offline;
}

extension on FleetSignalState {
  String get label => switch (this) {
        FleetSignalState.recent => '정상',
        FleetSignalState.delayed => '지연',
        FleetSignalState.offline => '오프라인',
        FleetSignalState.noData => '데이터 없음',
      };

  IconData get icon => switch (this) {
        FleetSignalState.recent => Icons.wifi_tethering,
        FleetSignalState.delayed => Icons.wifi_tethering_error,
        FleetSignalState.offline || FleetSignalState.noData => Icons.wifi_off,
      };

  Color color(AppSemanticColors colors) => switch (this) {
        FleetSignalState.recent => colors.success,
        FleetSignalState.delayed => colors.warning,
        FleetSignalState.offline => colors.danger,
        FleetSignalState.noData => colors.textTertiary,
      };
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: Spacing.xxs),
          Text(
            label,
            style: TextStyle(
              fontSize: FontSizes.badge,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
