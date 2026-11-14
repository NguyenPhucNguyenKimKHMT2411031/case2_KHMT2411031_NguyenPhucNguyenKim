import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<dynamic> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<dynamic> register(String fullName, String email, String password) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'fullName': fullName, 'email': email, 'password': password}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> login(String email, String password) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> getProfile() async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.get(Uri.parse('$baseUrl/auth/profile'), headers: headers);
    return jsonDecode(res.body);
  }
  static Future<dynamic> updateProfile(String fullName, String avatarUrl) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.put(Uri.parse('$baseUrl/auth/profile'), headers: headers, body: jsonEncode({'fullName': fullName, 'avatarUrl': avatarUrl}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> changePassword(String oldPassword, String newPassword) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.put(Uri.parse('$baseUrl/auth/change-password'), headers: headers, body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> forgotPassword(String email) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/forgot-password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> resetPassword(String email, String otp, String newPassword) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/reset-password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> getProjects() async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.get(Uri.parse('$baseUrl/projects'), headers: headers);
    return jsonDecode(res.body);
  }
  static Future<dynamic> getProjectById(String id) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.get(Uri.parse('$baseUrl/projects/$id'), headers: headers);
    return jsonDecode(res.body);
  }
  static Future<dynamic> createProject(String name, String description) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.post(Uri.parse('$baseUrl/projects'), headers: headers, body: jsonEncode({'name': name, 'description': description}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> updateProject(String id, String name, String description) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.put(Uri.parse('$baseUrl/projects/$id'), headers: headers, body: jsonEncode({'name': name, 'description': description}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> deleteProject(String id) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.delete(Uri.parse('$baseUrl/projects/$id'), headers: headers);
    return jsonDecode(res.body);
  }
  static Future<dynamic> addMember(String projectId, String email) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.post(Uri.parse('$baseUrl/projects/$projectId/members'), headers: headers, body: jsonEncode({'email': email}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> removeMember(String projectId, String memberId) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.delete(Uri.parse('$baseUrl/projects/$projectId/members/$memberId'), headers: headers);
    return jsonDecode(res.body);
  }
  static Future<dynamic> getTasks(String projectId, {String search = '', String status = 'All', String priority = 'All', String sortBy = 'createdAt'}) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final uri = Uri.parse('$baseUrl/tasks/project/$projectId').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (status != 'All') 'status': status,
      if (priority != 'All') 'priority': priority,
      'sortBy': sortBy,
    });
    final res = await http.get(uri, headers: headers);
    return jsonDecode(res.body);
  }
  static Future<dynamic> createTask(Map<String, dynamic> data) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.post(Uri.parse('$baseUrl/tasks'), headers: headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }
  static Future<dynamic> updateTaskStatus(String taskId, String status) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.patch(Uri.parse('$baseUrl/tasks/$taskId/status'), headers: headers, body: jsonEncode({'status': status}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> updateTaskPriority(String taskId, String priority) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.patch(Uri.parse('$baseUrl/tasks/$taskId/priority'), headers: headers, body: jsonEncode({'priority': priority}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> updateTaskDates(String taskId, String? startDate, String? dueDate) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.patch(Uri.parse('$baseUrl/tasks/$taskId/dates'), headers: headers, body: jsonEncode({'startDate': startDate, 'dueDate': dueDate}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> assignTaskUsers(String taskId, String emails, String permission) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.post(Uri.parse('$baseUrl/tasks/$taskId/assign'), headers: headers, body: jsonEncode({'emails': emails, 'permission': permission}));
    return jsonDecode(res.body);
  }
  static Future<dynamic> setTaskLead(String taskId, String email) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.patch(Uri.parse('$baseUrl/tasks/$taskId/lead'), headers: headers, body: jsonEncode({'email': email}));
    return jsonDecode(res.body);
  }
}
