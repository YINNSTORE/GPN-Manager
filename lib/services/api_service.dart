import 'package:dio/dio.dart';
import '../models/server_config.dart';
import '../models/user_item.dart';

class ApiService {
  Dio _dio(ServerConfig server) {
    return Dio(
      BaseOptions(
        baseUrl: server.baseUrl,
        headers: {
          'X-API-Key': server.apiKey,
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
  }

  Future<Map<String, dynamic>> getInfo(ServerConfig server) async {
    final res = await _dio(server).get('/api/info');
    return _normalizeMap(res.data);
  }

  Future<List<UserItem>> getUsers(ServerConfig server) async {
    final res = await _dio(server).get('/api/users');
    final data = res.data;

    if (data is List) {
      return data
          .map((e) => UserItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data['data'] ?? data['users'] ?? data['result'];
      if (list is List) {
        return list
            .map((e) => UserItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> createUser(
    ServerConfig server, {
    required String password,
    int? days,
    int? minutes,
  }) async {
    final body = <String, dynamic>{'password': password};
    if (days != null) body['days'] = days;
    if (minutes != null) body['minutes'] = minutes;

    final res = await _dio(server).post('/api/user/create', data: body);
    return _normalizeMap(res.data);
  }

  Future<Map<String, dynamic>> renewUser(
    ServerConfig server, {
    required String password,
    required int days,
  }) async {
    final res = await _dio(server).post(
      '/api/user/renew',
      data: {'password': password, 'days': days},
    );
    return _normalizeMap(res.data);
  }

  Future<Map<String, dynamic>> deleteUser(
    ServerConfig server, {
    required String password,
  }) async {
    final res = await _dio(server).post(
      '/api/user/delete',
      data: {'password': password},
    );
    return _normalizeMap(res.data);
  }

  Future<Map<String, dynamic>> triggerExpire(ServerConfig server) async {
    final res = await _dio(server).post('/api/cron/expire');
    return _normalizeMap(res.data);
  }

  Map<String, dynamic> _normalizeMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }
}