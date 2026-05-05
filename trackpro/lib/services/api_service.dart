import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String baseUrl = 'https://hkl-backend.onrender.com/api';
  static final supabase = Supabase.instance.client;
  
  // Get unique device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  // Update FCM token
  static Future<Map<String, dynamic>> updateFcmToken(String token) async {
    try {
      final headers = await getHeaders();
      final deviceId = await getDeviceId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/fcm-token'),
        headers: headers,
        body: jsonEncode({
          'token': token,
          'deviceId': deviceId,
          'deviceType': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to update FCM token'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Store token
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Remove token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Get headers with auth token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        await storeToken(data['token']);
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Register user (Admin only)
  static Future<Map<String, dynamic>> registerUser(String name, String username, String password, String role) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'username': username,
          'password': password,
          'role': role,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Get all users
  static Future<List<dynamic>> getUsers() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get users for assignment
  static Future<List<dynamic>> getUsersForAssignment() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/assign'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users for assignment');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Assign task to user
  static Future<Map<String, dynamic>> assignTask(String userId, String task) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/assign-task'),
        headers: headers,
        body: jsonEncode({'assignedTask': task}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'user': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Task assignment failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Assign finishing task with details
  static Future<Map<String, dynamic>> assignFinishingTask({
    required String userId,
    required String productName,
    required String toolListName,
    required dynamic diagramFile,
  }) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/users/$userId/assign-finishing');
      
      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['productName'] = productName;
      request.fields['toolListName'] = toolListName;
      
      if (diagramFile != null) {
        if (kIsWeb && diagramFile.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'diagram',
            diagramFile.bytes!,
            filename: diagramFile.name,
          ));
        } else if (!kIsWeb && diagramFile.path != null) {
          request.files.add(await http.MultipartFile.fromPath('diagram', diagramFile.path!));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'user': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Finishing task assignment failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Unassign task from user
  static Future<Map<String, dynamic>> unassignTask(String userId) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/unassign-task'),
        headers: headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'user': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Task unassignment failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Create inspection
  static Future<Map<String, dynamic>> createInspection(Map<String, dynamic> inspectionData, {File? image}) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/inspections');
      
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add form fields
      inspectionData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      // Add image if provided
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: 'inspection_${DateTime.now().millisecondsSinceEpoch}.png',
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image', image.path));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'inspection': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Inspection creation failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Create finishing record
  static Future<Map<String, dynamic>> createFinishing(Map<String, dynamic> finishingData) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/finishing'),
        headers: headers,
        body: jsonEncode(finishingData),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'finishing': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Finishing record creation failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Update finishing record
  static Future<Map<String, dynamic>> updateFinishing(String id, Map<String, dynamic> finishingData) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/finishing/$id'),
        headers: headers,
        body: jsonEncode(finishingData),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'finishing': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Finishing record update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Create quality control record
  static Future<Map<String, dynamic>> createQualityControl(Map<String, dynamic> qcData, {File? signature}) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/quality');
      
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add form fields
      qcData.forEach((key, value) {
        if (value is Map) {
          // Handle nested objects like holeDimensions and levelReadings
          value.forEach((nestedKey, nestedValue) {
            request.fields['$key.$nestedKey'] = nestedValue.toString();
          });
        } else {
          request.fields[key] = value.toString();
        }
      });
      
      // Add signature if provided
      if (signature != null) {
        if (kIsWeb) {
          final bytes = await signature.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'signatureImage',
            bytes,
            filename: 'signature_${DateTime.now().millisecondsSinceEpoch}.png',
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('signatureImage', signature.path));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'qualityControl': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'QC record creation failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Create delivery record
  static Future<Map<String, dynamic>> createDelivery(Map<String, dynamic> deliveryData, {File? proofImage}) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/delivery');
      
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add form fields
      deliveryData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      // Add proof image if provided
      if (proofImage != null) {
        if (kIsWeb) {
          final bytes = await proofImage.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'deliveryProofImage',
            bytes,
            filename: 'delivery_proof_${DateTime.now().millisecondsSinceEpoch}.png',
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('deliveryProofImage', proofImage.path));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'delivery': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Delivery record creation failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Get dashboard data
  static Future<Map<String, dynamic>> getDashboardData(String role) async {
    try {
      final headers = await getHeaders();
      String endpoint;
      
      switch (role.toLowerCase()) {
        case 'admin':
          endpoint = 'dashboard/admin';
          break;
        case 'supervisor':
          endpoint = 'dashboard/supervisor';
          break;
        default:
          endpoint = 'dashboard/user';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get dashboard stats for admin
  static Future<Map<String, dynamic>> getDashboardStats() async {
    return await getDashboardData('admin');
  }

  // Get dashboard stats for supervisor
  static Future<Map<String, dynamic>> getSupervisorDashboardStats() async {
    return await getDashboardData('supervisor');
  }

  // Get reports
  static Future<Map<String, dynamic>> getReport(String type, {String? startDate, String? endDate}) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/dashboard/reports/$type';
      
      if (startDate != null && endDate != null) {
        url += '?startDate=$startDate&endDate=$endDate';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load report');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Upload CSV tool list
  static Future<Map<String, dynamic>> uploadToolList({
    required String toolName,
    List<int>? csvFileBytes,
    String? csvFilePath,
    String? sheetType,
    String? sheetDisplayName,
    bool overwrite = false,
  }) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/tools/upload');

      final request = http.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['toolName'] = toolName;
      request.fields['overwrite'] = overwrite.toString();

      if (sheetType != null && sheetType.trim().isNotEmpty) {
        request.fields['sheetType'] = sheetType.trim();
      }
      if (sheetDisplayName != null && sheetDisplayName.trim().isNotEmpty) {
        request.fields['sheetDisplayName'] = sheetDisplayName.trim();
      }

      if (csvFileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'csv',
          csvFileBytes,
          filename: sheetDisplayName ?? '$toolName.csv',
        ));
      } else if (csvFilePath != null && csvFilePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('csv', csvFilePath));
      } else {
        return {
          'success': false,
          'message': 'No CSV file data provided for upload.',
        };
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'toolList': data['data']?['toolList'] ?? data['toolList'],
          'sheets': data['data']?['sheets'],
          'totals': data['data']?['totals'],
          'message': data['message'],
          'statusCode': response.statusCode,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Upload failed',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
  
  // Get tool lists
  static Future<List<dynamic>> getToolLists() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tools'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load tool lists');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get tool list by name
  static Future<Map<String, dynamic>> getToolListByName(String toolName) async {
    try {
      final headers = await getHeaders();
      final encodedToolName = Uri.encodeComponent(toolName);
      final response = await http.get(
        Uri.parse('$baseUrl/tools/name/$encodedToolName'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Tool list not found');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get current user profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get active tool life alerts
  static Future<Map<String, dynamic>> getActiveToolAlerts() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tool-life/alerts/active'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'alerts': data['data']['alerts'] ?? []};
      } else {
        return {'success': false, 'alerts': []};
      }
    } catch (e) {
      return {'success': false, 'alerts': []};
    }
  }
  
  // Record tool usage
  static Future<Map<String, dynamic>> recordToolUsage({
    required int toolId,
    required String componentId,
    required int noOfHoles,
    required double cuttingLength,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tool-life/usage/record'),
        headers: headers,
        body: jsonEncode({
          'tool_id': toolId,
          'component_id': componentId,
          'no_of_holes': noOfHoles,
          'cutting_length': cuttingLength,
        }),
      );
      
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Get tool status
  static Future<Map<String, dynamic>> getToolStatus(int toolId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tool-life/$toolId/status'),
        headers: headers,
      );
      
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== TOOL STOCK MANAGEMENT ====================

  // Get all tool stocks
  static Future<Map<String, dynamic>> getToolStocks({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final headers = await getHeaders();
      String url = '$baseUrl/tool-stock?page=$page&limit=$limit';
      
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch tool stocks');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get low stock items
  static Future<Map<String, dynamic>> getLowStockItems() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tool-stock/low-stock'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch low stock items');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get stock statistics
  static Future<Map<String, dynamic>> getStockStatistics() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tool-stock/statistics'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch stock statistics');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get single tool stock
  static Future<Map<String, dynamic>> getToolStock(String stockId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tool-stock/$stockId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Tool stock not found');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Create new tool stock
  static Future<Map<String, dynamic>> createToolStock({
    required String toolName,
    String atcPocketNo = '',
    String toolRoomNo = '',
    required int currentStock,
    int minimumStock = 5,
    int maximumStock = 50,
    int reorderLevel = 10,
    int reorderQuantity = 20,
    String unit = 'pieces',
    String location = 'Tool Room',
    double costPerUnit = 0,
    String notes = '',
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tool-stock'),
        headers: headers,
        body: jsonEncode({
          'toolName': toolName,
          'atcPocketNo': atcPocketNo,
          'toolRoomNo': toolRoomNo,
          'currentStock': currentStock,
          'minimumStock': minimumStock,
          'maximumStock': maximumStock,
          'reorderLevel': reorderLevel,
          'reorderQuantity': reorderQuantity,
          'unit': unit,
          'location': location,
          'costPerUnit': costPerUnit,
          'notes': notes,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create tool stock'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update tool stock
  static Future<Map<String, dynamic>> updateToolStock(
    String stockId, {
    String? toolName,
    String? atcPocketNo,
    String? toolRoomNo,
    int? currentStock,
    int? minimumStock,
    int? maximumStock,
    int? reorderLevel,
    int? reorderQuantity,
    String? unit,
    String? location,
    double? costPerUnit,
    String? notes,
  }) async {
    try {
      final headers = await getHeaders();
      
      final body = <String, dynamic>{};
      if (toolName != null) body['toolName'] = toolName;
      if (atcPocketNo != null) body['atcPocketNo'] = atcPocketNo;
      if (toolRoomNo != null) body['toolRoomNo'] = toolRoomNo;
      if (currentStock != null) body['currentStock'] = currentStock;
      if (minimumStock != null) body['minimumStock'] = minimumStock;
      if (maximumStock != null) body['maximumStock'] = maximumStock;
      if (reorderLevel != null) body['reorderLevel'] = reorderLevel;
      if (reorderQuantity != null) body['reorderQuantity'] = reorderQuantity;
      if (unit != null) body['unit'] = unit;
      if (location != null) body['location'] = location;
      if (costPerUnit != null) body['costPerUnit'] = costPerUnit;
      if (notes != null) body['notes'] = notes;
      
      final response = await http.put(
        Uri.parse('$baseUrl/tool-stock/$stockId'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update tool stock'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete tool stock
  static Future<Map<String, dynamic>> deleteToolStock(String stockId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tool-stock/$stockId'),
        headers: headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Tool stock deleted'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete tool stock'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add stock
  static Future<Map<String, dynamic>> addStock(String stockId, int quantity) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tool-stock/$stockId/add-stock'),
        headers: headers,
        body: jsonEncode({'quantity': quantity}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to add stock'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Remove stock
  static Future<Map<String, dynamic>> removeStock(String stockId, int quantity) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tool-stock/$stockId/remove-stock'),
        headers: headers,
        body: jsonEncode({'quantity': quantity}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to remove stock'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Batch create tool stocks
  static Future<Map<String, dynamic>> batchCreateToolStocks(List<Map<String, dynamic>> tools) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tool-stock/batch'),
        headers: headers,
        body: jsonEncode({'tools': tools}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Batch import failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Test FCM notification
  static Future<Map<String, dynamic>> testNotification() async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/fcm/test-notification'),
        headers: headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Test failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get FCM status
  static Future<Map<String, dynamic>> getFCMStatus() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/fcm/fcm-status'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get FCM status');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}