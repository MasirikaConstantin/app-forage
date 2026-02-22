import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_parameter.dart';
import '../models/app_stats.dart';
import '../models/app_user.dart';
import '../models/paginated_response.dart';
import '../models/reading.dart';
import '../models/subscriber.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    this.baseUrl = 'https://gestion.royalhouse-deboraa.com/api/v1',
  }) : _client = client ?? http.Client();

  static const String usersPath = '/users';
  static const String subscribersPath = '/abonnes';
  static const String readingsPath = '/releves';
  static const String parametersPath = '/parametres';
  static const String mePath = '/me';
  static const String logoutPath = '/logout';
  static const String statsPath = '/stats';
  static const String syncPath = '/sync';

  final http.Client _client;
  final String baseUrl;
  String? _token;
  String _tokenType = 'Bearer';

  void setAuthToken({required String token, String? tokenType}) {
    _token = token;
    if (tokenType != null && tokenType.isNotEmpty) {
      _tokenType = tokenType;
    }
  }

  Future<List<AppUser>> fetchUsers() async {
    debugPrint('GET $baseUrl$usersPath (auth=${_token != null})');
    final response = await _client.get(
      Uri.parse('$baseUrl$usersPath'),
      headers: _headers(),
    );
    debugPrint('GET users status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    final items = _extractList(payload);
    debugPrint('GET users items=${items.length} body=${response.body}');
    return items.map(AppUser.fromApi).toList();
  }

  Future<AppUser> fetchUser(String id) async {
    debugPrint('GET $baseUrl$usersPath/$id (auth=${_token != null})');
    final response = await _client.get(
      Uri.parse('$baseUrl$usersPath/$id'),
      headers: _headers(),
    );
    debugPrint('GET user status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    return AppUser.fromApi(_extractObject(payload));
  }

  Future<List<Subscriber>> fetchSubscribers() async {
    debugPrint('GET $baseUrl$subscribersPath (auth=${_token != null})');
    final response = await _client.get(
      Uri.parse('$baseUrl$subscribersPath'),
      headers: _headers(),
    );
    debugPrint('GET subscribers status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    final items = _extractList(payload);
    debugPrint('GET subscribers items=${items.length}');
    return items.map(Subscriber.fromApi).toList();
  }

  Future<Subscriber?> fetchSubscriber(String id) async {
    debugPrint('GET $baseUrl$subscribersPath/$id (auth=${_token != null})');
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$subscribersPath/$id'),
        headers: _headers(),
      );
      debugPrint('GET subscriber status=${response.statusCode}');
      _ensureSuccess(response);
      final payload = jsonDecode(response.body);
      return Subscriber.fromApi(payload);
    } catch (e) {
      debugPrint('Error fetching subscriber $id: $e');
      return null;
    }
  }

  Future<PaginatedResponse<Reading>> fetchReadings({
    String? abonneId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (abonneId != null && abonneId.isNotEmpty) {
      params['abonne_id'] = abonneId;
    }
    if (dateFrom != null) {
      params['date_from'] = dateFrom.toIso8601String().split('T').first;
    }
    if (dateTo != null) {
      params['date_to'] = dateTo.toIso8601String().split('T').first;
    }
    final uri = Uri.parse(
      '$baseUrl$readingsPath',
    ).replace(queryParameters: params.isEmpty ? null : params);

    debugPrint('GET $uri (auth=${_token != null})');
    final response = await _client.get(uri, headers: _headers());
    debugPrint('GET releves status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);

    // Check if payload has pagination structure
    if (payload is Map<String, dynamic> &&
        payload.containsKey('current_page')) {
      return PaginatedResponse<Reading>.fromJson(payload, Reading.fromApi);
    }

    // Fallback for flat list or wrapped in data without pagination keys (legacy support)
    final items = _extractList(payload);
    debugPrint('GET releves items=${items.length}');
    return PaginatedResponse<Reading>(
      items: items.map(Reading.fromApi).toList(),
      currentPage: 1,
      lastPage: 1,
      total: items.length,
    );
  }

  Future<AppUser> fetchMe() async {
    debugPrint('GET $baseUrl$mePath (auth=${_token != null})');
    final response = await _client.get(
      Uri.parse('$baseUrl$mePath'),
      headers: _headers(),
    );
    debugPrint('GET me status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    return AppUser.fromApi(_extractObject(payload));
  }

  Future<void> logout() async {
    debugPrint('POST $baseUrl$logoutPath (auth=${_token != null})');
    final response = await _client.post(
      Uri.parse('$baseUrl$logoutPath'),
      headers: _headers(),
    );
    debugPrint('POST logout status=${response.statusCode}');
    _ensureSuccess(response);
  }

  Future<AppStats> fetchStats() async {
    debugPrint('GET $baseUrl$statsPath (auth=${_token != null})');
    final response = await _client.get(
      Uri.parse('$baseUrl$statsPath'),
      headers: _headers(),
    );
    debugPrint('GET stats status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    if (payload is Map<String, dynamic>) {
      return AppStats.fromApi(payload);
    }
    return AppStats.fromApi(<String, dynamic>{});
  }

  Future<List<AppParameter>> fetchParameters() async {
    debugPrint('GET $baseUrl$parametersPath (auth=${_token != null})');
    final response = await _client.get(
      Uri.parse('$baseUrl$parametersPath'),
      headers: _headers(),
    );
    debugPrint('GET parametres status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    final items = _extractList(payload);
    debugPrint('GET parametres items=${items.length}');
    return items.map(AppParameter.fromApi).toList();
  }

  Future<AppParameter> createParameter(AppParameter parameter) async {
    debugPrint('POST $baseUrl$parametersPath (auth=${_token != null})');
    final response = await _client.post(
      Uri.parse('$baseUrl$parametersPath'),
      headers: _headers(),
      body: jsonEncode(parameter.toCreatePayload()),
    );
    debugPrint('POST parametres status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    return AppParameter.fromApi(_extractObject(payload));
  }

  Future<AppParameter> updateParameter(AppParameter parameter) async {
    debugPrint(
      'PUT $baseUrl$parametersPath/${parameter.id} (auth=${_token != null})',
    );
    final response = await _client.put(
      Uri.parse('$baseUrl$parametersPath/${parameter.id}'),
      headers: _headers(),
      body: jsonEncode(parameter.toCreatePayload()),
    );
    debugPrint('PUT parametres status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    return AppParameter.fromApi(_extractObject(payload));
  }

  Future<Reading> createReading({
    required String abonneId,
    required DateTime date,
    required double indexValue,
    required double prixM3,
    required bool isPaid,
  }) async {
    final payload = <String, dynamic>{
      'abonne_id': abonneId,
      'date_releve': date.toIso8601String().split('T').first,
      'index': indexValue,
      'prix_m3': prixM3,
      'est_paye': isPaid,
    };
    debugPrint('POST $baseUrl$readingsPath payload=$payload');
    debugPrint('POST $baseUrl$readingsPath (auth=${_token != null})');
    final response = await _client.post(
      Uri.parse('$baseUrl$readingsPath'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    debugPrint('POST releves status=${response.statusCode}');
    _ensureSuccess(response);
    final responsePayload = jsonDecode(response.body);
    return Reading.fromApi(_extractObject(responsePayload));
  }

  Future<Reading> fetchReading(String id) async {
    debugPrint('GET $baseUrl$readingsPath/$id (auth=${_token != null})');
    final response = await _client.get(
      Uri.parse('$baseUrl$readingsPath/$id'),
      headers: _headers(),
    );
    debugPrint('GET releve status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    return Reading.fromApi(_extractObject(payload));
  }

  Future<Facturation> createFacturation({
    required String readingId,
    required double pricePerM3,
    required String currency,
    required bool isPaid,
  }) async {
    final payload = <String, dynamic>{
      'releve_actuel_id': readingId,
      'prix_m3': pricePerM3,
      'devise': currency,
      'est_paye': isPaid,
    };
    debugPrint('POST $baseUrl/facturations payload=$payload');
    final response = await _client.post(
      Uri.parse('$baseUrl/facturations'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    debugPrint('POST facturations status=${response.statusCode}');
    _ensureSuccess(response);
    final responsePayload = jsonDecode(response.body);
    return Facturation.fromApi(_extractObject(responsePayload));
  }

  Future<Reading> updateReading({
    required String readingId,
    required DateTime date,
    required double indexValue,
  }) async {
    final payload = <String, dynamic>{
      'date_releve': date.toIso8601String().split('T').first,
      'index': indexValue,
    };
    debugPrint('PUT $baseUrl$readingsPath/$readingId payload=$payload');
    final response = await _client.put(
      Uri.parse('$baseUrl$readingsPath/$readingId'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    debugPrint('PUT releves status=${response.statusCode}');
    _ensureSuccess(response);
    final responsePayload = jsonDecode(response.body);
    return Reading.fromApi(_extractObject(responsePayload));
  }

  Future<void> deleteReading(String id) async {
    debugPrint('DELETE $baseUrl$readingsPath/$id');
    final response = await _client.delete(
      Uri.parse('$baseUrl$readingsPath/$id'),
      headers: _headers(),
    );
    debugPrint('DELETE releves status=${response.statusCode}');
    _ensureSuccess(response);
  }

  Future<void> deleteFacturation(String id) async {
    debugPrint('DELETE $baseUrl/facturations/$id');
    final response = await _client.delete(
      Uri.parse('$baseUrl/facturations/$id'),
      headers: _headers(),
    );
    debugPrint('DELETE facturations status=${response.statusCode}');
    _ensureSuccess(response);
  }

  Future<void> updateFacturationStatus(String id, bool isPaid) async {
    debugPrint('PATCH $baseUrl/facturations/$id/statut');
    final response = await _client.patch(
      Uri.parse('$baseUrl/facturations/$id/statut'),
      headers: _headers(),
      body: jsonEncode(<String, dynamic>{'est_paye': isPaid}),
    );
    debugPrint('PATCH facturations status=${response.statusCode}');
    _ensureSuccess(response);
  }

  Future<List<Subscriber>> syncSubscribers({
    required String deviceUuid,
    required List<Map<String, dynamic>> abonnes,
    required List<Map<String, dynamic>> releves,
    required List<Map<String, dynamic>> facturations,
    required List<Map<String, dynamic>> parametres,
  }) async {
    debugPrint('POST $baseUrl$syncPath (auth=${_token != null})');
    final response = await _client.post(
      Uri.parse('$baseUrl$syncPath'),
      headers: _headers(),
      body: jsonEncode(<String, dynamic>{
        'device_uuid': deviceUuid,
        'users': const <Map<String, dynamic>>[],
        'abonnes': abonnes,
        'releves': releves,
        'facturations': facturations,
        'parametres': parametres,
      }),
    );
    debugPrint('POST sync status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    final items = _extractSyncList(payload, 'abonnes');
    debugPrint('POST sync abonnes=${items.length}');
    return items.map(Subscriber.fromApi).toList();
  }

  Future<List<AppUser>> syncUsers({
    required String deviceUuid,
    required List<Map<String, dynamic>> users,
    required List<Map<String, dynamic>> abonnes,
    required List<Map<String, dynamic>> releves,
    required List<Map<String, dynamic>> facturations,
    required List<Map<String, dynamic>> parametres,
  }) async {
    debugPrint('POST $baseUrl$syncPath (auth=${_token != null})');
    final response = await _client.post(
      Uri.parse('$baseUrl$syncPath'),
      headers: _headers(),
      body: jsonEncode(<String, dynamic>{
        'device_uuid': deviceUuid,
        'users': users,
        'abonnes': abonnes,
        'releves': releves,
        'facturations': facturations,
        'parametres': parametres,
      }),
    );
    debugPrint('POST sync users status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    final items = _extractSyncList(payload, 'users');
    debugPrint('POST sync users count=${items.length}');
    return items.map(AppUser.fromApi).toList();
  }

  Future<AppUser> createUser(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$usersPath'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    _ensureSuccess(response);
    final responsePayload = jsonDecode(response.body);
    return AppUser.fromApi(_extractObject(responsePayload));
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> payload) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$usersPath/$id'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    _ensureSuccess(response);
    final responsePayload = jsonDecode(response.body);
    return AppUser.fromApi(_extractObject(responsePayload));
  }

  Future<void> deleteUser(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$usersPath/$id'),
      headers: _headers(),
    );
    _ensureSuccess(response);
  }

  Future<AppUser> uploadUserAvatar({
    required String userId,
    required String filePath,
  }) async {
    final uri = Uri.parse('$baseUrl$usersPath/$userId/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers()..remove('Content-Type'));
    request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

    debugPrint('POST $uri (avatar upload)');
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    return AppUser.fromApi(_extractObject(payload));
  }

  Future<Subscriber> createSubscriber(Subscriber subscriber) async {
    debugPrint('POST $baseUrl$subscribersPath (auth=${_token != null})');
    final response = await _client.post(
      Uri.parse('$baseUrl$subscribersPath'),
      headers: _headers(),
      body: jsonEncode(subscriber.toApiPayload()),
    );
    debugPrint('POST abonnes status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    return Subscriber.fromApi(_extractObject(payload));
  }

  Future<Subscriber> updateSubscriber(Subscriber subscriber) async {
    debugPrint(
      'PUT $baseUrl$subscribersPath/${subscriber.id} (auth=${_token != null})',
    );
    final response = await _client.put(
      Uri.parse('$baseUrl$subscribersPath/${subscriber.id}'),
      headers: _headers(),
      body: jsonEncode(subscriber.toApiPayload()),
    );
    debugPrint('PUT abonnes status=${response.statusCode}');
    _ensureSuccess(response);
    final payload = jsonDecode(response.body);
    return Subscriber.fromApi(_extractObject(payload));
  }

  Future<void> deleteSubscriber(String id) async {
    debugPrint('DELETE $baseUrl$subscribersPath/$id (auth=${_token != null})');
    final response = await _client.delete(
      Uri.parse('$baseUrl$subscribersPath/$id'),
      headers: _headers(),
    );
    _ensureSuccess(response);
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = '$_tokenType $_token';
    }
    return headers;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    debugPrint('API error status=${response.statusCode} body=${response.body}');

    String message = 'Erreur serveur (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        message = decoded['message'].toString();
      }
    } catch (_) {
      // Fallback to default message if parsing fails
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _extractSyncList(dynamic payload, String key) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        final list = data[key];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
      final list = payload[key];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractObject(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      if (payload['data'] is Map) {
        final data = Map<String, dynamic>.from(payload['data'] as Map);
        final nestedUser = data['user'];
        if (nestedUser is Map) {
          return Map<String, dynamic>.from(nestedUser);
        }
        final nestedSubscriber = data['subscriber'];
        if (nestedSubscriber is Map) {
          return Map<String, dynamic>.from(nestedSubscriber);
        }
        return data;
      }
      return payload;
    }
    if (payload is List && payload.isNotEmpty && payload.first is Map) {
      return Map<String, dynamic>.from(payload.first as Map);
    }
    return <String, dynamic>{};
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
