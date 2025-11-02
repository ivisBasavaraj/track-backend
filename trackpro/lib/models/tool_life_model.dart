class MasterTool {
  final int toolId;
  final String toolName;
  final String holderName;
  final String atcPocketNo;
  final String toolRoomNo;
  final int toolLifeThreshold;
  final String status;
  final String? supervisorEmail;
  final DateTime createdDate;
  final double? cumulativeUsage;
  final double? usagePercentage;
  final double? remainingLife;

  MasterTool({
    required this.toolId,
    required this.toolName,
    required this.holderName,
    required this.atcPocketNo,
    required this.toolRoomNo,
    required this.toolLifeThreshold,
    required this.status,
    this.supervisorEmail,
    required this.createdDate,
    this.cumulativeUsage,
    this.usagePercentage,
    this.remainingLife,
  });

  factory MasterTool.fromJson(Map<String, dynamic> json) {
    return MasterTool(
      toolId: json['tool_id'] ?? 0,
      toolName: json['tool_name'] ?? '',
      holderName: json['holder_name'] ?? '',
      atcPocketNo: json['atc_pocket_no'] ?? '',
      toolRoomNo: json['tool_room_no'] ?? '',
      toolLifeThreshold: json['tool_life_threshold'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
      supervisorEmail: json['supervisor_email'],
      createdDate: json['created_date'] != null
          ? DateTime.parse(json['created_date'])
          : DateTime.now(),
      cumulativeUsage: json['cumulative_usage']?.toDouble(),
      usagePercentage: json['usage_percentage'] != null
          ? double.parse(json['usage_percentage'].toString())
          : null,
      remainingLife: json['remaining_life']?.toDouble(),
    );
  }
}

class ToolUsageLog {
  final String id;
  final int toolId;
  final String toolName;
  final String componentId;
  final int noOfHoles;
  final double cuttingLength;
  final double usageScore;
  final double cumulativeTotalBefore;
  final double cumulativeTotalAfter;
  final int toolLifeThreshold;
  final double usagePercentage;
  final double remainingLife;
  final String alertType;
  final bool alertTriggered;
  final DateTime timestamp;

  ToolUsageLog({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.componentId,
    required this.noOfHoles,
    required this.cuttingLength,
    required this.usageScore,
    required this.cumulativeTotalBefore,
    required this.cumulativeTotalAfter,
    required this.toolLifeThreshold,
    required this.usagePercentage,
    required this.remainingLife,
    required this.alertType,
    required this.alertTriggered,
    required this.timestamp,
  });

  factory ToolUsageLog.fromJson(Map<String, dynamic> json) {
    return ToolUsageLog(
      id: json['_id'] ?? '',
      toolId: json['tool_id'] ?? 0,
      toolName: json['tool_name'] ?? '',
      componentId: json['component_id'] ?? '',
      noOfHoles: json['no_of_holes'] ?? 0,
      cuttingLength: (json['cutting_length'] ?? 0).toDouble(),
      usageScore: (json['usage_score'] ?? 0).toDouble(),
      cumulativeTotalBefore: (json['cumulative_total_before'] ?? 0).toDouble(),
      cumulativeTotalAfter: (json['cumulative_total_after'] ?? 0).toDouble(),
      toolLifeThreshold: json['tool_life_threshold'] ?? 0,
      usagePercentage: (json['usage_percentage'] ?? 0).toDouble(),
      remainingLife: (json['remaining_life'] ?? 0).toDouble(),
      alertType: json['alert_type'] ?? 'NONE',
      alertTriggered: json['alert_triggered'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class ToolAlert {
  final String id;
  final int toolId;
  final String toolName;
  final int toolLifeThreshold;
  final double cumulativeUsage;
  final String alertType;
  final String alertSeverity;
  final double usagePercentage;
  final double remainingLife;
  final List<String> componentsUsed;
  final String? supervisorEmail;
  final String alertStatus;
  final String alertMessage;
  final String alertDescription;
  final DateTime createdDate;
  final DateTime? sentDate;
  final DateTime? acknowledgedDate;

  ToolAlert({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.toolLifeThreshold,
    required this.cumulativeUsage,
    required this.alertType,
    required this.alertSeverity,
    required this.usagePercentage,
    required this.remainingLife,
    required this.componentsUsed,
    this.supervisorEmail,
    required this.alertStatus,
    required this.alertMessage,
    required this.alertDescription,
    required this.createdDate,
    this.sentDate,
    this.acknowledgedDate,
  });

  factory ToolAlert.fromJson(Map<String, dynamic> json) {
    return ToolAlert(
      id: json['_id'] ?? '',
      toolId: json['tool_id'] ?? 0,
      toolName: json['tool_name'] ?? '',
      toolLifeThreshold: json['tool_life_threshold'] ?? 0,
      cumulativeUsage: (json['cumulative_usage'] ?? 0).toDouble(),
      alertType: json['alert_type'] ?? '',
      alertSeverity: json['alert_severity'] ?? '',
      usagePercentage: (json['usage_percentage'] ?? 0).toDouble(),
      remainingLife: (json['remaining_life'] ?? 0).toDouble(),
      componentsUsed: List<String>.from(json['components_used'] ?? []),
      supervisorEmail: json['supervisor_email'],
      alertStatus: json['alert_status'] ?? 'PENDING',
      alertMessage: json['alert_message'] ?? '',
      alertDescription: json['alert_description'] ?? '',
      createdDate: json['created_date'] != null
          ? DateTime.parse(json['created_date'])
          : DateTime.now(),
      sentDate: json['sent_date'] != null
          ? DateTime.parse(json['sent_date'])
          : null,
      acknowledgedDate: json['acknowledged_date'] != null
          ? DateTime.parse(json['acknowledged_date'])
          : null,
    );
  }
}

class ToolStatus {
  final int toolId;
  final String toolName;
  final String holderName;
  final double cumulativeUsage;
  final int toolLifeThreshold;
  final double usagePercentage;
  final double remainingLife;
  final bool thresholdReached;
  final bool warningThresholdReached;
  final String alertStatus;
  final List<String> componentsUsed;
  final DateTime? lastUsed;
  final String status;
  final String recommendation;

  ToolStatus({
    required this.toolId,
    required this.toolName,
    required this.holderName,
    required this.cumulativeUsage,
    required this.toolLifeThreshold,
    required this.usagePercentage,
    required this.remainingLife,
    required this.thresholdReached,
    required this.warningThresholdReached,
    required this.alertStatus,
    required this.componentsUsed,
    this.lastUsed,
    required this.status,
    required this.recommendation,
  });

  factory ToolStatus.fromJson(Map<String, dynamic> json) {
    return ToolStatus(
      toolId: json['tool_id'] ?? 0,
      toolName: json['tool_name'] ?? '',
      holderName: json['holder_name'] ?? '',
      cumulativeUsage: (json['cumulative_usage'] ?? 0).toDouble(),
      toolLifeThreshold: json['tool_life_threshold'] ?? 0,
      usagePercentage: double.parse(json['usage_percentage'].toString()),
      remainingLife: (json['remaining_life'] ?? 0).toDouble(),
      thresholdReached: json['threshold_reached'] ?? false,
      warningThresholdReached: json['warning_threshold_reached'] ?? false,
      alertStatus: json['alert_status'] ?? 'NONE',
      componentsUsed: List<String>.from(json['components_used'] ?? []),
      lastUsed: json['last_used'] != null
          ? DateTime.parse(json['last_used'])
          : null,
      status: json['status'] ?? 'ACTIVE',
      recommendation: json['recommendation'] ?? '',
    );
  }
}
