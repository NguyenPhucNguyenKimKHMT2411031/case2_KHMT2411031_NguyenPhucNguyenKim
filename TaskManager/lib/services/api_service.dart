import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Cấu hình Base URL (Có thể đổi thành localhost nếu chạy Flutter Web)
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // ==========================================
  // --- HÀM AN TOÀN DECODE JSON (Chống crash HTML) ---
  // ==========================================
  static dynamic _safeJsonDecode(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html') ||
        response.body.trim().startsWith('<')) {
      return null;
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // --- PHẦN A: QUẢN LÝ TÀI KHOẢN VÀ XÁC THỰC ---
  // ==========================================

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
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Đăng nhập
  static Future<dynamic> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = _safeJsonDecode(response);
      if (data == null) {
        return {
          'success': false,
          'message': 'Lỗi Server (${response.statusCode}): Trả về HTML 404/500'
        };
      }

      String? token = data['token'] ?? data['accessToken'] ??
          data['data']?['token'];
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          token != null) {
        await saveToken(token);
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ??
            'Đăng nhập thất bại (${response.statusCode})'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Đăng ký
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
      final data = _safeJsonDecode(response);
      if (data == null) {
        return {
          'success': false,
          'message': 'Lỗi Server (${response.statusCode}): Trả về HTML'
        };
      }

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

  // Profile
  static Future<dynamic> getProfile() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Không lấy được thông tin cá nhân'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Cập nhật Profile
  static Future<dynamic> updateProfile(Map<String, dynamic> userData) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: jsonEncode(userData),
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Cập nhật thông tin thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Đổi mật khẩu
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
      final data = _safeJsonDecode(response);

      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Không thể lấy danh sách công việc'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<dynamic> getTaskById(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Không tìm thấy chi tiết công việc'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<dynamic> createTask(Map<String, dynamic> taskData) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode(taskData),
      );
      final data = _safeJsonDecode(response);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Tạo công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<dynamic> updateTask(String id,
      Map<String, dynamic> taskData) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers,
        body: jsonEncode(taskData),
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Cập nhật công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

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

  static Future<dynamic> updateTaskStatus(String id, String status) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Cập nhật trạng thái thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ==========================================
  // --- PHẦN C: GIAO VIỆC VÀ CHIA SẺ ---
  // ==========================================

  static Future<dynamic> getAssignees(String taskId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId/assignees'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': 'Không lấy được danh sách giao việc'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

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
      final data = _safeJsonDecode(response);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Giao công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<dynamic> updatePrimaryAssignee(String taskId,
      String userId) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/assignees/$userId'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Cập nhật người phụ trách thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<dynamic> removeAssignee(String taskId, String userId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId/assignees/$userId'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Hủy giao việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

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
      final data = _safeJsonDecode(response);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Chia sẻ công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<dynamic> getTaskShares(String taskId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId/shares'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Không lấy được danh sách chia sẻ'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

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
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Cập nhật quyền thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<dynamic> revokeShare(String taskId, String shareId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId/shares/$shareId'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Hủy chia sẻ thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ==========================================
  // --- PHẦN D: THÔNG BÁO (NOTIFICATIONS) ---
  // ==========================================

  // --- D1.1: Lấy danh sách thông báo ---
  static Future<dynamic> getNotifications({bool? unreadOnly}) async {
    try {
      final headers = await getHeaders();
      Map<String, String> queryParams = {};
      if (unreadOnly != null) queryParams['unreadOnly'] = unreadOnly.toString();

      final uri = Uri.parse('$baseUrl/notifications').replace(
          queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      final data = _safeJsonDecode(response);

      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': 'Không lấy được danh sách thông báo'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- D1.2: Đánh dấu 1 thông báo là đã đọc ---
  static Future<dynamic> markAsRead(String notificationId) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': 'Cập nhật trạng thái thông báo thất bại'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

// --- D1.3: Đánh dấu tất cả thông báo là đã đọc ---
  static Future<dynamic> markAllAsRead() async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': 'Không thể đánh dấu tất cả thông báo là đã đọc (${response
            .statusCode})'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<dynamic> getUnreadNotificationCount() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: headers,
      );
      final data = _safeJsonDecode(response);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': 'Không thể đếm thông báo chưa đọc (${response.statusCode})'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}