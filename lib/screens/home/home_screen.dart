import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/mock_data_service.dart';
import '../barber/barber_detail_screen.dart';
import '../barber/barber_list_screen.dart';
import '../booking/booking_screen.dart';
import '../profile/profile_screen.dart';
import '../support/cskh_screen.dart';

class BarberHomePage extends StatefulWidget {
  const BarberHomePage({super.key});

  @override
  State<BarberHomePage> createState() => _BarberHomePageState();
}

class _BarberHomePageState extends State<BarberHomePage> {
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

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    final user = _dataService.currentUser;
    final services = _dataService.services;
    final barbers = _dataService.barbers;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header (Click avatar -> Profile) ---
              _buildHeader(user),
              const SizedBox(height: 20),

              // --- Promo Banner ---
              _buildPromoBanner(),
              const SizedBox(height: 24),

              // --- Quick CSKH & Contact Banner ---
              _buildCskhBanner(),
              const SizedBox(height: 24),

              // --- Popular Services ---
              _buildSectionTitle('Dịch Vụ Nổi Bật', onViewAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookingScreen()),
                );
              }),
              const SizedBox(height: 12),
              _buildServicesGrid(services),
              const SizedBox(height: 24),

              // --- Top Barbers ---
              _buildSectionTitle('Barber Hàng Đầu', onViewAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BarberListScreen()),
                );
              }),
              const SizedBox(height: 12),
              _buildBarbersList(barbers),
            ],
          ),
        ),
      ),
    );
  }

  // Header Widget (Click user image -> open Profile)
  Widget _buildHeader(UserModel? user) {
    final userName = user?.fullName ?? 'Khách Hàng';
    final avatarUrl = user?.avatarUrl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFFD4AF37),
                    child: CircleAvatar(
                      radius: 23,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 10, color: Colors.black),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xin chào,',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không có thông báo mới.')),
            );
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // Promo Banner Widget
  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'GIẢM 20%',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Đặt Lịch Cắt Tóc Hôm Nay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ưu đãi đặc biệt cho lượt đặt lịch đầu tiên.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BookingScreen()),
                    );
                  },
                  child: const Text('Đặt Lịch Ngay'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.content_cut,
            size: 70,
            color: Color(0xFFD4AF37),
          ),
        ],
      ),
    );
  }

  // CSKH Quick Banner
  Widget _buildCskhBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.headset_mic_outlined, color: Color(0xFFD4AF37), size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cần Hỗ Trợ Từ Salon?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Liên hệ CSKH 24/7 để được giải đáp',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CskhScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Liên Hệ', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title, {required VoidCallback onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text(
            'Xem tất cả',
            style: TextStyle(color: Color(0xFFD4AF37)),
          ),
        ),
      ],
    );
  }

  // Services Grid
  Widget _buildServicesGrid(services) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: services.length > 4 ? 4 : services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.content_cut, color: Color(0xFFD4AF37), size: 24),
                  Text(
                    _formatPrice(service.price),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service.durationMin} phút',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Horizontal Barbers List
  Widget _buildBarbersList(barbers) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: barbers.length,
        itemBuilder: (context, index) {
          final barber = barbers[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BarberDetailScreen(barber: barber),
                ),
              );
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: barber.avatarUrl != null
                        ? NetworkImage(barber.avatarUrl!)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    barber.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    barber.specialty,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFD4AF37), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${barber.avgRating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
