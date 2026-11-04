import 'package:flutter/material.dart';
import 'app_network_image.dart';

/// Màn hình xem ảnh toàn màn hình với tính năng phóng to (Zoom/Pinch),
/// vuốt qua lại giữa các ảnh (Swipe) và nút xóa ảnh (nếu được cấp quyền).
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final Future<void> Function(String url)? onDelete;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.onDelete,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late List<String> _currentImages;

  @override
  void initState() {
    super.initState();
    _currentImages = List<String>.from(widget.images);
    _currentIndex = widget.initialIndex.clamp(0, _currentImages.isNotEmpty ? _currentImages.length - 1 : 0);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    if (_currentImages.isEmpty) return;
    final currentUrl = _currentImages[_currentIndex];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Xóa ảnh portfolio',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa ảnh này khỏi danh sách portfolio không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa ảnh'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && widget.onDelete != null) {
      await widget.onDelete!(currentUrl);
      setState(() {
        _currentImages.removeAt(_currentIndex);
        if (_currentIndex >= _currentImages.length && _currentImages.isNotEmpty) {
          _currentIndex = _currentImages.length - 1;
        }
      });

      if (_currentImages.isEmpty && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImages.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Không có ảnh nào', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          '${_currentIndex + 1} / ${_currentImages.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
              tooltip: 'Xóa ảnh này',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _currentImages.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final imageUrl = _currentImages[index];
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: AppNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                autoOptimize: false, // Giữ độ phân giải gốc khi xem toàn màn hình
              ),
            ),
          );
        },
      ),
    );
  }
}
