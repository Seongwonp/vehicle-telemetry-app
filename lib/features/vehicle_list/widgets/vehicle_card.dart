import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/api/api_client.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/status_pill.dart';
import 'info_chip.dart';

/// 차량 목록의 카드. 좁은 화면에서 잘리지 않게 가로로 경쟁하는 열 없이 세 줄로 쌓는다
/// (docs/design-system.md, test/responsive_overflow_test.dart).
///
/// ```
/// [아이콘] 차량 이름                  ● 최근 수신  [⋮]
///          #KR-GA-1234  홍길동
///          118 km/h · HIGH 12 · 5분 전 수신
/// ```
///
/// 마지막 줄은 [Wrap]이라 폭이 모자라면 줄바꿈된다.
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onDeleted;
  final ApiClient? apiClient;

  /// 삭제(비활성화) 메뉴를 보일지. 백엔드는 관리자만 허용하므로 권한 조회 결과를 받는다.
  /// 기본값 true는 기존 스냅샷·레이아웃 테스트를 유지하기 위해서다.
  final bool canManage;

  const VehicleCard({
    required this.vehicle,
    required this.onTap,
    required this.onDeleted,
    this.apiClient,
    this.canManage = true,
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
    final hasAnomaly = vehicle.highAnomalyCount > 0;
    final hasStaleSignal = signalState == FleetSignalState.delayed ||
        signalState == FleetSignalState.offline;
    final hasAttention = hasAnomaly || hasStaleSignal;
    final healthLabel = hasAnomaly
        ? '이상 감지'
        : hasStaleSignal
            ? '수신 확인'
            : '정상';
    final healthColor = hasAnomaly
        ? colors.danger
        : hasStaleSignal
            ? colors.warning
            : colors.success;

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
                  StatusPill(
                    label: signalState.label,
                    color: signalColor,
                    icon: signalState.icon,
                    density: StatusPillDensity.regular,
                    semanticsLabel: '데이터 상태 ${signalState.label}',
                  ),
                  if (canManage)
                    _DeleteMenuButton(onDelete: () => _confirmDelete(context)),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryVehicleMetric(
                      icon: Icons.speed_outlined,
                      label: '현재 속도',
                      value: vehicle.latestSpeed == null
                          ? '—'
                          : '${vehicle.latestSpeed!.toStringAsFixed(0)} km/h',
                      muted: vehicle.latestSpeed == null,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: colors.border,
                  ),
                  Expanded(
                    child: _PrimaryVehicleMetric(
                      icon: hasAttention
                          ? Icons.warning_amber_rounded
                          : Icons.health_and_safety_outlined,
                      label: '상태',
                      value: healthLabel,
                      color: healthColor,
                    ),
                  ),
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

class _PrimaryVehicleMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;
  final Color? color;

  const _PrimaryVehicleMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = color ?? colors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 18, color: tone),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: FontSizes.badge,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: Spacing.xxs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: FontSizes.body,
                  fontWeight: FontWeight.w700,
                  color: muted ? colors.textTertiary : tone,
                ),
              ),
            ],
          ),
        ),
      ],
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
/// [Wrap]이라 폭이 모자라면 다음 줄로 넘어간다.
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
          StatusPill(
            icon: Icons.speed_outlined,
            label: '${vehicle.latestSpeed!.toStringAsFixed(0)} km/h',
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        if (vehicle.highAnomalyCount > 0)
          StatusPill(
            icon: Icons.warning_amber_rounded,
            label: 'HIGH ${vehicle.highAnomalyCount}',
            color: colors.danger,
            fontWeight: FontWeight.w600,
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

/// 목록 카드의 신호 상태 문구.
///
/// 상세 화면의 "데이터 지연"(10초)과 기준이 다르다 — 마지막 수신이 5분/15분을 넘었는지를 본다.
/// 같은 판정으로 읽히지 않게 "지연" 대신 수신 시각에 대한 말만 쓴다.
extension on FleetSignalState {
  String get label => switch (this) {
        FleetSignalState.recent => '최근 수신',
        FleetSignalState.delayed => '오래전 수신',
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
