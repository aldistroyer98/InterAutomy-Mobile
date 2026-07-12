import 'package:dio/dio.dart';

import '../../app/app_config.dart';
import '../errors/app_exception.dart';

final class ApiClient {
  ApiClient({required String baseUrl, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {'Accept': 'application/json'},
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-InterAutomy-Client'] = 'mobile';
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  set baseUrl(String value) => _dio.options.baseUrl = value;

  Future<Response<T>> get<T>(String path) => _request(() => _dio.get<T>(path));

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _request(() => _dio.post<T>(path, data: data));

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() operation,
  ) async {
    try {
      return await operation();
    } on DioException catch (error) {
      final message = switch (error.type) {
        DioExceptionType.connectionTimeout =>
          'La conexión con la API agotó el tiempo de espera.',
        DioExceptionType.receiveTimeout =>
          'La API tardó demasiado en responder.',
        DioExceptionType.connectionError =>
          'No se pudo establecer conexión con la API.',
        DioExceptionType.badResponse =>
          'La API respondió con el estado ${error.response?.statusCode ?? 'desconocido'}.',
        _ => 'Ocurrió un error de red al comunicarse con la API.',
      };
      throw NetworkException(message);
    }
  }
}
