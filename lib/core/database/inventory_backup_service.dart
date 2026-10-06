import 'dart:convert';
import 'dart:typed_data';

import 'app_database.dart';

class InventoryBackupService {
  const InventoryBackupService(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Uint8List> createBackup() async {
    final (equipment, activity) = await _appDatabase.database.transaction(
      (transaction) async => (
        await transaction.query('equipment', orderBy: 'name COLLATE NOCASE'),
        await transaction.query('activity', orderBy: 'created_at'),
      ),
    );
    final backup = {
      'format': 'kito-backup',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'equipment': equipment,
      'activity': activity,
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)),
    );
  }

  Future<int> restoreBackup(Uint8List bytes) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'kito-backup' ||
        decoded['version'] != 1 ||
        decoded['equipment'] is! List ||
        decoded['activity'] is! List) {
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
    final activity = _validateRows(
      decoded['activity']! as List,
      const {'id', 'message', 'created_at'},
    );
    if (equipment.any((row) => !_isValidEquipmentRow(row)) ||
        activity.any((row) => !_isValidActivityRow(row))) {
      throw const FormatException('La sauvegarde contient des données invalides.');
    }

    await _appDatabase.database.transaction((transaction) async {
      await transaction.delete('activity');
      await transaction.delete('equipment');
      for (final row in equipment) {
        await transaction.insert('equipment', row);
      }
      for (final row in activity) {
        await transaction.insert('activity', row);
      }
    });
    return equipment.length;
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

  bool _isValidActivityRow(Map<String, Object?> row) {
    final createdAt = row['created_at'];
    return row['id'] is String &&
        row['message'] is String &&
        createdAt is String &&
        DateTime.tryParse(createdAt) != null;
  }

  bool _isNonNegativeInt(Object? value) => value is int && value >= 0;
}
