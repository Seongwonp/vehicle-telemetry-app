import 'package:flutter/material.dart';
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
            child: const Text('삭제', style: TextStyle(color: AppTheme.danger)),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 차량 아이콘 + 활성 상태 표시
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      size: 32,
                      color: cs.primary,
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: vehicle.active
                          ? AppTheme.success
                          : AppTheme.textTertiary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // 차량 정보
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
                  ],
                ),
              ),

              // 상태 배지 + 더보기 메뉴
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: vehicle.active
                          ? AppTheme.success.withOpacity(0.15)
                          : AppTheme.textTertiary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vehicle.active ? '활성' : '비활성',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: vehicle.active
                            ? AppTheme.success
                            : AppTheme.textTertiary,
                      ),
                    ),
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
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: AppTheme.danger),
                                SizedBox(width: 8),
                                Text('삭제',
                                    style: TextStyle(color: AppTheme.danger)),
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
