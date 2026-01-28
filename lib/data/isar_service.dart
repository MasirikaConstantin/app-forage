import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar_models.dart';

class IsarService {
  IsarService._();

  static final IsarService instance = IsarService._();

  Isar? _isar;
  bool _opened = false;

  Isar get isar => _isar!;

  Future<void> init() async {
    if (_opened && _isar != null) return;
    await _open();
    _opened = true;
  }

  Future<void> reopen() async {
    if (Isar.instanceNames.isNotEmpty) {
      final instance = Isar.getInstance();
      if (instance != null && instance.isOpen) {
        await instance.close();
      }
    }
    _opened = false;
    await _open();
    _opened = true;
  }

  Future<void> _open() async {
    if (Isar.instanceNames.isNotEmpty) {
      final existing = Isar.getInstance();
      if (existing != null) {
        _isar = existing;
        return;
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      <CollectionSchema>[
        UserEntitySchema,
        SubscriberEntitySchema,
        PendingChangeSchema,
        SyncMetaSchema,
        AuthTokenSchema,
        DeviceInfoSchema,
        CurrentUserEntitySchema,
      ],
      directory: dir.path,
    );
  }
}
