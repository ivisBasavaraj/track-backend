// File: lib/models/tool_list_model.dart

class ToolList {
  final String id;
  final String toolName;
  final List<SheetSummary> sheets;
  final SheetTotals totals;
  final String fileName;
  final String uploadedBy;
  final String uploaderName;
  final String? uploaderEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalTools;
  final int totalHoles;
  final double totalCuttingLength;

  ToolList({
    required this.id,
    required this.toolName,
    required this.sheets,
    required this.totals,
    required this.fileName,
    required this.uploadedBy,
    required this.uploaderName,
    this.uploaderEmail,
    required this.createdAt,
    required this.updatedAt,
    required this.totalTools,
    required this.totalHoles,
    required this.totalCuttingLength,
  });

  List<Tool> get toolData => sheets.expand((sheet) => sheet.toolData).toList();

  /// Convert ToolList to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'toolName': toolName,
      'sheets': sheets.map((sheet) => sheet.toMap()).toList(),
      'totals': totals.toMap(),
      'fileName': fileName,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploaderEmail': uploaderEmail,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'totalTools': totalTools,
      'totalHoles': totalHoles,
      'totalCuttingLength': totalCuttingLength,
    };
  }

  /// Create ToolList from JSON map (MongoDB response)
  factory ToolList.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'] is Map<String, dynamic> ? map['data'] as Map<String, dynamic> : map;
    
    // Parse toolData directly if it exists
    List<Tool> directToolData = [];
    if (rawData['toolData'] != null && rawData['toolData'] is List) {
      directToolData = (rawData['toolData'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Tool.fromMap)
          .toList();
    }
    
    // Create a single sheet from toolData if no sheets exist
    List<SheetSummary> sheets = _parseSheets(rawData['sheets'] ?? map['sheets']);
    if (sheets.isEmpty && directToolData.isNotEmpty) {
      sheets = [SheetSummary(
        sheetName: rawData['sheetName'] ?? 'csv',
        toolData: directToolData,
        toolCount: directToolData.length,
        totalHoles: directToolData.fold(0, (sum, t) => sum + t.noOfHolesInComponent),
        totalCuttingLength: directToolData.fold(0.0, (sum, t) => sum + t.cuttingLength),
      )];
    }
    
    return ToolList(
      id: rawData['_id'] ?? rawData['id'] ?? '',
      toolName: rawData['toolName'] ?? map['toolName'] ?? '',
      sheets: sheets,
      totals: SheetTotals.fromMap(rawData['totals'] ?? map['totals'] ?? const {}),
      fileName: rawData['fileName'] ?? map['fileName'] ?? '',
      uploadedBy: _parseUploadedBy(rawData['uploadedBy'] ?? map['uploadedBy']),
      uploaderName: rawData['uploaderName'] ?? map['uploaderName'] ?? '',
      uploaderEmail: rawData['uploaderEmail'] ?? map['uploaderEmail'],
      createdAt: _parseDate(rawData['createdAt'] ?? rawData['uploadedAt'] ?? map['createdAt']),
      updatedAt: _parseDate(rawData['updatedAt'] ?? map['updatedAt']),
      totalTools: rawData['totalTools'] ?? map['totalTools'] ?? 0,
      totalHoles: rawData['totalHoles'] ?? map['totalHoles'] ?? 0,
      totalCuttingLength: (rawData['totalCuttingLength'] ?? map['totalCuttingLength'] ?? 0).toDouble(),
    );
  }

  /// Copy with method for immutability
  ToolList copyWith({
    String? id,
    String? toolName,
    List<SheetSummary>? sheets,
    SheetTotals? totals,
    String? fileName,
    String? uploadedBy,
    String? uploaderName,
    String? uploaderEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalTools,
    int? totalHoles,
    double? totalCuttingLength,
  }) {
    return ToolList(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      sheets: sheets ?? this.sheets,
      totals: totals ?? this.totals,
      fileName: fileName ?? this.fileName,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploaderName: uploaderName ?? this.uploaderName,
      uploaderEmail: uploaderEmail ?? this.uploaderEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalTools: totalTools ?? this.totalTools,
      totalHoles: totalHoles ?? this.totalHoles,
      totalCuttingLength: totalCuttingLength ?? this.totalCuttingLength,
    );
  }

  @override
  String toString() {
    return 'ToolList(id: $id, toolName: $toolName, sheets: ${sheets.length}, totals: $totals)';
  }

  static List<SheetSummary> _parseSheets(dynamic rawSheets) {
    if (rawSheets is List) {
      return rawSheets
          .whereType<Map<String, dynamic>>()
          .map(SheetSummary.fromMap)
          .toList();
    }
    return const <SheetSummary>[];
  }

  static String _parseUploadedBy(dynamic uploadedBy) {
    if (uploadedBy == null) {
      return '';
    }
    if (uploadedBy is Map<String, dynamic>) {
      return uploadedBy['_id'] ?? uploadedBy['id'] ?? '';
    }
    return uploadedBy.toString();
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value == null) {
      return DateTime.now();
    }
    return DateTime.parse(value.toString());
  }
}

// File: lib/models/tool_model.dart

class Tool {
  final int slNo;
  final String atcPocketNo;
  final String toolName;
  final String holderName;
  final String toolRoomNo;
  final int noOfHolesInComponent;
  final double cuttingLength;
  final String remarks;
  final int toolLifeTime;

  Tool({
    required this.slNo,
    required this.atcPocketNo,
    required this.toolName,
    required this.holderName,
    required this.toolRoomNo,
    required this.noOfHolesInComponent,
    required this.cuttingLength,
    required this.remarks,
    this.toolLifeTime = 0,
  });

  /// Convert Tool to JSON map
  Map<String, dynamic> toMap() {
    return {
      'slNo': slNo,
      'atcPocketNo': atcPocketNo,
      'toolName': toolName,
      'holderName': holderName,
      'toolRoomNo': toolRoomNo,
      'noOfHolesInComponent': noOfHolesInComponent,
      'cuttingLength': cuttingLength,
      'remarks': remarks,
      'toolLifeTime': toolLifeTime,
    };
  }

  /// Create Tool from JSON map
  factory Tool.fromMap(Map<String, dynamic> map) {
    return Tool(
      slNo: map['slNo'] ?? 0,
      atcPocketNo: map['atcPocketNo'] ?? '',
      toolName: map['toolName'] ?? '',
      holderName: map['holderName'] ?? '',
      toolRoomNo: map['toolRoomNo'] ?? '',
      noOfHolesInComponent: map['noOfHolesInComponent'] ?? 0,
      cuttingLength: (map['cuttingLength'] ?? 0).toDouble(),
      remarks: map['remarks'] ?? '',
      toolLifeTime: map['toolLifeTime'] ?? 0,
    );
  }

  /// Copy with method
  Tool copyWith({
    int? slNo,
    String? atcPocketNo,
    String? toolName,
    String? holderName,
    String? toolRoomNo,
    int? noOfHolesInComponent,
    double? cuttingLength,
    String? remarks,
    int? toolLifeTime,
  }) {
    return Tool(
      slNo: slNo ?? this.slNo,
      atcPocketNo: atcPocketNo ?? this.atcPocketNo,
      toolName: toolName ?? this.toolName,
      holderName: holderName ?? this.holderName,
      toolRoomNo: toolRoomNo ?? this.toolRoomNo,
      noOfHolesInComponent: noOfHolesInComponent ?? this.noOfHolesInComponent,
      cuttingLength: cuttingLength ?? this.cuttingLength,
      remarks: remarks ?? this.remarks,
      toolLifeTime: toolLifeTime ?? this.toolLifeTime,
    );
  }

  @override
  String toString() {
    return 'Tool(slNo: $slNo, toolName: $toolName, atcPocketNo: $atcPocketNo)';
  }
}

class SheetSummary {
  final String sheetName;
  final List<Tool> toolData;
  final int toolCount;
  final int totalHoles;
  final double totalCuttingLength;

  SheetSummary({
    required this.sheetName,
    required this.toolData,
    required this.toolCount,
    required this.totalHoles,
    required this.totalCuttingLength,
  });

  factory SheetSummary.fromMap(Map<String, dynamic> map) {
    final rawToolData = map['toolData'];
    final tools = rawToolData is List
        ? rawToolData
            .whereType<Map<String, dynamic>>()
            .map(Tool.fromMap)
            .toList()
        : const <Tool>[];

    return SheetSummary(
      sheetName: map['sheetName'] ?? map['name'] ?? '',
      toolData: tools,
      toolCount: map['toolCount'] ?? map['totalTools'] ?? tools.length,
      totalHoles: map['totalHoles'] ?? 0,
      totalCuttingLength: (map['totalCuttingLength'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sheetName': sheetName,
      'toolData': toolData.map((tool) => tool.toMap()).toList(),
      'toolCount': toolCount,
      'totalHoles': totalHoles,
      'totalCuttingLength': totalCuttingLength,
    };
  }

  SheetSummary copyWith({
    String? sheetName,
    List<Tool>? toolData,
    int? toolCount,
    int? totalHoles,
    double? totalCuttingLength,
  }) {
    return SheetSummary(
      sheetName: sheetName ?? this.sheetName,
      toolData: toolData ?? this.toolData,
      toolCount: toolCount ?? this.toolCount,
      totalHoles: totalHoles ?? this.totalHoles,
      totalCuttingLength: totalCuttingLength ?? this.totalCuttingLength,
    );
  }

  @override
  String toString() {
    return 'SheetSummary(sheetName: $sheetName, tools: ${toolData.length})';
  }
}

class SheetTotals {
  final int totalTools;
  final int totalHoles;
  final double totalCuttingLength;

  SheetTotals({
    required this.totalTools,
    required this.totalHoles,
    required this.totalCuttingLength,
  });

  factory SheetTotals.fromMap(Map<String, dynamic> map) {
    return SheetTotals(
      totalTools: map['totalTools'] ?? 0,
      totalHoles: map['totalHoles'] ?? 0,
      totalCuttingLength: (map['totalCuttingLength'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalTools': totalTools,
      'totalHoles': totalHoles,
      'totalCuttingLength': totalCuttingLength,
    };
  }

  SheetTotals copyWith({
    int? totalTools,
    int? totalHoles,
    double? totalCuttingLength,
  }) {
    return SheetTotals(
      totalTools: totalTools ?? this.totalTools,
      totalHoles: totalHoles ?? this.totalHoles,
      totalCuttingLength: totalCuttingLength ?? this.totalCuttingLength,
    );
  }

  @override
  String toString() {
    return 'SheetTotals(totalTools: $totalTools, totalHoles: $totalHoles, totalCuttingLength: $totalCuttingLength)';
  }
}

// File: lib/models/excel_model.dart

class ExcelData {
  final String fileName;
  final List<ExcelSheet> sheets;
  final int sheetCount;
  final int totalRows;

  ExcelData({
    required this.fileName,
    required this.sheets,
    required this.sheetCount,
    required this.totalRows,
  });

  @override
  String toString() {
    return 'ExcelData(fileName: $fileName, sheetCount: $sheetCount, totalRows: $totalRows)';
  }
}

class ExcelSheet {
  final String name;
  final List<String> headers;
  final List<Map<String, dynamic>> rows;
  final int rowCount;

  ExcelSheet({
    required this.name,
    required this.headers,
    required this.rows,
    required this.rowCount,
  });

  @override
  String toString() {
    return 'ExcelSheet(name: $name, headers: $headers, rowCount: $rowCount)';
  }
}