// File: lib/services/tools_service.dart

import '../models/tool_list_model.dart';
import '../utils/api_client.dart';
import 'api_service.dart';

class ToolsService {
  final ApiClient _apiClient = ApiClient();

  /// Upload CSV tool list data via multipart form submission
  Future<Map<String, dynamic>> uploadToolList({
    required String toolName,
    List<int>? csvFileBytes,
    String? csvFilePath,
    String? sheetType,
    String? sheetDisplayName,
    bool overwrite = false,
  }) async {
    if (toolName.isEmpty) {
      throw Exception('Tool name is required');
    }

    if (csvFileBytes == null && (csvFilePath == null || csvFilePath.isEmpty)) {
      throw Exception('Selected CSV file could not be accessed');
    }

    final result = await ApiService.uploadToolList(
      toolName: toolName,
      csvFileBytes: csvFileBytes,
      csvFilePath: csvFilePath,
      sheetType: sheetType,
      sheetDisplayName: sheetDisplayName,
      overwrite: overwrite,
    );

    if (result['success'] == true) {
      return result;
    }

    throw Exception(result['message'] ?? 'Error uploading tool list');
  }

  /// Get tool lists with pagination metadata
  Future<Map<String, dynamic>> getToolLists({
    int page = 1,
    int pageSize = 10,
    String? searchTerm,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': pageSize,
      };
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['search'] = searchTerm;
      }

      final response = await _apiClient.get(
        '/tools',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> toolListsData = data['toolLists'] ?? [];
        final toolLists = toolListsData.map((item) => ToolList.fromMap(item)).toList();
        
        return {
          'toolLists': toolLists,
          'currentPage': data['currentPage'] ?? page,
          'totalPages': data['totalPages'] ?? 1,
          'total': data['total'] ?? toolLists.length,
        };
      } else {
        throw Exception('Failed to fetch tool lists');
      }
    } catch (e) {
      throw Exception('Error fetching tool lists: $e');
    }
  }

  /// Get all tool lists
  Future<List<ToolList>> getAllToolLists({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/tools',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['toolLists'];
        return data.map((item) => ToolList.fromMap(item)).toList();
      } else {
        throw Exception('Failed to fetch tool lists');
      }
    } catch (e) {
      throw Exception('Error fetching tool lists: $e');
    }
  }

  /// Get tool list by ID
  Future<ToolList?> getToolListById(String id) async {
    try {
      final response = await _apiClient.get('/tools/$id');

      if (response.statusCode == 200) {
        final data = response.data['data']['toolList'];
        return ToolList.fromMap(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch tool list');
      }
    } catch (e) {
      throw Exception('Error fetching tool list: $e');
    }
  }

  /// Get tool list by name
  Future<ToolList?> getToolListByName(String toolName) async {
    try {
      final response = await _apiClient.get('/tools/name/$toolName');

      if (response.statusCode == 200) {
        final data = response.data['data']['toolList'];
        return ToolList.fromMap(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch tool list');
      }
    } catch (e) {
      throw Exception('Error fetching tool list: $e');
    }
  }

  /// Delete tool list by ID
  Future<bool> deleteToolList(String id) async {
    try {
      final response = await _apiClient.delete('/tools/$id');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete tool list');
      }
    } catch (e) {
      throw Exception('Error deleting tool list: $e');
    }
  }

  /// Update tool list
  Future<ToolList?> updateToolList({
    required String id,
    required String toolName,
    required List<Map<String, dynamic>> toolData,
  }) async {
    try {
      final cleanedToolData = toolData.map((row) {
        return {
          'slNo': _parseNumber(row['slNo'] ?? 0),
          'atcPocketNo': row['atcPocketNo'] ?? '',
          'toolName': row['toolName'] ?? '',
          'holderName': row['holderName'] ?? '',
          'toolRoomNo': row['toolRoomNo'] ?? '',
          'noOfHolesInComponent': _parseNumber(row['noOfHolesInComponent'] ?? 0),
          'cuttingLength': _parseNumber(row['cuttingLength'] ?? 0),
          'remarks': row['remarks'] ?? '',
          'toolLifeTime': _parseNumber(row['toolLifeTime'] ?? 0),
        };
      }).toList();

      final requestBody = {
        'toolName': toolName,
        'toolData': cleanedToolData,
        'sheetType': 'master',
      };

      final response = await _apiClient.put(
        '/tools/$id',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['toolList'];
        return ToolList.fromMap(data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update tool list');
      }
    } catch (e) {
      throw Exception('Error updating tool list: $e');
    }
  }

  /// Search tool lists by name
  Future<List<ToolList>> searchToolLists(String searchTerm, {int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/tools',
        queryParameters: {
          'search': searchTerm,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['toolLists'];
        return data.map((item) => ToolList.fromMap(item)).toList();
      } else {
        throw Exception('Failed to search tool lists');
      }
    } catch (e) {
      throw Exception('Error searching tool lists: $e');
    }
  }

  /// Get tool lists by user
  Future<List<ToolList>> getToolListsByUser(String userId, {int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/tools/user/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['toolLists'];
        return data.map((item) => ToolList.fromMap(item)).toList();
      } else {
        throw Exception('Failed to fetch user tool lists');
      }
    } catch (e) {
      throw Exception('Error fetching user tool lists: $e');
    }
  }

  /// Batch delete tool lists
  Future<void> batchDeleteToolLists(List<String> ids) async {
    try {
      final response = await _apiClient.delete(
        '/tools',
        data: {'ids': ids},
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to delete tool lists');
      }
    } catch (e) {
      throw Exception('Error batch deleting tool lists: $e');
    }
  }

  /// Helper function to parse numbers
  num _parseNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }
}