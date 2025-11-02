// File: lib/models/tool_stock_model.dart

class ToolStock {
  final String id;
  final String toolName;
  final String atcPocketNo;
  final String toolRoomNo;
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final int reorderLevel;
  final int reorderQuantity;
  final String unit;
  final String status;
  final String lastUpdatedByName;
  final String notes;
  final String location;
  final double costPerUnit;
  final DateTime? lastRestockDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ToolStock({
    required this.id,
    required this.toolName,
    required this.atcPocketNo,
    required this.toolRoomNo,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.reorderLevel,
    required this.reorderQuantity,
    required this.unit,
    required this.status,
    required this.lastUpdatedByName,
    required this.notes,
    required this.location,
    required this.costPerUnit,
    this.lastRestockDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get stock status color based on current stock and thresholds
  String getStatusLabel() {
    switch (status) {
      case 'out_of_stock':
        return 'Out of Stock';
      case 'critical':
        return 'Critical';
      case 'low_stock':
        return 'Low Stock';
      case 'in_stock':
        return 'In Stock';
      default:
        return 'Unknown';
    }
  }

  /// Check if stock needs reordering
  bool needsReordering() => currentStock <= reorderLevel;

  /// Get percentage of stock relative to maximum
  double getStockPercentage() {
    if (maximumStock == 0) return 0;
    return (currentStock / maximumStock).clamp(0, 1);
  }

  /// Calculate total value of current stock
  double getTotalValue() => currentStock * costPerUnit;

  /// Convert ToolStock to JSON map
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'toolName': toolName,
      'atcPocketNo': atcPocketNo,
      'toolRoomNo': toolRoomNo,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'reorderLevel': reorderLevel,
      'reorderQuantity': reorderQuantity,
      'unit': unit,
      'status': status,
      'lastUpdatedByName': lastUpdatedByName,
      'notes': notes,
      'location': location,
      'costPerUnit': costPerUnit,
      'lastRestockDate': lastRestockDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create ToolStock from JSON map (API response)
  factory ToolStock.fromMap(Map<String, dynamic> map) {
    return ToolStock(
      id: map['_id'] ?? map['id'] ?? '',
      toolName: map['toolName'] ?? '',
      atcPocketNo: map['atcPocketNo'] ?? '',
      toolRoomNo: map['toolRoomNo'] ?? '',
      currentStock: map['currentStock'] ?? 0,
      minimumStock: map['minimumStock'] ?? 5,
      maximumStock: map['maximumStock'] ?? 50,
      reorderLevel: map['reorderLevel'] ?? 10,
      reorderQuantity: map['reorderQuantity'] ?? 20,
      unit: map['unit'] ?? 'pieces',
      status: map['status'] ?? 'in_stock',
      lastUpdatedByName: map['lastUpdatedByName'] ?? '',
      notes: map['notes'] ?? '',
      location: map['location'] ?? 'Tool Room',
      costPerUnit: (map['costPerUnit'] ?? 0).toDouble(),
      lastRestockDate: map['lastRestockDate'] != null
          ? DateTime.tryParse(map['lastRestockDate'].toString())
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  /// Copy with method for immutability
  ToolStock copyWith({
    String? id,
    String? toolName,
    String? atcPocketNo,
    String? toolRoomNo,
    int? currentStock,
    int? minimumStock,
    int? maximumStock,
    int? reorderLevel,
    int? reorderQuantity,
    String? unit,
    String? status,
    String? lastUpdatedByName,
    String? notes,
    String? location,
    double? costPerUnit,
    DateTime? lastRestockDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ToolStock(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      atcPocketNo: atcPocketNo ?? this.atcPocketNo,
      toolRoomNo: toolRoomNo ?? this.toolRoomNo,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      lastUpdatedByName: lastUpdatedByName ?? this.lastUpdatedByName,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ToolStock(id: $id, toolName: $toolName, currentStock: $currentStock, status: $status)';
  }
}

/// Tool Stock Statistics
class ToolStockStatistics {
  final int totalItems;
  final int totalStock;
  final double totalValue;
  final int lowStockCount;
  final int criticalCount;
  final int outOfStockCount;

  ToolStockStatistics({
    required this.totalItems,
    required this.totalStock,
    required this.totalValue,
    required this.lowStockCount,
    required this.criticalCount,
    required this.outOfStockCount,
  });

  factory ToolStockStatistics.fromMap(Map<String, dynamic> map) {
    return ToolStockStatistics(
      totalItems: map['totalItems'] ?? 0,
      totalStock: map['totalStock'] ?? 0,
      totalValue: (map['totalValue'] ?? 0).toDouble(),
      lowStockCount: map['lowStockCount'] ?? 0,
      criticalCount: map['criticalCount'] ?? 0,
      outOfStockCount: map['outOfStockCount'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'ToolStockStatistics(totalItems: $totalItems, totalStock: $totalStock, critical: $criticalCount)';
  }
}