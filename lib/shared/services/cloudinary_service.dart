import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Singleton pattern
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  /// =========================================================================
  /// CẤU HÌNH CLOUDINARY
  /// Thay thế cloudName và uploadPreset bằng thông tin tài khoản Cloudinary của bạn:
  /// 1. Đăng nhập https://cloudinary.com
  /// 2. Lấy Cloud Name ở Dashboard
  /// 3. Vào Settings -> Upload -> Upload Presets -> Add Upload Preset -> Signing Mode: "Unsigned"
  /// =========================================================================
  static String cloudName =
      'c3c2yz54'; // Cloud Name mặc định hoặc điền cloud name của bạn
  static String uploadPreset =
      'barber_app_preset'; // Upload Preset dạng Unsigned

  /// Đặt cấu hình Cloudinary động trong code khi cần
  static void configure({
    required String newCloudName,
    required String newUploadPreset,
  }) {
    cloudName = newCloudName;
    uploadPreset = newUploadPreset;
  }

  /// Tải ảnh lên Cloudinary từ [XFile] (từ image_picker)
  /// Trả về link HTTPS [secure_url] trực tiếp để lưu vào database và hiển thị
  Future<String> uploadImage(XFile file, {String folder = 'barbershop'}) async {
    final bytes = await file.readAsBytes();
    return uploadImageBytes(
      bytes,
      filename: file.name.isNotEmpty
          ? file.name
          : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      folder: folder,
    );
  }

  /// Tải ảnh lên Cloudinary từ [Uint8List] bytes
  Future<String> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'image.jpg',
    String folder = 'barbershop',
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Chưa cấu hình Cloudinary cloudName hoặc uploadPreset.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;
    if (folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl != null && secureUrl.isNotEmpty) {
        return secureUrl;
      }
      throw Exception('Không tìm thấy link ảnh trong phản hồi từ Cloudinary.');
    } else {
      String errorMessage =
          'Lỗi tải ảnh lên Cloudinary (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        if (errJson.containsKey('error') && errJson['error'] is Map) {
          errorMessage = errJson['error']['message'] ?? errorMessage;
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  /// Tạo link tối ưu hóa ảnh Cloudinary (tự động nén chất lượng q_auto, định dạng f_auto, scale/crop)
  /// Giúp ảnh load siêu nhanh và tiết kiệm dung lượng
  static String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String crop = 'fill',
    int? quality,
  }) {
    if (!originalUrl.contains('res.cloudinary.com') ||
        !originalUrl.contains('/image/upload/')) {
      return originalUrl;
    }

    final transformations = <String>[];
    if (width != null && height != null) {
      transformations.add('c_$crop,w_$width,h_$height');
    } else if (width != null) {
      transformations.add('w_$width');
    } else if (height != null) {
      transformations.add('h_$height');
    }

    transformations.add('f_auto'); // Auto format (WebP / AVIF)
    if (quality != null) {
      transformations.add('q_$quality');
    } else {
      transformations.add('q_auto'); // Auto quality optimization
    }

    final transformStr = transformations.join(',');
    return originalUrl.replaceFirst(
      '/image/upload/',
      '/image/upload/$transformStr/',
    );
  }
}
