class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.active,
    required this.createdAt,
    this.avatarUrl = '',
    this.avatarThumbUrl = '',
    this.password,
    this.passwordConfirmation,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool active;
  final DateTime createdAt;
  final String avatarUrl;
  final String avatarThumbUrl;
  final String? password;
  final String? passwordConfirmation;

  Map<String, dynamic> toCreatePayload() {
    final confirmation =
        (passwordConfirmation != null && passwordConfirmation!.isNotEmpty)
            ? passwordConfirmation
            : password;
    return <String, dynamic>{
      'name': fullName,
      'email': email,
      'telephone': phone,
      'phone': phone,
      'password': password ?? '',
      'password_confirmation': confirmation ?? '',
      'role': _normalizeRole(role),
      'est_actif': active,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    final payload = <String, dynamic>{
      'name': fullName,
      'email': email,
      'telephone': phone,
      'phone': phone,
      'role': _normalizeRole(role),
      'est_actif': active,
    };
    final pwd = password ?? '';
    if (pwd.isNotEmpty) {
      final confirmation =
          (passwordConfirmation != null && passwordConfirmation!.isNotEmpty)
              ? passwordConfirmation
              : password;
      payload['password'] = pwd;
      payload['password_confirmation'] = confirmation ?? '';
    }
    return payload;
  }

  Map<String, dynamic> toSyncPayload({DateTime? deletedAt}) {
    return <String, dynamic>{
      'id': id,
      'name': fullName,
      'email': email,
      'email_verified_at': null,
      'role': _normalizeRole(role),
      'est_actif': active,
      'pin': null,
      'created_by': null,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    bool? active,
    DateTime? createdAt,
    String? avatarUrl,
    String? avatarThumbUrl,
    String? password,
    String? passwordConfirmation,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarThumbUrl: avatarThumbUrl ?? this.avatarThumbUrl,
      password: password ?? this.password,
      passwordConfirmation: passwordConfirmation ?? this.passwordConfirmation,
    );
  }

  AppUser withoutSecrets() {
    return AppUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      active: active,
      createdAt: createdAt,
      avatarUrl: avatarUrl,
      avatarThumbUrl: avatarThumbUrl,
      password: null,
      passwordConfirmation: null,
    );
  }

  static String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == 'utilisateur' ||
        normalized == 'admin' ||
        normalized == 'visiteur') {
      return normalized;
    }
    return 'utilisateur';
  }

  static AppUser fromApi(Map<String, dynamic> json) {
    final id = _stringFromKeys(json, <String>['id', 'user_id', 'uuid']) ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final fullName = _stringFromKeys(json, <String>[
          'full_name',
          'fullname',
          'name',
          'nom',
        ]) ??
        'Sans nom';
    final email = _stringFromKeys(json, <String>['email', 'mail']) ?? '';
    final phone = _stringFromKeys(json, <String>['phone', 'telephone']) ?? '';
    final role = _stringFromKeys(json, <String>['role', 'profil']) ?? 'Agent';
    final active =
        _boolFromKeys(json, <String>['active', 'is_active', 'est_actif']) ??
            true;
    final avatarUrl =
        _stringFromKeys(json, <String>['avatar_url']) ?? '';
    final avatarThumbUrl = _stringFromKeys(
          json,
          <String>['avatar'],
        ) ??
        '';
    final createdAt = _dateFromKeys(json, <String>['created_at', 'createdAt']) ??
        DateTime.now();

    return AppUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      active: active,
      createdAt: createdAt,
      avatarUrl: avatarUrl,
      avatarThumbUrl: avatarThumbUrl,
    );
  }

  static String? _stringFromKeys(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  static bool? _boolFromKeys(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        if (value == '1' || value.toLowerCase() == 'true') return true;
        if (value == '0' || value.toLowerCase() == 'false') return false;
      }
      if (value is num) return value != 0;
    }
    return null;
  }

  static DateTime? _dateFromKeys(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    }
    return null;
  }
}
