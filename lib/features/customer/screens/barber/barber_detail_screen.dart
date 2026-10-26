import 'package:flutter/material.dart';

import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';
import 'package:barber_booking_app/shared/widgets/add_review_dialog.dart';
import '../booking/booking_screen.dart';
import '../profile/edit_profile_screen.dart';

class BarberDetailScreen extends StatefulWidget {
  final BarberModel barber;

  const BarberDetailScreen({
    super.key,
    required this.barber,
  });

  @override
  State<BarberDetailScreen> createState() => _BarberDetailScreenState();
}

class _BarberDetailScreenState extends State<BarberDetailScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _dataService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  // Get current updated barber object from data service
  BarberModel get currentBarber {
    return _dataService.barbers.firstWhere(
      (b) => b.userId == widget.barber.userId,
      orElse: () => widget.barber,
    );
  }

  void _navigateToBooking(BuildContext context, BarberModel barber) {
    final user = _dataService.currentUser;
    final hasInfo = user != null && user.hasRequiredProfileInfo;

    if (!hasInfo) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD4AF37), size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Yêu Cầu Thông Tin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: const Text(
            'Để salon tiện liên hệ xác nhận lịch hẹn, bạn vui lòng bổ sung Họ tên & Số điện thoại trong hồ sơ trước khi đặt lịch nhé!',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              child: const Text('Cập Nhật Ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(initialBarber: barber),
      ),
    );
  }

  void _openAddReviewDialog() {
    final barber = currentBarber;
    final canReview = _dataService.canUserReviewBarber(barber.userId);

    if (!canReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã gửi đánh giá cho Barber này rồi! (Mỗi người dùng chỉ được đánh giá 1 lần)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        barberName: barber.fullName,
        onSubmit: (rating, comment) {
          final success = _dataService.addReview(
            staffId: barber.userId,
            rating: rating,
            comment: comment,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cảm ơn bạn đã gửi đánh giá!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barber = currentBarber;
    final reviews = _dataService.getReviewsForBarber(barber.userId);
    final hasReviewed = _dataService.hasUserReviewedBarber(barber.userId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar with Avatar Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                barber.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  barber.avatarUrl != null && barber.avatarUrl!.isNotEmpty
                      ? Image.network(
                          barber.avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: const Color(0xFF2C2C2C)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Info Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD4AF37)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${barber.avgRating} (${barber.reviewCount} đánh giá)',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: Text(
                          '${barber.yearsExperience} năm kinh nghiệm',
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Specialty
                  Row(
                    children: [
                      const Icon(Icons.content_cut, color: Color(0xFFD4AF37), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sở trường: ${barber.specialty}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bio
                  Text(
                    barber.bio,
                    style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Tabs Header: Portfolio Images / Reviews
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFD4AF37),
                    labelColor: const Color(0xFFD4AF37),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Kiểu Tóc Đã Làm (${barber.portfolioImages.length})'),
                      Tab(text: 'Đánh Giá (${reviews.length})'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Views Content inside SingleChildScrollView container
                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Portfolio Images Grid
                        barber.portfolioImages.isEmpty
                            ? const Center(
                                child: Text(
                                  'Chưa có hình ảnh sản phẩm',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
                                itemCount: barber.portfolioImages.length,
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      barber.portfolioImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),

                        // Tab 2: Reviews List
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Nhận xét từ khách hàng',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  OutlinedButton.icon(
                                    icon: Icon(
                                      hasReviewed ? Icons.check : Icons.rate_review_outlined,
                                      size: 16,
                                      color: hasReviewed ? Colors.grey : const Color(0xFFD4AF37),
                                    ),
                                    label: Text(
                                      hasReviewed ? 'Đã đánh giá' : 'Viết đánh giá',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasReviewed ? Colors.grey : const Color(0xFFD4AF37),
                                      ),
                                    ),
                                    onPressed: hasReviewed ? null : _openAddReviewDialog,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: reviews.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Chưa có nhận xét nào cho Barber này.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: reviews.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final rev = reviews[index];
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E1E),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: const Color(0xFFD4AF37),
                                                    child: Text(
                                                      rev.customerName.isNotEmpty
                                                          ? rev.customerName[0]
                                                          : 'K',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      rev.customerName,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Row(
                                                    children: List.generate(5, (starIdx) {
                                                      return Icon(
                                                        starIdx < rev.rating
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        color: const Color(0xFFD4AF37),
                                                        size: 14,
                                                      );
                                                    }),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                rev.comment,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calendar_month, color: Colors.black),
            label: Text('Đặt Lịch Với ${barber.fullName}'),
            onPressed: () {
              _navigateToBooking(context, barber);
            },
          ),
        ),
      ),
    );
  }
}
