import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class UserEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;
  late String fullName;
  late String email;
  late String phone;
  late String role;
  late bool active;
  late DateTime createdAt;
  String? avatarUrl;
  String? avatarThumbUrl;
}

@collection
class SubscriberEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String subscriberId;
  late String fullName;
  late String email;
  late String phone;
  late String location;
  late String plan;
  late bool active;
  late DateTime startDate;
  late double monthlyFee;
}

@collection
class PendingChange {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String entityType;
  late String entityId;
  late String action;
  late String payload;
  late DateTime createdAt;
}

@collection
class SyncMeta {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;
  late int value;
}

@collection
class AuthToken {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;
  late String token;
  late String tokenType;
  late DateTime createdAt;
}

@collection
class DeviceInfo {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;
  late String value;
  late DateTime createdAt;
}

@collection
class CurrentUserEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;
  late String userId;
  late String fullName;
  late String email;
  late String phone;
  late String role;
  late bool active;
  late DateTime createdAt;
  String? avatarUrl;
  String? avatarThumbUrl;
}
