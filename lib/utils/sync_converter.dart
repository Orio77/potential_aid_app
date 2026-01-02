/// Utility class for converting between local and remote data formats

class SyncConverter {
  static const Set<String> _timestampFieldNames = {
    'start_date',
    'deadline',
    'last_modified',
    'day_local',
    'created_at',
    'updated_at',
    'completed_at',
    'start_time',
    'end_time',
  };

  static const Set<String> _colorFieldNames = {'color'};

  static const Map<String, Map<String, String>> _columnNameOverrides = {
    'block_task': {'blockId': 'block_id', 'taskId': 'task_id'},
  };

  /// Normalize value for remote storage
  /// 
  /// Converts local values to remote-compatible formats:
  /// - DateTime objects are converted to ISO8601 strings
  /// - Color integers are converted to signed 32-bit format for PostgreSQL
  /// - Epoch timestamps (int) are detected and converted to ISO8601 strings
  /// 
  /// Parameters:
  /// - value: The value to normalize
  /// - fieldName: Optional field name to apply field-specific normalization rules
  /// 
  /// Returns: Normalized value suitable for remote storage
  static dynamic normalizeValue(dynamic value, {String? fieldName}) {
    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (fieldName != null && _colorFieldNames.contains(fieldName)) {
      final colorInt = _coerceToInt(value);
      if (colorInt != null) {
        return _toSigned32Bit(colorInt);
      }
    }

    final intValue = _coerceToInt(value);
    if (intValue != null && _shouldTreatAsEpoch(intValue, fieldName)) {
      final dateTime = intValue > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(intValue)
          : DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
      return dateTime.toIso8601String();
    }

    return value;
  }

  /// Convert camelCase to snake_case
  static String toSnakeCase(String input) {
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (_isUpperCase(char) && i != 0 && input[i - 1] != '_') {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  /// Get field value with fallback to snake_case key
  static T? getField<T>(Map<String, dynamic> record, String camelCaseKey) {
    if (record.containsKey(camelCaseKey)) {
      return record[camelCaseKey] as T?;
    }
    final snakeKey = toSnakeCase(camelCaseKey);
    if (record.containsKey(snakeKey)) {
      return record[snakeKey] as T?;
    }
    return null;
  }

  /// Get column name override if exists
  static String getColumnName(String tableName, String columnName) {
    final overrides = _columnNameOverrides[tableName];
    return overrides?[columnName] ?? toSnakeCase(columnName);
  }

  /// Restore unsigned color value
  static int? restoreUnsignedColor(dynamic value) {
    final intValue = _coerceToInt(value);
    if (intValue == null) return null;
    const mod = 0x100000000;
    return intValue < 0 ? intValue + mod : intValue;
  }

  /// Parse DateTime from various formats
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Private helper methods

  static int? _coerceToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.round();
    return null;
  }

  static bool _shouldTreatAsEpoch(int value, String? fieldName) {
    if (fieldName != null && _timestampFieldNames.contains(fieldName)) {
      return true;
    }

    // Heuristic: treat large positive ints as epoch timestamps
    if (value <= 0) return false;
    // Seconds range roughly between 2001 and 2099
    if (value >= 1000000000 && value <= 4102444800) {
      return true;
    }
    // Milliseconds for reasonable dates
    if (value >= 1000000000000 && value <= 4102444800000) {
      return true;
    }
    return false;
  }

  static int _toSigned32Bit(int value) {
    const maxSigned = 0x7fffffff;
    const minSigned = -0x80000000;
    const mod = 0x100000000;
    if (value > maxSigned) {
      return value - mod;
    }
    if (value < minSigned) {
      return value + mod;
    }
    return value;
  }

  static bool _isUpperCase(String char) {
    return char.toUpperCase() == char && char.toLowerCase() != char;
  }
}
