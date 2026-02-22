import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_parameter.dart';
import '../models/app_stats.dart';
import '../models/app_user.dart';
import '../models/paginated_response.dart';
import '../models/reading.dart';
import '../models/subscriber.dart';
import 'app_repository.dart';

class AppStore extends ChangeNotifier {
  AppStore(this._repository);

  final AppRepository _repository;

  final List<AppUser> _users = <AppUser>[];
  final List<Subscriber> _subscribers = <Subscriber>[];
  AppUser? _currentUser;

  bool _syncingUsers = false;
  bool _syncingSubscribers = false;

  static Future<AppStore> initialize() async {
    final repository = AppRepository();
    await repository.init();
    final store = AppStore(repository);
    await store._loadCache();
    unawaited(store.syncUsers());
    unawaited(store.syncSubscribers());
    return store;
  }

  List<AppUser> get users => List.unmodifiable(_users);
  List<Subscriber> get subscribers => List.unmodifiable(_subscribers);
  AppUser? get currentUser => _currentUser;

  bool get isSyncingUsers => _syncingUsers;
  bool get isSyncingSubscribers => _syncingSubscribers;

  int get activeUsers => _users.where((user) => user.active).length;
  int get activeSubscribers => _subscribers.where((sub) => sub.active).length;
  double get monthlyRevenue => _subscribers
      .where((sub) => sub.active)
      .fold(0, (sum, sub) => sum + sub.monthlyFee);

  Future<void> _loadCache() async {
    _users
      ..clear()
      ..addAll(await _repository.loadUsers());
    _subscribers
      ..clear()
      ..addAll(await _repository.loadSubscribers());
    _currentUser = await _repository.loadCurrentUser();
    notifyListeners();
  }

  Future<void> addUser(AppUser user) async {
    final created = await _repository.createUser(user);
    _users.add(created.withoutSecrets());
    notifyListeners();
    unawaited(syncUsers(force: true));
  }

  Future<void> updateUser(AppUser user) async {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index == -1) return;
    final updated = await _repository.upsertUser(user);
    _users[index] = updated.withoutSecrets();
    if (_currentUser != null && _currentUser!.id == updated.id) {
      _currentUser = updated.withoutSecrets();
    }
    notifyListeners();
    if (updated.fullName.trim().isEmpty || updated.email.trim().isEmpty) {
      await syncUsers(force: true);
    }
  }

  Future<void> removeUser(String id) async {
    await _repository.deleteUser(id);
    _users.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> addSubscriber(Subscriber subscriber) async {
    await _repository.createSubscriber(subscriber);
    _subscribers.add(subscriber);
    notifyListeners();
  }

  Future<void> updateSubscriber(Subscriber subscriber) async {
    final index = _subscribers.indexWhere((item) => item.id == subscriber.id);
    if (index == -1) return;
    await _repository.upsertSubscriber(subscriber);
    _subscribers[index] = subscriber;
    notifyListeners();
  }

  Future<void> removeSubscriber(String id) async {
    await _repository.deleteSubscriber(id);
    _subscribers.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<Subscriber?> fetchSubscriber(String id) async {
    return await _repository.fetchSubscriber(id);
  }

  Future<void> saveAuthToken({
    required String token,
    required String tokenType,
  }) async {
    await _repository.saveAuthToken(token: token, tokenType: tokenType);
  }

  Future<void> clearAuthToken() async {
    await _repository.clearAuthToken();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> saveCurrentUser(AppUser user) async {
    await _repository.saveCurrentUser(user);
    _currentUser = user.withoutSecrets();
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final updated = await _repository.refreshCurrentUser();
    if (updated != null) {
      _currentUser = updated.withoutSecrets();
      notifyListeners();
    }
  }

  Future<AppUser?> uploadCurrentUserAvatar(String filePath) async {
    final user = _currentUser;
    if (user == null) return null;
    final updated = await _repository.uploadUserAvatar(
      userId: user.id,
      filePath: filePath,
    );
    _currentUser = updated.withoutSecrets();
    final index = _users.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _users[index] = updated.withoutSecrets();
    }
    notifyListeners();
    return updated;
  }

  Future<bool> hasAuthToken() async {
    final token = await _repository.loadAuthToken();
    return token != null && token.token.isNotEmpty;
  }

  Future<PaginatedResponse<Reading>> fetchReadings({
    String? abonneId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
  }) async {
    return _repository.fetchReadings(
      abonneId: abonneId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
    );
  }

  Future<List<AppParameter>> fetchParameters() async {
    return _repository.fetchParameters();
  }

  Future<AppParameter> createParameter(AppParameter parameter) async {
    return _repository.createParameter(parameter);
  }

  Future<AppParameter> updateParameter(AppParameter parameter) async {
    return _repository.updateParameter(parameter);
  }

  Future<AppStats> fetchStats() async {
    return _repository.fetchStats();
  }

  Future<Reading> createReading({
    required String abonneId,
    required DateTime date,
    required double indexValue,
    required double prixM3,
    required bool isPaid,
  }) async {
    return _repository.createReading(
      abonneId: abonneId,
      date: date,
      indexValue: indexValue,
      prixM3: prixM3,
      isPaid: isPaid,
    );
  }

  Future<Reading> fetchReading(String id) async {
    return _repository.fetchReading(id);
  }

  Future<Facturation> createFacturation({
    required String readingId,
    required double pricePerM3,
    required String currency,
    required bool isPaid,
  }) async {
    return _repository.createFacturation(
      readingId: readingId,
      pricePerM3: pricePerM3,
      currency: currency,
      isPaid: isPaid,
    );
  }

  Future<Reading> updateReading({
    required String readingId,
    required DateTime date,
    required double indexValue,
  }) async {
    return _repository.updateReading(
      readingId: readingId,
      date: date,
      indexValue: indexValue,
    );
  }

  Future<void> deleteReading(String id) async {
    await _repository.deleteReading(id);
  }

  Future<void> deleteFacturation(String id) async {
    await _repository.deleteFacturation(id);
  }

  Future<void> updateFacturationStatus(String id, bool isPaid) async {
    await _repository.updateFacturationStatus(id, isPaid);
  }

  Future<SyncResult> syncUsers({bool force = false}) async {
    if (_syncingUsers) {
      return const SyncResult(SyncStatus.skipped);
    }
    _syncingUsers = true;
    notifyListeners();
    try {
      final result = await _repository.syncUsers(force: force);
      _users
        ..clear()
        ..addAll(await _repository.loadUsers());
      final current = _currentUser;
      if (current != null) {
        for (final user in _users) {
          if (user.id == current.id) {
            _currentUser = user.withoutSecrets();
            break;
          }
        }
      }
      debugPrint(
        'Sync users done status=${result.status} count=${_users.length} message=${result.message ?? ''}',
      );
      return result;
    } catch (error, stackTrace) {
      debugPrint('Sync users error: $error');
      debugPrint(stackTrace.toString());
      return const SyncResult(
        SyncStatus.partial,
        message: 'Erreur de synchronisation utilisateurs',
      );
    } finally {
      _syncingUsers = false;
      notifyListeners();
    }
  }

  Future<SyncResult> syncSubscribers({bool force = false}) async {
    if (_syncingSubscribers) {
      return const SyncResult(SyncStatus.skipped);
    }
    _syncingSubscribers = true;
    notifyListeners();
    try {
      final result = await _repository.syncSubscribers(force: force);
      _subscribers
        ..clear()
        ..addAll(await _repository.loadSubscribers());
      debugPrint(
        'Sync subscribers done status=${result.status} count=${_subscribers.length} message=${result.message ?? ''}',
      );
      return result;
    } catch (error, stackTrace) {
      debugPrint('Sync subscribers error: $error');
      debugPrint(stackTrace.toString());
      return const SyncResult(
        SyncStatus.partial,
        message: 'Erreur de synchronisation abonnes',
      );
    } finally {
      _syncingSubscribers = false;
      notifyListeners();
    }
  }
}
