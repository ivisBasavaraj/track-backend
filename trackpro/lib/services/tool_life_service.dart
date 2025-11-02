import '../models/tool_life_model.dart';
import '../utils/api_client.dart';

class ToolLifeService {
  final ApiClient _apiClient;

  ToolLifeService(this._apiClient);

  Future<Map<String, dynamic>> recordToolUsage({
    required int toolId,
    required String componentId,
    required int noOfHoles,
    required double cuttingLength,
    String? operatorId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/tool-life/usage/record',
        data: {
          'tool_id': toolId,
          'component_id': componentId,
          'no_of_holes': noOfHoles,
          'cutting_length': cuttingLength,
          'operator_id': operatorId,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to record tool usage');
      }
    } catch (e) {
      throw Exception('Error recording tool usage: $e');
    }
  }

  Future<ToolStatus> getToolStatus(int toolId) async {
    try {
      final response = await _apiClient.get('/tool-life/$toolId/status');
      final data = response.data;

      if (data['success'] == true) {
        return ToolStatus.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to get tool status');
      }
    } catch (e) {
      throw Exception('Error fetching tool status: $e');
    }
  }

  Future<List<ToolAlert>> getActiveAlerts() async {
    try {
      final response = await _apiClient.get('/tool-life/alerts/active');
      final data = response.data;

      if (data['success'] == true) {
        final List<dynamic> alertsJson = data['data']['alerts'];
        return alertsJson.map((json) => ToolAlert.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to get alerts');
      }
    } catch (e) {
      throw Exception('Error fetching alerts: $e');
    }
  }

  Future<void> sendNotification({
    required String alertId,
    required String supervisorEmail,
  }) async {
    try {
      final response = await _apiClient.post(
        '/tool-life/alerts/notify',
        data: {
          'alert_id': alertId,
          'supervisor_email': supervisorEmail,
        },
      );

      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to send notification');
      }
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }

  Future<void> resetTool({
    required int toolId,
    String? maintenanceNotes,
    DateTime? maintenanceDate,
    String? technicianId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/tool-life/$toolId/reset',
        data: {
          'maintenance_notes': maintenanceNotes,
          'maintenance_date': maintenanceDate?.toIso8601String(),
          'technician_id': technicianId,
        },
      );

      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to reset tool');
      }
    } catch (e) {
      throw Exception('Error resetting tool: $e');
    }
  }

  Future<void> createMasterTool({
    required int toolId,
    required String toolName,
    required int toolLifeThreshold,
    String? holderName,
    String? atcPocketNo,
    String? toolRoomNo,
    String? supervisorEmail,
  }) async {
    try {
      final response = await _apiClient.post(
        '/tool-life/master/create',
        data: {
          'tool_id': toolId,
          'tool_name': toolName,
          'tool_life_threshold': toolLifeThreshold,
          'holder_name': holderName,
          'atc_pocket_no': atcPocketNo,
          'tool_room_no': toolRoomNo,
          'supervisor_email': supervisorEmail,
        },
      );

      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to create master tool');
      }
    } catch (e) {
      throw Exception('Error creating master tool: $e');
    }
  }

  Future<List<MasterTool>> getAllMasterTools() async {
    try {
      final response = await _apiClient.get('/tools', queryParameters: {'page': 1, 'limit': 100});
      final data = response.data;

      if (data['success'] == true) {
        final List<dynamic> toolsJson = data['data']['masterTools'];
        return toolsJson.map((json) => MasterTool.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to get master tools');
      }
    } catch (e) {
      throw Exception('Error fetching master tools: $e');
    }
  }

  Future<MasterTool> getMasterTool(int toolId) async {
    try {
      final response = await _apiClient.get('/tool-life/master/$toolId');
      final data = response.data;

      if (data['success'] == true) {
        return MasterTool.fromJson(data['data']['masterTool']);
      } else {
        throw Exception(data['message'] ?? 'Failed to get tool');
      }
    } catch (e) {
      throw Exception('Error fetching tool: $e');
    }
  }

  Future<void> updateMasterTool({
    required int toolId,
    String? toolName,
    String? holderName,
    String? atcPocketNo,
    String? toolRoomNo,
    int? toolLifeThreshold,
    String? supervisorEmail,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/tool-life/master/$toolId',
        data: {
          if (toolName != null) 'tool_name': toolName,
          if (holderName != null) 'holder_name': holderName,
          if (atcPocketNo != null) 'atc_pocket_no': atcPocketNo,
          if (toolRoomNo != null) 'tool_room_no': toolRoomNo,
          if (toolLifeThreshold != null) 'tool_life_threshold': toolLifeThreshold,
          if (supervisorEmail != null) 'supervisor_email': supervisorEmail,
        },
      );

      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update tool');
      }
    } catch (e) {
      throw Exception('Error updating tool: $e');
    }
  }

  Future<void> deleteMasterTool(int toolId) async {
    try {
      final response = await _apiClient.delete('/tool-life/master/$toolId');
      final data = response.data;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete tool');
      }
    } catch (e) {
      throw Exception('Error deleting tool: $e');
    }
  }

  Future<List<ToolUsageLog>> getToolHistory(int toolId) async {
    try {
      final response = await _apiClient.get('/tool-life/$toolId/history');
      final data = response.data;

      if (data['success'] == true) {
        final List<dynamic> logsJson = data['data']['logs'];
        return logsJson.map((json) => ToolUsageLog.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to get tool history');
      }
    } catch (e) {
      throw Exception('Error fetching tool history: $e');
    }
  }
}
