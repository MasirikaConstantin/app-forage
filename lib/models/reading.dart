class Reading {
  const Reading({
    required this.id,
    required this.subscriberId,
    required this.createdBy,
    required this.date,
    required this.indexValue,
    required this.createdAt,
    required this.updatedAt,
    this.cumulativeIndex,
    this.facturationCount,
    this.subscriberName,
    this.subscriberEmail,
    this.createdByName,
    this.createdByEmail,
    this.createdByAvatarUrl,
    this.facturationPeriod,
    this.facturationAmount,
    this.pricePerM3,
    this.consumptionM3,
    this.isPaid,
    this.facturation,
  });

  final String id;
  final String subscriberId;
  final String createdBy;
  final DateTime date;
  final double indexValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? cumulativeIndex;
  final int? facturationCount;
  final String? subscriberName;
  final String? subscriberEmail;
  final String? createdByName;
  final String? createdByEmail;
  final String? createdByAvatarUrl;
  final String? facturationPeriod;
  final double? facturationAmount;
  final double? pricePerM3;
  final double? consumptionM3;
  final bool? isPaid;
  final Facturation? facturation;

  static Reading fromApi(Map<String, dynamic> json) {
    final id = _stringFromKeys(json, <String>['id']) ?? '';
    final subscriberId =
        _stringFromKeys(json, <String>['abonne_id', 'subscriber_id']) ?? '';
    final createdById = _stringFromKeys(json, <String>['created_by']) ?? '';
    final date =
        _dateFromKeys(json, <String>['date_releve', 'date']) ?? DateTime.now();
    final indexValue =
        _doubleFromKeys(json, <String>['index', 'index_value']) ?? 0;
    final createdAt =
        _dateFromKeys(json, <String>['created_at']) ?? DateTime.now();
    final updatedAt =
        _dateFromKeys(json, <String>['updated_at']) ?? DateTime.now();
    final cumulativeIndex =
        _doubleFromKeys(json, <String>['cumul_index']) ?? null;

    final facturationRaw = json['facturation'];
    final facturation = facturationRaw is Map<String, dynamic>
        ? Facturation.fromApi(facturationRaw)
        : null;

    final facturationPeriod = facturation?.period;
    final facturationAmount = facturation?.totalAmount;
    final pricePerM3 = facturation?.pricePerM3;
    final consumptionM3 = facturation?.consumptionM3;
    final isPaid = facturation?.isPaid;

    final abonneRaw = json['abonne'];
    final abonne = abonneRaw is Map
        ? Map<String, dynamic>.from(abonneRaw)
        : null;
    final subscriberName = abonne == null
        ? null
        : _composeName(
            _stringFromKeys(abonne, <String>['nom']),
            _stringFromKeys(abonne, <String>['prenom']),
            _stringFromKeys(abonne, <String>['name']) ?? '',
          );
    final subscriberEmail = abonne == null
        ? null
        : _stringFromKeys(abonne, <String>['email']);

    final createdByRaw = json['createdBy'];
    final createdBy = createdByRaw is Map
        ? Map<String, dynamic>.from(createdByRaw)
        : null;
    final createdByName = createdBy == null
        ? null
        : _stringFromKeys(createdBy, <String>['name']) ?? '';
    final createdByEmail = createdBy == null
        ? null
        : _stringFromKeys(createdBy, <String>['email']) ?? '';
    final createdByAvatarUrl = createdBy == null
        ? null
        : _stringFromKeys(createdBy, <String>['avatar_url', 'avatar']);

    return Reading(
      id: id,
      subscriberId: subscriberId,
      createdBy: createdById,
      date: date,
      indexValue: indexValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cumulativeIndex: cumulativeIndex,
      subscriberName: subscriberName,
      subscriberEmail: subscriberEmail,
      createdByName: createdByName,
      createdByEmail: createdByEmail,
      createdByAvatarUrl: createdByAvatarUrl,
      facturationPeriod: facturationPeriod,
      facturationAmount: facturationAmount,
      pricePerM3: pricePerM3,
      consumptionM3: consumptionM3,
      isPaid: isPaid,
      facturation: facturation,
    );
  }

  Reading copyWith({
    String? id,
    String? subscriberId,
    String? createdBy,
    DateTime? date,
    double? indexValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? cumulativeIndex,
    int? facturationCount,
    String? subscriberName,
    String? subscriberEmail,
    String? createdByName,
    String? createdByEmail,
    String? createdByAvatarUrl,
    String? facturationPeriod,
    double? facturationAmount,
    double? pricePerM3,
    double? consumptionM3,
    bool? isPaid,
    Facturation? facturation,
  }) {
    return Reading(
      id: id ?? this.id,
      subscriberId: subscriberId ?? this.subscriberId,
      createdBy: createdBy ?? this.createdBy,
      date: date ?? this.date,
      indexValue: indexValue ?? this.indexValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cumulativeIndex: cumulativeIndex ?? this.cumulativeIndex,
      facturationCount: facturationCount ?? this.facturationCount,
      subscriberName: subscriberName ?? this.subscriberName,
      subscriberEmail: subscriberEmail ?? this.subscriberEmail,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdByAvatarUrl: createdByAvatarUrl ?? this.createdByAvatarUrl,
      facturationPeriod: facturationPeriod ?? this.facturationPeriod,
      facturationAmount: facturationAmount ?? this.facturationAmount,
      pricePerM3: pricePerM3 ?? this.pricePerM3,
      consumptionM3: consumptionM3 ?? this.consumptionM3,
      isPaid: isPaid ?? this.isPaid,
      facturation: facturation ?? this.facturation,
    );
  }

  static String? _stringFromKeys(Map<String, dynamic> json, List<String> keys) {
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

  static DateTime? _dateFromKeys(Map<String, dynamic> json, List<String> keys) {
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

  static double? _doubleFromKeys(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
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

  static String _composeName(String? nom, String? prenom, String fallback) {
    final nameParts = <String>[];
    if (nom != null && nom.isNotEmpty) nameParts.add(nom);
    if (prenom != null && prenom.isNotEmpty) nameParts.add(prenom);
    if (nameParts.isEmpty) return fallback;
    return nameParts.join(' ');
  }
}

class Facturation {
  const Facturation({
    required this.id,
    required this.period,
    required this.currency,
    required this.totalAmount,
    required this.pricePerM3,
    required this.consumptionM3,
    required this.isPaid,
    required this.createdAt,
    this.isActive,
  });

  final String id;
  final String period;
  final String currency;
  final double totalAmount;
  final double pricePerM3;
  final double consumptionM3;
  final bool isPaid;
  final DateTime createdAt;
  final bool? isActive;

  Facturation copyWith({
    String? id,
    String? period,
    String? currency,
    double? totalAmount,
    double? pricePerM3,
    double? consumptionM3,
    bool? isPaid,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Facturation(
      id: id ?? this.id,
      period: period ?? this.period,
      currency: currency ?? this.currency,
      totalAmount: totalAmount ?? this.totalAmount,
      pricePerM3: pricePerM3 ?? this.pricePerM3,
      consumptionM3: consumptionM3 ?? this.consumptionM3,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  static Facturation fromApi(Map<String, dynamic> json) {
    final id = Reading._stringFromKeys(json, <String>['id']) ?? '';
    final period = Reading._stringFromKeys(json, <String>['periode']) ?? '';
    final currency = Reading._stringFromKeys(json, <String>['devise']) ?? 'CDF';
    final totalAmount =
        Reading._doubleFromKeys(json, <String>['montant_total']) ?? 0;
    final pricePerM3 = Reading._doubleFromKeys(json, <String>['prix_m3']) ?? 0;
    final consumptionM3 =
        Reading._doubleFromKeys(json, <String>['consommation_m3']) ?? 0;
    final isPaid = Reading._boolFromKeys(json, <String>['est_paye']) ?? false;
    final isActive = Reading._boolFromKeys(json, <String>['est_actif']);
    final createdAt =
        Reading._dateFromKeys(json, <String>['created_at']) ?? DateTime.now();

    return Facturation(
      id: id,
      period: period,
      currency: currency,
      totalAmount: totalAmount,
      pricePerM3: pricePerM3,
      consumptionM3: consumptionM3,
      isPaid: isPaid,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
