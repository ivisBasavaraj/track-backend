import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class CsvParser {
  static Future<List<Map<String, dynamic>>?> pickAndParseCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.first.bytes;
    if (bytes == null) return null;

    final csvString = utf8.decode(bytes);
    return parseCsvString(csvString);
  }

  static List<Map<String, dynamic>> parseCsvString(String csvString) {
    final lines = csvString.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length < 3) return [];

    final data = <Map<String, dynamic>>[];

    for (var i = 2; i < lines.length; i++) {
      final values = lines[i].split(',');
      if (values.length >= 3) {
        data.add({
          'toolName': values[1].trim(),
          'currentStock': values[2].trim(),
          'remarks': values.length > 3 ? values[3].trim() : '',
        });
      }
    }

    return data;
  }
}
