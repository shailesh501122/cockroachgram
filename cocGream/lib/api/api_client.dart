import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_storage.dart';

/// Singleton Dio client with:
///   1. Bearer-token injection on every request
///   2. Transparent refresh on 401 (rotates and replays the request once)
class ApiClient {
  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        // Don't throw on 4xx — let callers handle DRF validation responses.
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    dio.interceptors.add(_authInterceptor());
  }

  static final instance = ApiClient._();
  late final Dio dio;

  /// Set externally when the user signs in/out so we can react to forced logouts.
  void Function()? onSessionExpired;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skipAuth'] != true) {
          final access = await AuthStorage.instance.readAccess();
          if (access != null) {
            options.headers['Authorization'] = 'Bearer $access';
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        if (response.statusCode == 401 && response.requestOptions.extra['retried'] != true) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            // Replay original request with new access token.
            final opts = response.requestOptions
              ..extra['retried'] = true
              ..headers['Authorization'] = 'Bearer ${await AuthStorage.instance.readAccess()}';
            try {
              final retry = await dio.fetch(opts);
              return handler.resolve(retry);
            } catch (_) {
              // fall through
            }
          } else {
            onSessionExpired?.call();
          }
        }
        handler.next(response);
      },
    );
  }

  Future<bool> _tryRefresh() async {
    final refresh = await AuthStorage.instance.readRefresh();
    if (refresh == null) return false;
    try {
      final r = await dio.post(
        '/auth/refresh/',
        data: {'refresh': refresh},
        options: Options(extra: {'skipAuth': true}),
      );
      if (r.statusCode == 200 && r.data is Map) {
        final access = r.data['access'] as String?;
        final newRefresh = r.data['refresh'] as String? ?? refresh;
        if (access != null) {
          await AuthStorage.instance.save(access: access, refresh: newRefresh);
          return true;
        }
      }
    } on DioException catch (_) {}
    return false;
  }
}

/// Lift the most useful info out of a Dio error.
String describeError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      // DRF returns either {field: [msg]} or {detail: msg}.
      if (data['detail'] is String) return data['detail'] as String;
      for (final v in data.values) {
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v is String) return v;
      }
    }
    return error.message ?? 'Network error.';
  }
  return error.toString();
}
