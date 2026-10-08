import 'dart:convert';
import 'dart:typed_data';

import 'app_database.dart';

class InventoryBackupPreview {
  const InventoryBackupPreview({
    required this.equipmentCount,
    required this.createdAt,
  });

  final int equipmentCount;
  final DateTime? createdAt;
}

class _ValidatedBackup {
  const _ValidatedBackup({
    required this.equipment,
    required this.createdAt,
  });

  final List<Map<String, Object?>> equipment;
  final DateTime? createdAt;
}

class InventoryBackupService {
  const InventoryBackupService(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Uint8List> createBackup() async {
    final equipment = await _appDatabase.database.query(
      'equipment',
      orderBy: 'name COLLATE NOCASE',
    );
    final backup = {
      'format': 'kito-backup',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'equipment': equipment,
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)),
    );
  }

  InventoryBackupPreview previewBackup(Uint8List bytes) {
    final backup = _decodeAndValidateBackup(bytes);
    return InventoryBackupPreview(
      equipmentCount: backup.equipment.length,
      createdAt: backup.createdAt,
    );
  }

  Future<int> restoreBackup(Uint8List bytes) async {
    final backup = _decodeAndValidateBackup(bytes);

    await _appDatabase.database.transaction((transaction) async {
      await transaction.delete('equipment');
      for (final row in backup.equipment) {
        await transaction.insert('equipment', row);
      }
    });
    return backup.equipment.length;
  }

  _ValidatedBackup _decodeAndValidateBackup(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'kito-backup' ||
        decoded['version'] != 1 ||
        decoded['equipment'] is! List) {
      throw const FormatException('Ce fichier n’est pas une sauvegarde Kito valide.');
    }

    final equipment = _validateRows(
      decoded['equipment']! as List,
      const {
        'id',
        'name',
        'category',
        'new_quantity',
        'good_quantity',
        'repair_quantity',
        'unusable_quantity',
        'low_stock_threshold',
        'is_consumable',
        'notes',
      },
    );
    final createdAtValue = decoded['createdAt'];
    final createdAt = createdAtValue == null
        ? null
        : createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;
    if (equipment.any((row) => !_isValidEquipmentRow(row)) ||
        _hasDuplicateIds(equipment) ||
        (createdAtValue != null && createdAt == null)) {
      throw const FormatException('La sauvegarde contient des données invalides.');
    }

    return _ValidatedBackup(
      equipment: equipment,
      createdAt: createdAt,
    );
  }

  bool _hasDuplicateIds(List<Map<String, Object?>> rows) {
    final ids = rows.map((row) => row['id']).toSet();
    return ids.length != rows.length;
  }

  List<Map<String, Object?>> _validateRows(
    List<dynamic> values,
    Set<String> requiredColumns,
  ) {
    return values.map((value) {
      if (value is! Map<String, dynamic> ||
          !value.keys.toSet().containsAll(requiredColumns)) {
        throw const FormatException('La sauvegarde contient une ligne invalide.');
      }
      return {
        for (final key in requiredColumns) key: value[key] as Object?,
      };
    }).toList();
  }

  bool _isValidEquipmentRow(Map<String, Object?> row) =>
      row['id'] is String &&
      (row['id']! as String).isNotEmpty &&
      row['name'] is String &&
      (row['name']! as String).trim().isNotEmpty &&
      row['category'] is String &&
      _isNonNegativeInt(row['new_quantity']) &&
      _isNonNegativeInt(row['good_quantity']) &&
      _isNonNegativeInt(row['repair_quantity']) &&
      _isNonNegativeInt(row['unusable_quantity']) &&
      _isNonNegativeInt(row['low_stock_threshold']) &&
      (row['is_consumable'] == 0 || row['is_consumable'] == 1) &&
      row['notes'] is String;

  bool _isNonNegativeInt(Object? value) => value is int && value >= 0;
}
