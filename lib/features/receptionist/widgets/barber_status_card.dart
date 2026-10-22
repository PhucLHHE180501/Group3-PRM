import 'package:flutter/material.dart';
import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/services/mock_data_service.dart';

class BarberStatusCard extends StatelessWidget {
  final BarberModel barber;
  final VoidCallback onQuickAssign;
  final VoidCallback onViewSchedule;

  const BarberStatusCard({
    super.key,
    required this.barber,
    required this.onQuickAssign,
    required this.onViewSchedule,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.greenAccent;
      case 'busy':
        return Colors.orangeAccent;
      case 'break':
        return Colors.amber;
      case 'off':
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Sẵn sàng đón khách';
      case 'busy':
        return 'Đang phục vụ';
      case 'break':
        return 'Nghỉ giữa ca';
      case 'off':
      default:
        return 'Nghỉ làm';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle_outline;
      case 'busy':
        return Icons.content_cut;
      case 'break':
        return Icons.coffee;
      case 'off':
      default:
        return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = MockDataService();
    final dynamicStatus = dataService.getBarberDynamicStatus(barber.userId);
    final currentJob = dataService.getBarberCurrentJob(barber.userId);
    final statusColor = _getStatusColor(dynamicStatus);
    final todayBookings = dataService.getBarberBookings(barber.userId).where((b) {
      final now = DateTime.now();
      return b.bookingDate.year == now.year &&
          b.bookingDate.month == now.month &&
          b.bookingDate.day == now.day &&
          b.status != 'cancelled';
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Barber info & Live Status Badge
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: barber.avatarUrl != null ? NetworkImage(barber.avatarUrl!) : null,
                    child: barber.avatarUrl == null ? const Icon(Icons.person, color: Colors.white70) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFD4AF37), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${barber.avgRating} (${barber.reviewCount} đánh giá)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${barber.yearsExperience} năm KN',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      barber.specialty,
                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(dynamicStatus), color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(dynamicStatus),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Current Serving Details (if busy/in_progress)
          if (currentJob != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.orangeAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đang phục vụ: ${currentJob.customerName ?? "Khách #${currentJob.id}"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Dịch vụ: ${currentJob.services.map((s) => s.name).join(", ")}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Khung giờ: ${currentJob.startTime} - ${currentJob.endTime}',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Sub info: Schedule summary for today
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch hôm nay: ${todayBookings.length} khách',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.calendar_month, size: 14),
                    label: const Text('Xem lịch', style: TextStyle(fontSize: 12)),
                    onPressed: onViewSchedule,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dynamicStatus == 'available'
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF333333),
                      foregroundColor: dynamicStatus == 'available' ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Xếp khách ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: onQuickAssign,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
