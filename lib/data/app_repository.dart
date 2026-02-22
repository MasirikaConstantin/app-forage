import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../models/app_parameter.dart';
import '../models/app_stats.dart';
import '../models/app_user.dart';
import '../models/paginated_response.dart';
import '../models/reading.dart';
import '../models/subscriber.dart';
import 'api_client.dart';
import 'isar_models.dart';
import 'isar_service.dart';

class AppRepository {
  AppRepository({
    ApiClient? apiClient,
    IsarService? isarService,
    Connectivity? connectivity,
  }) : _apiClient = apiClient ?? ApiClient(),
       _isarService = isarService ?? IsarService.instance,
       _connectivity = connectivity ?? Connectivity();

  static const Duration defaultSyncTtl = Duration(minutes: 10);

  final ApiClient _apiClient;
  final IsarService _isarService;
  final Connectivity _connectivity;

  Isar get _isar => _isarService.isar;

  Future<void> init() async {
    await _isarService.init();
    final token = await loadAuthToken();
    if (token != null) {
      _apiClient.setAuthToken(token: token.token, tokenType: token.tokenType);
    }
  }

  Future<List<AppUser>> loadUsers() async {
    final entities = await _isar.userEntitys.where().findAll();
    return entities.map(_mapUserEntity).toList();
  }

  Future<List<Subscriber>> loadSubscribers() async {
    final entities = await _isar.subscriberEntitys.where().findAll();
    return entities.map(_mapSubscriberEntity).toList();
  }

  Future<Subscriber?> fetchSubscriber(String id) async {
    return await _apiClient.fetchSubscriber(id);
  }

  Future<List<AppParameter>> fetchParameters() async {
    return _apiClient.fetchParameters();
  }

  Future<AppParameter> createParameter(AppParameter parameter) async {
    return _apiClient.createParameter(parameter);
  }

  Future<AppParameter> updateParameter(AppParameter parameter) async {
    return _apiClient.updateParameter(parameter);
  }

  Future<AppStats> fetchStats() async {
    return _apiClient.fetchStats();
  }

  Future<PaginatedResponse<Reading>> fetchReadings({
    String? abonneId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
  }) async {
    return _apiClient.fetchReadings(
      abonneId: abonneId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
    );
  }

  Future<Reading> createReading({
    required String abonneId,
    required DateTime date,
    required double indexValue,
    required double prixM3,
    required bool isPaid,
  }) async {
    return _apiClient.createReading(
      abonneId: abonneId,
      date: date,
      indexValue: indexValue,
      prixM3: prixM3,
      isPaid: isPaid,
    );
  }

  Future<Reading> fetchReading(String id) async {
    return _apiClient.fetchReading(id);
  }

  Future<Facturation> createFacturation({
    required String readingId,
    required double pricePerM3,
    required String currency,
    required bool isPaid,
  }) async {
    return _apiClient.createFacturation(
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
    return _apiClient.updateReading(
      readingId: readingId,
      date: date,
      indexValue: indexValue,
    );
  }

  Future<void> deleteReading(String id) async {
    await _apiClient.deleteReading(id);
  }

  Future<void> deleteFacturation(String id) async {
    await _apiClient.deleteFacturation(id);
  }

  Future<void> updateFacturationStatus(String id, bool isPaid) async {
    await _apiClient.updateFacturationStatus(id, isPaid);
  }

  Future<AuthToken?> loadAuthToken() async {
    return _isar.authTokens.filter().keyEqualTo('auth').findFirst();
  }

  Future<AppUser?> loadCurrentUser() async {
    final entity = await _isar.currentUserEntitys
        .filter()
        .keyEqualTo('current')
        .findFirst();
    if (entity == null) return null;
    return _mapCurrentUserEntity(entity);
  }

  Future<void> saveCurrentUser(AppUser user) async {
    await _isar.writeTxn(() async {
      final entry = _mapCurrentUserToEntity(user)..key = 'current';
      await _isar.currentUserEntitys.put(entry);
    });
  }

  Future<void> clearCurrentUser() async {
    await _isar.writeTxn(() async {
      final entry = await _isar.currentUserEntitys
          .filter()
          .keyEqualTo('current')
          .findFirst();
      if (entry != null) {
        await _isar.currentUserEntitys.delete(entry.isarId);
      }
    });
  }

  Future<AppUser?> refreshCurrentUser() async {
    final current = await loadCurrentUser();
    final updated = current == null
        ? await _apiClient.fetchMe()
        : await _apiClient.fetchUser(current.id);
    await _isar.writeTxn(() async {
      final existing = await _isar.userEntitys
          .filter()
          .userIdEqualTo(updated.id)
          .findFirst();
      final entity = _mapUserToEntity(updated);
      if (existing != null) {
        entity.isarId = existing.isarId;
      }
      await _isar.userEntitys.put(entity);
    });
    await saveCurrentUser(updated);
    return updated;
  }

  Future<String> deviceUuid() async {
    final existing = await _isar.deviceInfos
        .filter()
        .keyEqualTo('device_uuid')
        .findFirst();
    if (existing != null && existing.value.isNotEmpty) {
      return existing.value;
    }
    final uuid = _generateUuid();
    await _isar.writeTxn(() async {
      final entry = DeviceInfo()
        ..key = 'device_uuid'
        ..value = uuid
        ..createdAt = DateTime.now();
      await _isar.deviceInfos.put(entry);
    });
    return uuid;
  }

  Future<void> saveAuthToken({
    required String token,
    required String tokenType,
  }) async {
    try {
      await _saveAuthTokenInternal(token: token, tokenType: tokenType);
    } on IsarError catch (error) {
      debugPrint('AuthToken save error: $error');
      if (error.toString().contains('Missing')) {
        await _isarService.reopen();
        await _saveAuthTokenInternal(token: token, tokenType: tokenType);
      } else {
        rethrow;
      }
    }
  }

  Future<void> clearAuthToken() async {
    try {
      await _apiClient.logout();
    } catch (error) {
      debugPrint('Logout failed: $error');
    }
    await _isar.writeTxn(() async {
      final entry = await _isar.authTokens
          .filter()
          .keyEqualTo('auth')
          .findFirst();
      if (entry != null) {
        await _isar.authTokens.delete(entry.isarId);
      }
    });
    _apiClient.setAuthToken(token: '', tokenType: 'Bearer');
    await clearCurrentUser();
  }

  Future<void> _saveAuthTokenInternal({
    required String token,
    required String tokenType,
  }) async {
    await _isar.writeTxn(() async {
      final entry = AuthToken()
        ..key = 'auth'
        ..token = token
        ..tokenType = tokenType
        ..createdAt = DateTime.now();
      await _isar.authTokens.put(entry);
    });
    _apiClient.setAuthToken(token: token, tokenType: tokenType);
  }

  Future<AppUser> upsertUser(AppUser user) async {
    final payload = user.toUpdatePayload();
    try {
      final updated = await _apiClient.updateUser(user.id, payload);
      await _isar.writeTxn(() async {
        final existing = await _isar.userEntitys
            .filter()
            .userIdEqualTo(updated.id)
            .findFirst();
        final entity = _mapUserToEntity(updated);
        if (existing != null) {
          entity.isarId = existing.isarId;
        }
        await _isar.userEntitys.put(entity);
      });
      return updated;
    } catch (error) {
      debugPrint('Online update user failed, queueing: $error');
    }

    await _isar.writeTxn(() async {
      final existing = await _isar.userEntitys
          .filter()
          .userIdEqualTo(user.id)
          .findFirst();
      final entity = _mapUserToEntity(user);
      if (existing != null) {
        entity.isarId = existing.isarId;
      }
      await _isar.userEntitys.put(entity);
    });
    await _queueChange(
      entityType: 'user',
      entityId: user.id,
      action: 'update',
      payload: jsonEncode(user.toSyncPayload()),
    );
    await _attemptImmediateSync('user');
    return user;
  }

  Future<AppUser> createUser(AppUser user) async {
    final payload = user.toCreatePayload();
    try {
      final created = await _apiClient.createUser(payload);
      await _isar.writeTxn(() async {
        await _isar.userEntitys.put(_mapUserToEntity(created));
      });
      return created;
    } catch (error) {
      debugPrint('Online create user failed, queueing: $error');
    }

    await _isar.writeTxn(() async {
      await _isar.userEntitys.put(_mapUserToEntity(user));
    });
    await _queueChange(
      entityType: 'user',
      entityId: user.id,
      action: 'create',
      payload: jsonEncode(user.toSyncPayload()),
    );
    await _attemptImmediateSync('user');
    return user;
  }

  Future<void> deleteUser(String id) async {
    try {
      await _apiClient.deleteUser(id);
      await _isar.writeTxn(() async {
        final existing = await _isar.userEntitys
            .filter()
            .userIdEqualTo(id)
            .findFirst();
        if (existing != null) {
          await _isar.userEntitys.delete(existing.isarId);
        }
      });
      return;
    } catch (error) {
      debugPrint('Online delete user failed, queueing: $error');
    }

    await _isar.writeTxn(() async {
      final existing = await _isar.userEntitys
          .filter()
          .userIdEqualTo(id)
          .findFirst();
      if (existing != null) {
        await _isar.userEntitys.delete(existing.isarId);
      }
    });
    final deletedAt = DateTime.now();
    final payload = await _buildUserDeletePayload(id, deletedAt);
    await _queueChange(
      entityType: 'user',
      entityId: id,
      action: 'delete',
      payload: jsonEncode(payload),
    );
    await _attemptImmediateSync('user');
  }

  Future<AppUser> uploadUserAvatar({
    required String userId,
    required String filePath,
  }) async {
    final updated = await _apiClient.uploadUserAvatar(
      userId: userId,
      filePath: filePath,
    );
    await _isar.writeTxn(() async {
      final existing = await _isar.userEntitys
          .filter()
          .userIdEqualTo(updated.id)
          .findFirst();
      final entity = _mapUserToEntity(updated);
      if (existing != null) {
        entity.isarId = existing.isarId;
      }
      await _isar.userEntitys.put(entity);
    });
    final current = await loadCurrentUser();
    if (current != null && current.id == updated.id) {
      await saveCurrentUser(updated);
    }
    return updated;
  }

  Future<void> upsertSubscriber(Subscriber subscriber) async {
    final pendingCreate = await _isar.pendingChanges
        .filter()
        .entityTypeEqualTo('subscriber')
        .entityIdEqualTo(subscriber.id)
        .actionEqualTo('create')
        .findFirst();
    if (pendingCreate != null) {
      await _isar.writeTxn(() async {
        final existing = await _isar.subscriberEntitys
            .filter()
            .subscriberIdEqualTo(subscriber.id)
            .findFirst();
        final entity = _mapSubscriberToEntity(subscriber);
        if (existing != null) {
          entity.isarId = existing.isarId;
        }
        await _isar.subscriberEntitys.put(entity);
        pendingCreate.payload = jsonEncode(subscriber.toSyncPayload());
        await _isar.pendingChanges.put(pendingCreate);
      });
      return;
    }

    try {
      final updated = await _apiClient.updateSubscriber(subscriber);
      await _isar.writeTxn(() async {
        final existing = await _isar.subscriberEntitys
            .filter()
            .subscriberIdEqualTo(updated.id)
            .findFirst();
        final entity = _mapSubscriberToEntity(updated);
        if (existing != null) {
          entity.isarId = existing.isarId;
        }
        await _isar.subscriberEntitys.put(entity);
      });
      return;
    } catch (error) {
      debugPrint('Online update subscriber failed, queueing: $error');
    }

    await _isar.writeTxn(() async {
      final existing = await _isar.subscriberEntitys
          .filter()
          .subscriberIdEqualTo(subscriber.id)
          .findFirst();
      final entity = _mapSubscriberToEntity(subscriber);
      if (existing != null) {
        entity.isarId = existing.isarId;
      }
      await _isar.subscriberEntitys.put(entity);
    });
    await _queueChange(
      entityType: 'subscriber',
      entityId: subscriber.id,
      action: 'update',
      payload: jsonEncode(subscriber.toSyncPayload()),
    );
    await _attemptImmediateSync('subscriber');
  }

  Future<void> createSubscriber(Subscriber subscriber) async {
    try {
      final created = await _apiClient.createSubscriber(subscriber);
      await _isar.writeTxn(() async {
        await _isar.subscriberEntitys.put(_mapSubscriberToEntity(created));
      });
      return;
    } catch (error) {
      debugPrint('Online create subscriber failed, queueing: $error');
    }

    await _isar.writeTxn(() async {
      await _isar.subscriberEntitys.put(_mapSubscriberToEntity(subscriber));
    });
    await _queueChange(
      entityType: 'subscriber',
      entityId: subscriber.id,
      action: 'create',
      payload: jsonEncode(subscriber.toSyncPayload()),
    );
    await _attemptImmediateSync('subscriber');
  }

  Future<void> deleteSubscriber(String id) async {
    try {
      await _apiClient.deleteSubscriber(id);
      await _isar.writeTxn(() async {
        final existing = await _isar.subscriberEntitys
            .filter()
            .subscriberIdEqualTo(id)
            .findFirst();
        if (existing != null) {
          await _isar.subscriberEntitys.delete(existing.isarId);
        }
      });
      return;
    } catch (error) {
      debugPrint('Online delete subscriber failed, queueing: $error');
    }

    final existing = await _isar.subscriberEntitys
        .filter()
        .subscriberIdEqualTo(id)
        .findFirst();
    final deletedAt = DateTime.now();
    final payload = existing != null
        ? _mapSubscriberEntity(existing).toSyncPayload(deletedAt: deletedAt)
        : <String, dynamic>{
            'id': id,
            'deleted_at': deletedAt.toIso8601String(),
          };
    await _isar.writeTxn(() async {
      if (existing != null) {
        await _isar.subscriberEntitys.delete(existing.isarId);
      }
    });
    await _queueChange(
      entityType: 'subscriber',
      entityId: id,
      action: 'delete',
      payload: jsonEncode(payload),
    );
    await _attemptImmediateSync('subscriber');
  }

  Future<SyncResult> syncUsers({bool force = false}) async {
    return _sync(
      key: 'users',
      entityType: 'user',
      force: force,
      fetchRemote: _apiClient.fetchUsers,
      replaceLocal: _replaceUsers,
    );
  }

  Future<SyncResult> syncSubscribers({bool force = false}) async {
    return _syncSubscribersInternal(force: force, onlyPending: false);
  }

  Future<SyncResult> _sync<T>({
    required String key,
    required String entityType,
    required bool force,
    required Future<List<T>> Function() fetchRemote,
    required Future<void> Function(List<T> items) replaceLocal,
  }) async {
    if (!await _hasConnection()) {
      return const SyncResult(SyncStatus.offline, message: 'Hors connexion');
    }
    if (!force && !await _shouldSync(key, defaultSyncTtl)) {
      return const SyncResult(SyncStatus.skipped, message: 'Cache a jour');
    }

    final pendingResult = await _syncPendingChanges(entityType);
    if (pendingResult == PendingSyncResult.failed) {
      return const SyncResult(
        SyncStatus.partial,
        message: 'Impossible de synchroniser les modifications locales',
      );
    }

    final stillPending = await _pendingCount(entityType);
    if (stillPending > 0) {
      return const SyncResult(
        SyncStatus.partial,
        message: 'Modifications locales en attente',
      );
    }

    final remoteItems = await fetchRemote();
    await replaceLocal(remoteItems);
    await _setLastSync(key, DateTime.now());

    return const SyncResult(SyncStatus.success, message: 'Synchronisation OK');
  }

  Future<void> _replaceUsers(List<AppUser> users) async {
    await _isar.writeTxn(() async {
      await _isar.userEntitys.clear();
      await _isar.userEntitys.putAll(users.map(_mapUserToEntity).toList());
    });
  }

  Future<void> _replaceSubscribers(List<Subscriber> subscribers) async {
    await _isar.writeTxn(() async {
      await _isar.subscriberEntitys.clear();
      await _isar.subscriberEntitys.putAll(
        subscribers.map(_mapSubscriberToEntity).toList(),
      );
    });
  }

  Future<void> _queueChange({
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
  }) async {
    await _isar.writeTxn(() async {
      final change = PendingChange()
        ..entityType = entityType
        ..entityId = entityId
        ..action = action
        ..payload = payload
        ..createdAt = DateTime.now();
      await _isar.pendingChanges.put(change);
    });
  }

  Future<PendingSyncResult> _syncPendingChanges(String entityType) async {
    if (!await _hasConnection()) {
      return PendingSyncResult.failed;
    }

    if (entityType == 'subscriber') {
      return _syncSubscribersPending();
    }
    if (entityType == 'user') {
      final pendingCount = await _pendingCount('user');
      if (pendingCount == 0) {
        return PendingSyncResult.ok;
      }
      return _syncUsersPending();
    }

    final pending = await _isar.pendingChanges
        .filter()
        .entityTypeEqualTo(entityType)
        .sortByCreatedAt()
        .findAll();
    for (final change in pending) {
      try {
        if (entityType == 'user') {
          await _syncUserChange(change);
        } else if (entityType == 'subscriber') {
          await _syncSubscriberChange(change);
        }
        await _isar.writeTxn(() async {
          await _isar.pendingChanges.delete(change.isarId);
        });
      } catch (_) {
        return PendingSyncResult.failed;
      }
    }
    return PendingSyncResult.ok;
  }

  Future<void> _syncUserChange(PendingChange change) async {
    // Replaced by batch sync to /sync.
    await _syncUsersPending();
  }

  Future<void> _syncSubscriberChange(PendingChange change) async {
    // Replaced by batch sync to /sync.
    await _syncSubscribersPending();
  }

  Future<PendingSyncResult> _syncSubscribersPending() async {
    try {
      final result = await _syncSubscribersInternal(
        force: true,
        onlyPending: true,
      );
      return result.status == SyncStatus.success
          ? PendingSyncResult.ok
          : PendingSyncResult.failed;
    } catch (error) {
      debugPrint('Sync abonnes pending error: $error');
      return PendingSyncResult.failed;
    }
  }

  Future<PendingSyncResult> _syncUsersPending() async {
    try {
      final result = await _syncUsersInternal(force: true, onlyPending: true);
      return result.status == SyncStatus.success
          ? PendingSyncResult.ok
          : PendingSyncResult.failed;
    } catch (error) {
      debugPrint('Sync users pending error: $error');
      return PendingSyncResult.failed;
    }
  }

  Future<SyncResult> _syncSubscribersInternal({
    required bool force,
    required bool onlyPending,
  }) async {
    if (!await _hasConnection()) {
      return const SyncResult(SyncStatus.offline, message: 'Hors connexion');
    }

    final pending = await _isar.pendingChanges
        .filter()
        .entityTypeEqualTo('subscriber')
        .sortByCreatedAt()
        .findAll();

    final shouldSync =
        force ||
        pending.isNotEmpty ||
        (!onlyPending && await _shouldSync('subscribers', defaultSyncTtl));
    if (!shouldSync) {
      return const SyncResult(SyncStatus.skipped, message: 'Cache a jour');
    }

    final payloads = pending
        .map((change) {
          final payload = _decodePayload(change.payload);
          if (!payload.containsKey('id') || payload['id'] == null) {
            payload['id'] = change.entityId;
          }
          return payload;
        })
        .where((payload) => payload.isNotEmpty)
        .toList();

    debugPrint(
      'Sync abonnes onlyPending=$onlyPending pending=${pending.length} payloads=${payloads.length}',
    );
    final deviceUuidValue = await deviceUuid();
    List<Subscriber> remoteSubscribers = <Subscriber>[];

    if (onlyPending) {
      remoteSubscribers = await _apiClient.syncSubscribers(
        deviceUuid: deviceUuidValue,
        abonnes: payloads,
        releves: const <Map<String, dynamic>>[],
        facturations: const <Map<String, dynamic>>[],
        parametres: const <Map<String, dynamic>>[],
      );
      if (remoteSubscribers.isNotEmpty) {
        await _replaceSubscribers(remoteSubscribers);
      }
    } else {
      if (payloads.isNotEmpty) {
        await _apiClient.syncSubscribers(
          deviceUuid: deviceUuidValue,
          abonnes: payloads,
          releves: const <Map<String, dynamic>>[],
          facturations: const <Map<String, dynamic>>[],
          parametres: const <Map<String, dynamic>>[],
        );
      }
      remoteSubscribers = await _apiClient.fetchSubscribers();
      await _replaceSubscribers(remoteSubscribers);
    }

    if (pending.isNotEmpty) {
      await _clearPendingChanges(pending);
    }

    if (!onlyPending) {
      await _setLastSync('subscribers', DateTime.now());
    }
    return const SyncResult(SyncStatus.success, message: 'Synchronisation OK');
  }

  Future<SyncResult> _syncUsersInternal({
    required bool force,
    required bool onlyPending,
  }) async {
    if (!await _hasConnection()) {
      return const SyncResult(SyncStatus.offline, message: 'Hors connexion');
    }

    final pending = await _isar.pendingChanges
        .filter()
        .entityTypeEqualTo('user')
        .sortByCreatedAt()
        .findAll();

    final shouldSync =
        force ||
        pending.isNotEmpty ||
        (!onlyPending && await _shouldSync('users', defaultSyncTtl));
    if (!shouldSync) {
      return const SyncResult(SyncStatus.skipped, message: 'Cache a jour');
    }

    final payloads = pending
        .map((change) {
          final payload = _normalizeUserSyncPayload(
            _decodePayload(change.payload),
          );
          if (!payload.containsKey('id') || payload['id'] == null) {
            payload['id'] = change.entityId;
          }
          return payload;
        })
        .where((payload) => payload.isNotEmpty)
        .toList();

    debugPrint(
      'Sync users onlyPending=$onlyPending pending=${pending.length} payloads=${payloads.length}',
    );
    final deviceUuidValue = await deviceUuid();
    final remoteUsers = await _apiClient.syncUsers(
      deviceUuid: deviceUuidValue,
      users: payloads,
      abonnes: const <Map<String, dynamic>>[],
      releves: const <Map<String, dynamic>>[],
      facturations: const <Map<String, dynamic>>[],
      parametres: const <Map<String, dynamic>>[],
    );

    if (onlyPending) {
      if (remoteUsers.isNotEmpty) {
        await _replaceUsers(remoteUsers);
      }
    } else {
      await _replaceUsers(remoteUsers);
    }

    if (pending.isNotEmpty) {
      await _clearPendingChanges(pending);
    }

    if (!onlyPending) {
      await _setLastSync('users', DateTime.now());
    }
    return const SyncResult(SyncStatus.success, message: 'Synchronisation OK');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  Map<String, dynamic> _normalizeUserSyncPayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return payload;
    final normalized = Map<String, dynamic>.from(payload);
    normalized.remove('password');
    normalized.remove('password_confirmation');
    if (!normalized.containsKey('name')) {
      final fallback =
          normalized['full_name'] ??
          normalized['fullname'] ??
          normalized['nom'];
      if (fallback != null) {
        normalized['name'] = fallback.toString();
      }
    }
    if (!normalized.containsKey('email')) {
      final fallback = normalized['mail'];
      if (fallback != null) {
        normalized['email'] = fallback.toString();
      }
    }
    if (!normalized.containsKey('est_actif')) {
      final fallback = normalized['active'];
      if (fallback != null) {
        normalized['est_actif'] = fallback;
      }
    }
    final roleValue = normalized['role']?.toString().toLowerCase();
    if (roleValue == null ||
        (roleValue != 'utilisateur' &&
            roleValue != 'admin' &&
            roleValue != 'visiteur')) {
      normalized['role'] = 'utilisateur';
    } else {
      normalized['role'] = roleValue;
    }
    return normalized;
  }

  Future<Map<String, dynamic>> _buildUserDeletePayload(
    String id,
    DateTime deletedAt,
  ) async {
    final existing = await _isar.userEntitys
        .filter()
        .userIdEqualTo(id)
        .findFirst();
    if (existing != null) {
      final user = _mapUserEntity(existing);
      return user.toSyncPayload(deletedAt: deletedAt);
    }
    return <String, dynamic>{
      'id': id,
      'deleted_at': deletedAt.toIso8601String(),
    };
  }

  Future<bool> _shouldSync(String key, Duration ttl) async {
    final meta = await _isar.syncMetas.filter().keyEqualTo(key).findFirst();
    if (meta == null) return true;
    final lastSync = DateTime.fromMillisecondsSinceEpoch(meta.value);
    return DateTime.now().difference(lastSync) > ttl;
  }

  Future<void> _setLastSync(String key, DateTime value) async {
    await _isar.writeTxn(() async {
      final meta = SyncMeta()
        ..key = key
        ..value = value.millisecondsSinceEpoch;
      await _isar.syncMetas.put(meta);
    });
  }

  Future<int> _pendingCount(String entityType) async {
    return _isar.pendingChanges.filter().entityTypeEqualTo(entityType).count();
  }

  Future<void> _clearPendingChanges(List<PendingChange> changes) async {
    await _isar.writeTxn(() async {
      for (final change in changes) {
        await _isar.pendingChanges.delete(change.isarId);
      }
    });
  }

  Future<void> _attemptImmediateSync(String entityType) async {
    if (!await _hasConnection()) return;
    try {
      await _syncPendingChanges(entityType);
    } catch (error) {
      debugPrint('Immediate sync error ($entityType): $error');
    }
  }

  Future<bool> _hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  UserEntity _mapUserToEntity(AppUser user) {
    return UserEntity()
      ..userId = user.id
      ..fullName = user.fullName
      ..email = user.email
      ..phone = user.phone
      ..role = user.role
      ..active = user.active
      ..createdAt = user.createdAt
      ..avatarUrl = user.avatarUrl.isEmpty ? null : user.avatarUrl
      ..avatarThumbUrl = user.avatarThumbUrl.isEmpty
          ? null
          : user.avatarThumbUrl;
  }

  SubscriberEntity _mapSubscriberToEntity(Subscriber subscriber) {
    return SubscriberEntity()
      ..subscriberId = subscriber.id
      ..fullName = subscriber.fullName
      ..email = subscriber.email
      ..phone = subscriber.phone
      ..location = subscriber.location
      ..plan = subscriber.plan
      ..active = subscriber.active
      ..startDate = subscriber.startDate
      ..monthlyFee = subscriber.monthlyFee;
  }

  AppUser _mapUserEntity(UserEntity entity) {
    return AppUser(
      id: entity.userId,
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      role: entity.role,
      active: entity.active,
      createdAt: entity.createdAt,
      avatarUrl: entity.avatarUrl ?? '',
      avatarThumbUrl: entity.avatarThumbUrl ?? '',
    );
  }

  CurrentUserEntity _mapCurrentUserToEntity(AppUser user) {
    return CurrentUserEntity()
      ..key = 'current'
      ..userId = user.id
      ..fullName = user.fullName
      ..email = user.email
      ..phone = user.phone
      ..role = user.role
      ..active = user.active
      ..createdAt = user.createdAt
      ..avatarUrl = user.avatarUrl.isEmpty ? null : user.avatarUrl
      ..avatarThumbUrl = user.avatarThumbUrl.isEmpty
          ? null
          : user.avatarThumbUrl;
  }

  AppUser _mapCurrentUserEntity(CurrentUserEntity entity) {
    return AppUser(
      id: entity.userId,
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      role: entity.role,
      active: entity.active,
      createdAt: entity.createdAt,
      avatarUrl: entity.avatarUrl ?? '',
      avatarThumbUrl: entity.avatarThumbUrl ?? '',
    );
  }

  Subscriber _mapSubscriberEntity(SubscriberEntity entity) {
    return Subscriber(
      id: entity.subscriberId,
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      location: entity.location,
      plan: entity.plan,
      active: entity.active,
      startDate: entity.startDate,
      monthlyFee: entity.monthlyFee,
    );
  }

  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}

enum SyncStatus { success, offline, skipped, partial }

enum PendingSyncResult { ok, failed }

class SyncResult {
  const SyncResult(this.status, {this.message});

  final SyncStatus status;
  final String? message;
}
