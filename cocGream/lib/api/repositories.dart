// All repositories — thin wrappers over the API endpoints, returning models.

import 'package:dio/dio.dart';

import '../data.dart';
import 'api_client.dart';
import 'auth_storage.dart';

Dio get _dio => ApiClient.instance.dio;

/// Pull the `results` array out of either a paginated DRF response or a raw list.
List<Map<String, dynamic>> _unwrap(dynamic body) {
  if (body is List) {
    return body.cast<Map<String, dynamic>>();
  }
  if (body is Map && body['results'] is List) {
    return (body['results'] as List).cast<Map<String, dynamic>>();
  }
  return const [];
}

// ===== Auth =====
class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  /// Returns the freshly-created user. Tokens are persisted to secure storage.
  Future<User> signup({
    required String name,
    required String username,
    required String contact,
    required String password,
    required String state,
    required bool agree,
  }) async {
    final r = await _dio.post(
      '/auth/signup/',
      data: {
        'name': name,
        'username': username,
        'contact': contact,
        'password': password,
        'state': state,
        'agree': agree,
      },
      options: Options(extra: {'skipAuth': true}),
    );
    _ensure2xx(r);
    final data = r.data as Map<String, dynamic>;
    await AuthStorage.instance.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> login({required String identifier, required String password}) async {
    final r = await _dio.post(
      '/auth/login/',
      data: {'identifier': identifier, 'password': password},
      options: Options(extra: {'skipAuth': true}),
    );
    _ensure2xx(r);
    final data = r.data as Map<String, dynamic>;
    await AuthStorage.instance.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refresh = await AuthStorage.instance.readRefresh();
    if (refresh != null) {
      try {
        await _dio.post('/auth/logout/', data: {'refresh': refresh});
      } on DioException catch (_) {}
    }
    await AuthStorage.instance.clear();
  }
}

// ===== Users =====
class UsersRepository {
  UsersRepository._();
  static final instance = UsersRepository._();

  Future<User> me() async {
    final r = await _dio.get('/users/me/');
    _ensure2xx(r);
    return User.fromJson(r.data as Map<String, dynamic>);
  }

  Future<User> byUsername(String username) async {
    final r = await _dio.get('/users/$username/');
    _ensure2xx(r);
    return User.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> follow(String username) async {
    final r = await _dio.post('/users/$username/follow/');
    _ensure2xx(r);
  }

  Future<void> unfollow(String username) async {
    final r = await _dio.delete('/users/$username/follow/');
    _ensure2xx(r);
  }
}

// ===== Posts =====
class PostsRepository {
  PostsRepository._();
  static final instance = PostsRepository._();

  Future<List<Post>> feed({required String tab}) async {
    final r = await _dio.get('/posts/', queryParameters: {'tab': tab});
    _ensure2xx(r);
    return _unwrap(r.data).map(Post.fromJson).toList();
  }

  Future<Post> create({
    required String text,
    required List<String> tags,
    String audience = 'public',
  }) async {
    final body = text + (tags.isEmpty ? '' : '  ${tags.map((t) => '#$t').join(' ')}');
    final r = await _dio.post(
      '/posts/',
      data: {'text': body, 'audience': audience, 'tags': tags},
    );
    _ensure2xx(r);
    return Post.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> like(int postId, {required bool liked}) async {
    final r = liked
        ? await _dio.post('/posts/$postId/like/')
        : await _dio.delete('/posts/$postId/like/');
    _ensure2xx(r);
  }

  Future<void> repost(int postId, {required bool reposted}) async {
    final r = reposted
        ? await _dio.post('/posts/$postId/repost/')
        : await _dio.delete('/posts/$postId/repost/');
    _ensure2xx(r);
  }

  Future<void> bookmark(int postId, {required bool bookmarked}) async {
    final r = bookmarked
        ? await _dio.post('/posts/$postId/bookmark/')
        : await _dio.delete('/posts/$postId/bookmark/');
    _ensure2xx(r);
  }
}

// ===== Trending =====
class TrendingRepository {
  TrendingRepository._();
  static final instance = TrendingRepository._();

  Future<List<Trend>> list({String window = 'now'}) async {
    final r = await _dio.get('/trending/', queryParameters: {'window': window});
    _ensure2xx(r);
    final data = r.data as Map<String, dynamic>;
    return (data['results'] as List)
        .cast<Map<String, dynamic>>()
        .map(Trend.fromJson)
        .toList();
  }
}

// ===== Notifications =====
class NotificationsRepository {
  NotificationsRepository._();
  static final instance = NotificationsRepository._();

  Future<List<Notif>> list({String filter = 'all'}) async {
    final r = await _dio.get('/notifications/', queryParameters: {'filter': filter});
    _ensure2xx(r);
    return _unwrap(r.data).map(Notif.fromJson).toList();
  }

  Future<int> unreadCount() async {
    final r = await _dio.get('/notifications/unread/');
    _ensure2xx(r);
    return ((r.data as Map)['unread'] as num).toInt();
  }

  Future<void> markAllRead() async {
    final r = await _dio.post('/notifications/read/', data: {'all': true});
    _ensure2xx(r);
  }
}

// ===== shared =====
void _ensure2xx(Response r) {
  if (r.statusCode == null || r.statusCode! >= 300) {
    throw DioException(
      requestOptions: r.requestOptions,
      response: r,
      message: 'API error ${r.statusCode}',
    );
  }
}
