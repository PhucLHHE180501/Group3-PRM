import 'package:flutter/material.dart';

class CskhScreen extends StatelessWidget {
  const CskhScreen({super.key});

  void _showContactSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD4AF37),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chăm Sóc Khách Hàng (CSKH)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner CSKH
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: Color(0xFFD4AF37),
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hỗ Trợ 24/7',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Chúng tôi luôn sẵn sàng hỗ trợ giải đáp thắc mắc và lắng nghe góp ý của bạn.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Liên Hệ Trực Tiếp Quán Barber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Hotline Button / Link
            _buildContactLinkTile(
              context: context,
              icon: Icons.phone,
              iconColor: Colors.green,
              title: 'Hotline Tổng Đài',
              subtitle: '1900 8888 (Miễn phí cuộc gọi)',
              actionText: 'Gọi ngay',
              onTap: () {
                _showContactSnackbar(context, 'Đang kết nối cuộc gọi đến Hotline: 1900 8888');
              },
            ),
            const SizedBox(height: 12),

            // Zalo Link
            _buildContactLinkTile(
              context: context,
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.blue,
              title: 'Zalo CSKH Barber',
              subtitle: 'Chat trực tiếp với nhân viên hỗ trợ',
              actionText: 'Mở Zalo',
              onTap: () {
                _showContactSnackbar(context, 'Đang mở liên kết Zalo CSKH...');
              },
            ),
            const SizedBox(height: 12),

            // Fanpage Facebook Link
            _buildContactLinkTile(
              context: context,
              icon: Icons.facebook,
              iconColor: Colors.indigoAccent,
              title: 'Fanpage Facebook',
              subtitle: 'fb.com/barbershop.official',
              actionText: 'Truy cập',
              onTap: () {
                _showContactSnackbar(context, 'Đang mở trang Fanpage Facebook...');
              },
            ),
            const SizedBox(height: 12),

            // Location Link
            _buildContactLinkTile(
              context: context,
              icon: Icons.map_outlined,
              iconColor: const Color(0xFFD4AF37),
              title: 'Địa Chỉ Tiệm Cắt Tóc',
              subtitle: '123 Đường Nam Kỳ Khởi Nghĩa, Quận 1, TP.HCM',
              actionText: 'Xem bản đồ',
              onTap: () {
                _showContactSnackbar(context, 'Đang mở Google Maps chỉ đường...');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactLinkTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37)),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
