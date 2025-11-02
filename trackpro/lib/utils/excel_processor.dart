import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Utility responsible for parsing Excel tool list uploads into a
/// service-friendly structure.
class ExcelProcessor {
  /// Columns that must be present to build a valid tool list payload.
  static const List<String> _requiredKeys = [
    'toolName',
    'atcPocketNo',
    'holderName',
    'toolRoomNo',
  ];

  /// Frequently used header variations mapped to canonical keys.
  static const Map<String, String> _headerMapping = {
    'sl': 'slNo',
    'slno': 'slNo',
    'sl no': 'slNo',
    'sl number': 'slNo',
    'serial number': 'slNo',
    'atc pocket no': 'atcPocketNo',
    'atc pocketno': 'atcPocketNo',
    'atc pocket number': 'atcPocketNo',
    'tool name': 'toolName',
    'tool names': 'toolName',
    'holder name': 'holderName',
    'holder': 'holderName',
    'tool room no': 'toolRoomNo',
    'toolroom no': 'toolRoomNo',
    'tool room number': 'toolRoomNo',
    'no of holes in component': 'noOfHolesInComponent',
    'no of holes': 'noOfHolesInComponent',
    'number of holes': 'noOfHolesInComponent',
    'holes in component': 'noOfHolesInComponent',
    'cutting length': 'cuttingLength',
    'length of cut': 'cuttingLength',
    'cut length': 'cuttingLength',
    'cutting length mm': 'cuttingLength',
    'remarks': 'remarks',
    'remark': 'remarks',
    'comments': 'remarks',
    'comment': 'remarks',
  };

  /// Parse the provided Excel bytes and return cleaned tool rows.
  static List<Map<String, dynamic>> processToolListExcelFromBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw Exception('Selected file is empty.');
    }

    return _processExcelBytes(bytes);
  }

  /// Parse the provided Excel [file] and return cleaned tool rows.
  static List<Map<String, dynamic>> processToolListExcel(File file) {
    if (!file.existsSync()) {
      throw Exception('Selected file could not be found.');
    }

    final bytes = file.readAsBytesSync();
    if (bytes.isEmpty) {
      throw Exception('Selected file is empty.');
    }

    return _processExcelBytes(bytes);
  }

  static List<Map<String, dynamic>> _processExcelBytes(List<int> bytes) {

    final excel = Excel.decodeBytes(bytes);

    // Merge the APIs (`tables` vs `sheets`) to support different excel package versions.
    final Map<String, Sheet> sheetMap = {};
    sheetMap.addAll(excel.tables);
    sheetMap.addAll(excel.sheets);

    if (sheetMap.isEmpty) {
      throw Exception('No sheets were found in the Excel file.');
    }

    // Prefer the first sheet that contains data; fall back to the first sheet otherwise.
    Sheet? selectedSheet;
    for (final entry in sheetMap.entries) {
      if (entry.value.rows.isNotEmpty) {
        selectedSheet = entry.value;
        break;
      }
    }
    selectedSheet ??= sheetMap.values.first;

    final rows = selectedSheet.rows;
    if (rows.isEmpty) {
      throw Exception('The selected sheet does not contain any rows.');
    }

    int headerIndex = -1;
    List<String?> headerKeys = [];

    for (var i = 0; i < rows.length; i++) {
      final headerRow = rows[i];
      final mappedHeaders = _mapHeaderRow(headerRow);
      if (mappedHeaders.any((key) => key != null && key.isNotEmpty)) {
        headerIndex = i;
        headerKeys = mappedHeaders;
        break;
      }
    }

    if (headerIndex == -1) {
      throw Exception('Unable to locate a header row in the Excel sheet.');
    }

    _validateRequiredColumns(headerKeys);

    final toolRows = <Map<String, dynamic>>[];

    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (_isRowCompletelyEmpty(row)) {
        continue;
      }

      final mappedRow = _mapRow(row, headerKeys);
      if (_isRowEmptyAfterMapping(mappedRow)) {
        continue;
      }

      toolRows.add(mappedRow);
    }

    if (toolRows.isEmpty) {
      throw Exception('No tool rows were detected in the Excel file.');
    }

    return toolRows;
  }

  /// Convert headers to their canonical representation while preserving unknown columns.
  static List<String?> _mapHeaderRow(List<Data?> row) {
    final mappedHeaders = <String?>[];
    for (final cell in row) {
      final rawHeader = _extractCellString(cell);
      if (rawHeader == null) {
        mappedHeaders.add(null);
        continue;
      }

      final normalized = _normalizeHeader(rawHeader);
      final canonical = _mapHeaderName(normalized);

      if (canonical != null && canonical.isNotEmpty) {
        mappedHeaders.add(canonical);
      } else if (normalized.isNotEmpty) {
        // Preserve additional columns by using a compact header key.
        mappedHeaders.add(normalized.replaceAll(' ', ''));
      } else {
        mappedHeaders.add(null);
      }
    }
    return mappedHeaders;
  }

  /// Ensure the minimum required columns are present before parsing rows.
  static void _validateRequiredColumns(List<String?> headerKeys) {
    final present = headerKeys.whereType<String>().toSet();
    final missing = _requiredKeys.where((key) => !present.contains(key)).toList();

    if (missing.isNotEmpty) {
      throw Exception('The Excel file is missing required columns: ${missing.join(', ')}.');
    }
  }

  /// Convert a row of cells into a map using the header ordering.
  static Map<String, dynamic> _mapRow(List<Data?> row, List<String?> headerKeys) {
    final mappedRow = <String, dynamic>{};

    for (var columnIndex = 0; columnIndex < headerKeys.length; columnIndex++) {
      final key = headerKeys[columnIndex];
      if (key == null || key.isEmpty) {
        continue;
      }

      final cell = columnIndex < row.length ? row[columnIndex] : null;
      final rawValue = _extractCellValue(cell);
      final sanitizedValue = _sanitizeCellValue(key, rawValue);

      if (sanitizedValue != null) {
        mappedRow[key] = sanitizedValue;
      }
    }

    return mappedRow;
  }

  /// Determine whether a data row is entirely empty.
  static bool _isRowCompletelyEmpty(List<Data?> row) {
    return row.every((cell) {
      final value = _extractCellString(cell);
      return value == null || value.isEmpty;
    });
  }

  /// Remove rows that only contain empty or zero values.
  static bool _isRowEmptyAfterMapping(Map<String, dynamic> row) {
    if (row.isEmpty) {
      return true;
    }

    return row.values.every((value) {
      if (value == null) {
        return true;
      }
      if (value is String) {
        return value.trim().isEmpty;
      }
      if (value is num) {
        return value == 0;
      }
      return false;
    });
  }

  /// Map a normalized header string to its canonical key.
  static String? _mapHeaderName(String normalizedHeader) {
    if (normalizedHeader.isEmpty) {
      return null;
    }

    final directMatch = _headerMapping[normalizedHeader];
    if (directMatch != null) {
      return directMatch;
    }

    if (normalizedHeader.startsWith('sl') && normalizedHeader.contains('no')) {
      return 'slNo';
    }
    if (normalizedHeader.contains('atc') && normalizedHeader.contains('pocket')) {
      return 'atcPocketNo';
    }
    if (normalizedHeader.contains('tool') && normalizedHeader.contains('name')) {
      return 'toolName';
    }
    if (normalizedHeader.contains('holder') && normalizedHeader.contains('name')) {
      return 'holderName';
    }
    if (normalizedHeader.contains('tool') && normalizedHeader.contains('room')) {
      return 'toolRoomNo';
    }
    if (normalizedHeader.contains('hole')) {
      return 'noOfHolesInComponent';
    }
    if (normalizedHeader.contains('cut') && normalizedHeader.contains('length')) {
      return 'cuttingLength';
    }
    if (normalizedHeader.contains('remark') || normalizedHeader.contains('comment')) {
      return 'remarks';
    }

    return null;
  }

  /// Convert commonly formatted headers (mixed case, punctuation) into a standard form.
  static String _normalizeHeader(String input) {
    final normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Extract the raw value from an Excel cell.
  static dynamic _extractCellValue(Data? cell) => cell?.value;

  /// Extract a trimmed string value from an Excel cell, returning null for blanks.
  static String? _extractCellString(Data? cell) {
    final value = _extractCellValue(cell);
    if (value == null) {
      return null;
    }
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  /// Sanitise individual cell values based on the expected column.
  static dynamic _sanitizeCellValue(String key, dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }

    if (rawValue is String) {
      final trimmed = rawValue.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
        return null;
      }
      rawValue = trimmed;
    }

    switch (key) {
      case 'slNo':
      case 'noOfHolesInComponent':
        final numericValue = _parseNumeric(rawValue);
        return numericValue?.round();
      case 'cuttingLength':
        final numericValue = _parseNumeric(rawValue);
        return numericValue?.toDouble();
      case 'toolName':
      case 'atcPocketNo':
      case 'holderName':
      case 'toolRoomNo':
      case 'remarks':
        return rawValue.toString();
      default:
        return rawValue is String ? rawValue : rawValue.toString();
    }
  }

  /// Attempt to parse numeric values from strings or dynamic inputs.
  static num? _parseNumeric(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      if (cleaned.isEmpty) {
        return null;
      }
      return num.tryParse(cleaned);
    }
    return null;
  }
}