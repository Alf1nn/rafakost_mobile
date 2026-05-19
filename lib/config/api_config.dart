class ApiConfig {
  static const String baseUrl = 'https://rafakost.biz.id/api';
  static const String storageUrl = 'https://rafakost.biz.id/storage';

  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }

    if (path.startsWith('http')) {
      return path;
    }

    return '$storageUrl/$path';
  }
}