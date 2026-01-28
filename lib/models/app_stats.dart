class AppStats {
  const AppStats({
    required this.users,
    required this.abonnes,
    required this.releves,
    required this.facturations,
    required this.parametres,
    required this.syncLogs,
    required this.userDevices,
    required this.userLogs,
    required this.tokens,
    required this.media,
    this.generatedAt,
  });

  final StatsUsers users;
  final StatsAbonnes abonnes;
  final StatsReleves releves;
  final StatsFacturations facturations;
  final StatsParametres parametres;
  final StatsSyncLogs syncLogs;
  final StatsUserDevices userDevices;
  final StatsUserLogs userLogs;
  final StatsTokens tokens;
  final StatsMedia media;
  final String? generatedAt;

  static AppStats fromApi(Map<String, dynamic> json) {
    final data = _mapFrom(json['data']);
    return AppStats(
      users: StatsUsers.fromApi(_mapFrom(data['users'])),
      abonnes: StatsAbonnes.fromApi(_mapFrom(data['abonnes'])),
      releves: StatsReleves.fromApi(_mapFrom(data['releves'])),
      facturations: StatsFacturations.fromApi(_mapFrom(data['facturations'])),
      parametres: StatsParametres.fromApi(_mapFrom(data['parametres'])),
      syncLogs: StatsSyncLogs.fromApi(_mapFrom(data['sync_logs'])),
      userDevices: StatsUserDevices.fromApi(_mapFrom(data['user_devices'])),
      userLogs: StatsUserLogs.fromApi(_mapFrom(data['user_logs'])),
      tokens: StatsTokens.fromApi(_mapFrom(data['tokens'])),
      media: StatsMedia.fromApi(_mapFrom(data['media'])),
      generatedAt: _stringFrom(data, 'generated_at'),
    );
  }

  static Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static String? _stringFrom(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String) return value;
    return value?.toString();
  }

  static int _intFrom(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _doubleFrom(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static Map<String, int> _intMapFrom(dynamic value) {
    if (value is! Map) return <String, int>{};
    final map = <String, int>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is int) {
        map[key] = val;
      } else if (val is num) {
        map[key] = val.toInt();
      } else if (val is String) {
        map[key] = int.tryParse(val) ?? 0;
      }
    }
    return map;
  }
}

class StatsUsers {
  const StatsUsers({
    required this.total,
    required this.totalWithDeleted,
    required this.active,
    required this.inactive,
    required this.withPhone,
    required this.withAvatar,
    required this.byRole,
  });

  final int total;
  final int totalWithDeleted;
  final int active;
  final int inactive;
  final int withPhone;
  final int withAvatar;
  final Map<String, int> byRole;

  static StatsUsers fromApi(Map<String, dynamic> data) {
    return StatsUsers(
      total: AppStats._intFrom(data, 'total'),
      totalWithDeleted: AppStats._intFrom(data, 'total_with_deleted'),
      active: AppStats._intFrom(data, 'active'),
      inactive: AppStats._intFrom(data, 'inactive'),
      withPhone: AppStats._intFrom(data, 'with_phone'),
      withAvatar: AppStats._intFrom(data, 'with_avatar'),
      byRole: AppStats._intMapFrom(data['by_role']),
    );
  }
}

class StatsAbonnes {
  const StatsAbonnes({
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

  static StatsAbonnes fromApi(Map<String, dynamic> data) {
    return StatsAbonnes(
      total: AppStats._intFrom(data, 'total'),
      active: AppStats._intFrom(data, 'active'),
      inactive: AppStats._intFrom(data, 'inactive'),
    );
  }
}

class StatsReleves {
  const StatsReleves({
    required this.total,
    required this.sumIndex,
    required this.maxCumulIndex,
    required this.lastDate,
  });

  final int total;
  final double sumIndex;
  final double maxCumulIndex;
  final String lastDate;

  static StatsReleves fromApi(Map<String, dynamic> data) {
    return StatsReleves(
      total: AppStats._intFrom(data, 'total'),
      sumIndex: AppStats._doubleFrom(data, 'sum_index'),
      maxCumulIndex: AppStats._doubleFrom(data, 'max_cumul_index'),
      lastDate: AppStats._stringFrom(data, 'last_date') ?? '-',
    );
  }
}

class StatsFacturations {
  const StatsFacturations({
    required this.total,
    required this.payees,
    required this.impayees,
    required this.montantTotal,
    required this.montantImpayes,
    required this.consommationTotalM3,
    required this.lastPeriode,
  });

  final int total;
  final int payees;
  final int impayees;
  final double montantTotal;
  final double montantImpayes;
  final double consommationTotalM3;
  final String lastPeriode;

  static StatsFacturations fromApi(Map<String, dynamic> data) {
    return StatsFacturations(
      total: AppStats._intFrom(data, 'total'),
      payees: AppStats._intFrom(data, 'payees'),
      impayees: AppStats._intFrom(data, 'impayees'),
      montantTotal: AppStats._doubleFrom(data, 'montant_total'),
      montantImpayes: AppStats._doubleFrom(data, 'montant_impayes'),
      consommationTotalM3: AppStats._doubleFrom(data, 'consommation_total_m3'),
      lastPeriode: AppStats._stringFrom(data, 'last_periode') ?? '-',
    );
  }
}

class StatsParametres {
  const StatsParametres({
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

  static StatsParametres fromApi(Map<String, dynamic> data) {
    return StatsParametres(
      total: AppStats._intFrom(data, 'total'),
      active: AppStats._intFrom(data, 'active'),
      inactive: AppStats._intFrom(data, 'inactive'),
    );
  }
}

class StatsSyncLogs {
  const StatsSyncLogs({
    required this.total,
    required this.lastSyncAt,
    required this.distinctDevices,
  });

  final int total;
  final String lastSyncAt;
  final int distinctDevices;

  static StatsSyncLogs fromApi(Map<String, dynamic> data) {
    return StatsSyncLogs(
      total: AppStats._intFrom(data, 'total'),
      lastSyncAt: AppStats._stringFrom(data, 'last_sync_at') ?? '-',
      distinctDevices: AppStats._intFrom(data, 'distinct_devices'),
    );
  }
}

class StatsUserDevices {
  const StatsUserDevices({
    required this.total,
    required this.distinctUsers,
    required this.lastUsedAt,
  });

  final int total;
  final int distinctUsers;
  final String lastUsedAt;

  static StatsUserDevices fromApi(Map<String, dynamic> data) {
    return StatsUserDevices(
      total: AppStats._intFrom(data, 'total'),
      distinctUsers: AppStats._intFrom(data, 'distinct_users'),
      lastUsedAt: AppStats._stringFrom(data, 'last_used_at') ?? '-',
    );
  }
}

class StatsUserLogs {
  const StatsUserLogs({
    required this.total,
    required this.last7Days,
    required this.byAction,
  });

  final int total;
  final int last7Days;
  final Map<String, int> byAction;

  static StatsUserLogs fromApi(Map<String, dynamic> data) {
    return StatsUserLogs(
      total: AppStats._intFrom(data, 'total'),
      last7Days: AppStats._intFrom(data, 'last_7_days'),
      byAction: AppStats._intMapFrom(data['by_action']),
    );
  }
}

class StatsTokens {
  const StatsTokens({
    required this.total,
    required this.lastUsedAt,
    required this.withExpiry,
  });

  final int total;
  final String lastUsedAt;
  final int withExpiry;

  static StatsTokens fromApi(Map<String, dynamic> data) {
    return StatsTokens(
      total: AppStats._intFrom(data, 'total'),
      lastUsedAt: AppStats._stringFrom(data, 'last_used_at') ?? '-',
      withExpiry: AppStats._intFrom(data, 'with_expiry'),
    );
  }
}

class StatsMedia {
  const StatsMedia({
    required this.total,
    required this.totalSize,
  });

  final int total;
  final double totalSize;

  static StatsMedia fromApi(Map<String, dynamic> data) {
    return StatsMedia(
      total: AppStats._intFrom(data, 'total'),
      totalSize: AppStats._doubleFrom(data, 'total_size'),
    );
  }
}
