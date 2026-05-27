import 'dart:io';

import 'package:dio/dio.dart';

class ImgbbClient {
  final String apiKey;
  final Dio _dio;

  ImgbbClient({required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  /// Uploads a local [file] to imgbb and returns the direct image URL.
  /// Throws a [DioException] or generic [Exception] on failure.
  Future<String> uploadFile(File file, {String? name}) async {
    final url = 'https://api.imgbb.com/1/upload';

    final formData = FormData.fromMap({
      'key': apiKey,
      'image': await MultipartFile.fromFile(
        file.path,
        filename: name ?? file.uri.pathSegments.last,
      ),
    });

    final resp = await _dio.post(url, data: formData);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = resp.data as Map<String, dynamic>;
      // imgbb v1 response: data.data.display_url or data.data.url
      final imageData = data['data'] as Map<String, dynamic>?;
      if (imageData == null) throw Exception('Invalid imgbb response');
      return imageData['display_url'] ??
          imageData['url'] ??
          imageData['image']?['url'] ??
          '';
    }

    throw Exception('ImgBB upload failed: ${resp.statusCode}');
  }
}
