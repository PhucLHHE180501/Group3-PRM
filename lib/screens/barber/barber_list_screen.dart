import 'package:flutter/material.dart';

import '../../services/mock_data_service.dart';
import 'barber_detail_screen.dart';

class BarberListScreen extends StatefulWidget {
  const BarberListScreen({super.key});

  @override
  State<BarberListScreen> createState() => _BarberListScreenState();
}

class _BarberListScreenState extends State<BarberListScreen> {
  final MockDataService _dataService = MockDataService();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final barbers = _dataService.barbers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Barber'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: barbers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final barber = barbers[index];

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarberDetailScreen(barber: barber),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarberDetailScreen(barber: barber),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFD4AF37),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundImage: barber.avatarUrl != null
                              ? NetworkImage(barber.avatarUrl!)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
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
                          const SizedBox(height: 4),
                          Text(
                            barber.specialty,
                            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${barber.avgRating} (${barber.reviewCount} đánh giá)',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '• ${barber.yearsExperience} năm kinh nghiệm',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
