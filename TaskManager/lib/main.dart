import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // ==========================================
  // --- PHẦN A: QUẢN LÝ TÀI KHOẢN VÀ XÁC THỰC ---
  // ==========================================

  // --- Chức năng 1: Quản lý Token & Headers ---
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<dynamic> getHeaders() async {
    final token = await getToken();
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- Chức năng 2: Đăng nhập ---
  static Future<dynamic> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      String? token = data['token'] ?? data['accessToken'] ??
          data['data']?['token'];
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          token != null) {
        await saveToken(token);
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Đăng nhập thất bại'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 3: Đăng ký ---
  static Future<dynamic> register(String fullName, String email,
      String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? data['error'] ?? 'Đăng ký thất bại'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 4: Xem thông tin cá nhân (Profile) ---
  static Future<dynamic> getProfile() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Không lấy được thông tin cá nhân'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 5: Cập nhật thông tin cá nhân ---
  static Future<dynamic> updateProfile(Map<String, dynamic> userData) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: jsonEncode(userData),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Cập nhật thông tin thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 6: Đổi mật khẩu ---
  static Future<dynamic> changePassword(String oldPassword,
      String newPassword) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/change-password'),
        headers: headers,
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Đổi mật khẩu thành công'};
      }
      return {'success': false, 'message': 'Đổi mật khẩu thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ==========================================
  // --- PHẦN B: QUẢN LÝ CÔNG VIỆC (TASKS) ---
  // ==========================================

  // --- Chức năng 1/B: Lấy danh sách công việc (Hỗ trợ Lọc & Tìm kiếm) ---
  static Future<dynamic> getTasks({
    String? type,
    String? search,
    String? status,
    String? priority,
    String? sortBy,
  }) async {
    try {
      final headers = await getHeaders();
      Map<String, String> queryParams = {};
      if (type != null) queryParams['type'] = type;
      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (sortBy != null) queryParams['sortBy'] = sortBy;

      final uri = Uri.parse('$baseUrl/tasks').replace(
          queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Không thể lấy danh sách công việc'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 2/B: Xem chi tiết 1 công việc ---
  static Future<dynamic> getTaskById(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Không tìm thấy chi tiết công việc'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 3/B: Tạo công việc mới ---
  static Future<dynamic> createTask(Map<String, dynamic> taskData) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode(taskData),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Tạo công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 4/B: Cập nhật công việc ---
  static Future<dynamic> updateTask(String id,
      Map<String, dynamic> taskData) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers,
        body: jsonEncode(taskData),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Cập nhật công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 5/B: Xóa công việc ---
  static Future<dynamic> deleteTask(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Xóa công việc thành công'};
      }
      return {'success': false, 'message': 'Xóa công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng 6/B: Cập nhật nhanh trạng thái công việc ---
  static Future<dynamic> updateTaskStatus(String id, String status) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Cập nhật trạng thái thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ==========================================
  // --- PHẦN C: GIAO VIỆC VÀ CHIA SẺ ---
  // ==========================================

  // --- Chức năng C1.1: Xem danh sách người được giao ---
  static Future<dynamic> getAssignees(String taskId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId/assignees'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'message': 'Không lấy được danh sách giao việc'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng C1.2: Giao việc cho một hoặc nhiều người ---
  static Future<dynamic> assignTask(String taskId, List<String> assigneeIds,
      String? primaryAssigneeId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/assignees'),
        headers: headers,
        body: jsonEncode({
          'assigneeIds': assigneeIds,
          'primaryAssigneeId': primaryAssigneeId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Giao công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng C1.3: Cập nhật người phụ trách chính ---
  static Future<dynamic> updatePrimaryAssignee(String taskId,
      String userId) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/assignees/$userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Cập nhật người phụ trách thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng C1.4: Hủy giao việc cho một người ---
  static Future<dynamic> removeAssignee(String taskId, String userId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId/assignees/$userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Hủy giao việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng C2.1: Chia sẻ công việc với người dùng khác ---
  static Future<dynamic> shareTask(String taskId, String email,
      String role) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/shares'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'role': role,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Chia sẻ công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng C2.2: Xem danh sách người được chia sẻ ---
  static Future<dynamic> getTaskShares(String taskId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId/shares'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Không lấy được danh sách chia sẻ'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng C2.3: Cập nhật quyền truy cập ---
  static Future<dynamic> updateSharePermission(String taskId, String shareId,
      String role) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/shares/$shareId'),
        headers: headers,
        body: jsonEncode({
          'role': role,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Cập nhật quyền thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- Chức năng C2.4: Hủy chia sẻ công việc ---
  static Future<dynamic> revokeShare(String taskId, String shareId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId/shares/$shareId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Hủy chia sẻ thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

// ==========================================
// --- PHẦN D: THÔNG BÁO (NOTIFICATIONS) ---
// ==========================================

// --- Chức năng D1.1: Lấy danh sách thông báo của người dùng ---
  static Future<dynamic> getNotifications({bool? unreadOnly}) async {
    try {
      final headers = await getHeaders();
      Map<String, String> queryParams = {};
      if (unreadOnly != null) queryParams['unreadOnly'] = unreadOnly.toString();

      final uri = Uri.parse('$baseUrl/notifications').replace(
          queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'message': 'Không lấy được danh sách thông báo'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
