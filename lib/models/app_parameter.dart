class AppParameter {
  const AppParameter({
    required this.id,
    required this.keyName,
    required this.value,
    required this.description,
    required this.active,
  });

  final String id;
  final String keyName;
  final String value;
  final String description;
  final bool active;

  Map<String, dynamic> toCreatePayload() {
    return <String, dynamic>{
      'cle': keyName,
      'valeur': value,
      'description': description,
      'est_actif': active,
    };
  }

  AppParameter copyWith({
    String? id,
    String? keyName,
    String? value,
    String? description,
    bool? active,
  }) {
    return AppParameter(
      id: id ?? this.id,
      keyName: keyName ?? this.keyName,
      value: value ?? this.value,
      description: description ?? this.description,
      active: active ?? this.active,
    );
  }

  static AppParameter fromApi(Map<String, dynamic> json) {
    final id = _stringFromKeys(json, <String>['id']) ?? '';
    final keyName = _stringFromKeys(json, <String>['cle', 'key']) ?? '';
    final value = _stringFromKeys(json, <String>['valeur', 'value']) ?? '';
    final description =
        _stringFromKeys(json, <String>['description']) ?? '';
    final active =
        _boolFromKeys(json, <String>['est_actif', 'active']) ?? true;

    return AppParameter(
      id: id,
      keyName: keyName,
      value: value,
      description: description,
      active: active,
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
}
