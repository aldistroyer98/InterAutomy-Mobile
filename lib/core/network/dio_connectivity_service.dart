import 'package:dio/dio.dart';

import '../../domain/services/connectivity_service.dart';

final class DioConnectivityService implements ConnectivityService {
  DioConnectivityService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<bool> canReach(String baseUrl) async {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
    try {
      final response = await _dio.headUri<void>(
        uri,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode != null && response.statusCode! < 500;
    } on DioException {
      return false;
    }
  }
}
