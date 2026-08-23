import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/api/api_client.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/theme/app_theme.dart';
import 'info_chip.dart';

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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 28,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!vehicle.active) ...[
                      const SizedBox(height: 3),
                      Text('비활성 차량',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textTertiary,
                          )),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        InfoChip(label: vehicle.vehicleId, icon: Icons.tag),
                        InfoChip(
                            label: vehicle.owner, icon: Icons.person_outline),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '등록: ${_formatDate(vehicle.registeredAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FleetSummaryRow(vehicle: vehicle),
                  ],
                ),
              ),

              // 마지막 수신 상태 + 관리 메뉴
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SignalStatus(
                    state: signalState,
                    lastSeenAt: vehicle.lastSeenAt,
                    color: signalColor,
                  ),
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            size: 20, color: cs.onSurface.withOpacity(0.6)),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'delete') _confirmDelete(context);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: colors.danger),
                                const SizedBox(width: 8),
                                Text('삭제',
                                    style: TextStyle(color: colors.danger)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}

class _FleetSummaryRow extends StatelessWidget {
  final Vehicle vehicle;
  const _FleetSummaryRow({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    final hasHighAnomaly = vehicle.highAnomalyCount > 0;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (vehicle.latestSpeed != null)
          _Badge(
            icon: Icons.speed_outlined,
            label: '${vehicle.latestSpeed!.toStringAsFixed(0)} km/h',
            color: primary,
          ),
        if (hasHighAnomaly)
          _Badge(
            icon: Icons.warning_amber_rounded,
            label: 'HIGH ${vehicle.highAnomalyCount}',
            color: colors.danger,
          ),
      ],
    );
  }
}

class _SignalStatus extends StatelessWidget {
  final FleetSignalState state;
  final DateTime? lastSeenAt;
  final Color color;

  const _SignalStatus({
    required this.state,
    required this.lastSeenAt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final detail = lastSeenAt == null
        ? '수신 이력 없음'
        : timeago.format(lastSeenAt!, locale: 'ko');
    return Semantics(
      label: '데이터 상태 ${state.label}, 마지막 신호 $detail',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(state.icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(state.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ],
            ),
            const SizedBox(height: 2),
            Text(detail,
                style: TextStyle(
                  fontSize: 9.5,
                  color: context.appColors.textSecondary,
                )),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
