import 'package:flutter/material.dart';
import 'package:barber_booking_app/shared/services/cloudinary_service.dart';

/// Widget chuyên dụng để tải và hiển thị ảnh từ Cloudinary hoặc bất kỳ URL mạng nào
/// Tự động áp dụng tối ưu hóa kích thước (resize, f_auto, q_auto) để load nhanh nhất
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool autoOptimize;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.autoOptimize = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildDefaultError();
    }

    final effectiveUrl = autoOptimize
        ? CloudinaryService.getOptimizedUrl(
            imageUrl!,
            width: (width != null && width!.isFinite) ? (width! * 1.5).toInt() : null,
            height: (height != null && height!.isFinite) ? (height! * 1.5).toInt() : null,
          )
        : imageUrl!;

    Widget imageWidget = Image.network(
      effectiveUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.white10,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildDefaultError();
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}

