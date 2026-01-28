class Subscriber {
  const Subscriber({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.plan,
    required this.active,
    required this.startDate,
    required this.monthlyFee,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String plan;
  final bool active;
  final DateTime startDate;
  final double monthlyFee;

  Map<String, dynamic> toApiPayload() {
    final nameParts = _splitName(fullName);
    final payload = <String, dynamic>{
      'id': id,
      'nom': nameParts.$1,
      'date_naissance': startDate.toIso8601String().split('T').first,
      'est_actif': active,
    };
    if (nameParts.$2.isNotEmpty) {
      payload['prenom'] = nameParts.$2;
    }
    if (email.trim().isNotEmpty) {
      payload['email'] = email.trim();
    }
    if (phone.trim().isNotEmpty) {
      payload['telephone'] = phone.trim();
    }
    if (location.trim().isNotEmpty) {
      payload['adresse'] = location.trim();
    }
    if (plan.trim().isNotEmpty) {
      payload['profession'] = plan.trim();
    }
    return payload;
  }

  Map<String, dynamic> toSyncPayload({DateTime? deletedAt}) {
    final nameParts = _splitName(fullName);
    final payload = <String, dynamic>{
      'id': id,
      'nom': nameParts.$1,
      'date_naissance': startDate.toIso8601String().split('T').first,
      'est_actif': active,
      'created_by': null,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': startDate.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (nameParts.$2.isNotEmpty) {
      payload['prenom'] = nameParts.$2;
    }
    if (email.trim().isNotEmpty) {
      payload['email'] = email.trim();
    }
    if (phone.trim().isNotEmpty) {
      payload['telephone'] = phone.trim();
    }
    if (location.trim().isNotEmpty) {
      payload['adresse'] = location.trim();
    }
    if (plan.trim().isNotEmpty) {
      payload['profession'] = plan.trim();
    }
    return payload;
  }

  Subscriber copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? plan,
    bool? active,
    DateTime? startDate,
    double? monthlyFee,
  }) {
    return Subscriber(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      plan: plan ?? this.plan,
      active: active ?? this.active,
      startDate: startDate ?? this.startDate,
      monthlyFee: monthlyFee ?? this.monthlyFee,
    );
  }

  static Subscriber fromApi(Map<String, dynamic> json) {
    final id = _stringFromKeys(json, <String>['id', 'subscriber_id', 'uuid']) ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final nom = _stringFromKeys(json, <String>['nom', 'last_name']);
    final prenom = _stringFromKeys(json, <String>['prenom', 'first_name']);
    final fallbackName = _stringFromKeys(json, <String>[
          'full_name',
          'fullname',
          'name',
        ]) ??
        'Sans nom';
    final fullName = _composeName(nom, prenom, fallbackName);
    final email = _stringFromKeys(json, <String>['email', 'mail']) ?? '';
    final phone =
        _stringFromKeys(json, <String>['phone', 'telephone']) ?? '';
    final location = _stringFromKeys(
          json,
          <String>['location', 'adresse', 'zone', 'quartier'],
        ) ??
        '';
    final plan = _stringFromKeys(json, <String>['plan', 'forfait']) ?? 'Standard';
    final active =
        _boolFromKeys(json, <String>['active', 'is_active', 'est_actif']) ??
            true;
    final startDate = _dateFromKeys(
          json,
          <String>['created_at', 'updated_at', 'date_naissance', 'start_date'],
        ) ??
        DateTime.now();
    final monthlyFee =
        _doubleFromKeys(json, <String>['monthly_fee', 'fee', 'amount']) ?? 0;

    return Subscriber(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      location: location,
      plan: plan,
      active: active,
      startDate: startDate,
      monthlyFee: monthlyFee,
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

  static double? _doubleFromKeys(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  static (String, String) _splitName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return ('', '');
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  static String _composeName(
    String? nom,
    String? prenom,
    String fallback,
  ) {
    final nameParts = <String>[];
    if (nom != null && nom.isNotEmpty) nameParts.add(nom);
    if (prenom != null && prenom.isNotEmpty) nameParts.add(prenom);
    if (nameParts.isEmpty) return fallback;
    return nameParts.join(' ');
  }
}
