import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future register(String fullName, String email, String password) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'fullName': fullName, 'email': email, 'password': password}));
    return jsonDecode(res.body);
  }

  static Future login(String email, String password) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    return jsonDecode(res.body);
  }

  static Future forgotPassword(String email) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/forgot-password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email}));
    return jsonDecode(res.body);
  }

  static Future resetPassword(String email, String otp, String newPassword) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/reset-password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}));
    return jsonDecode(res.body);
  }

  static Future getProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/users/profile'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future updateProfile(String fullName, [String avatar = '']) async {
    final res = await http.put(Uri.parse('$baseUrl/users/profile'), headers: await _headers(), body: jsonEncode({'fullName': fullName, 'avatar': avatar}));
    return jsonDecode(res.body);
  }

  static Future changePassword(String currentPassword, String newPassword) async {
    final res = await http.put(Uri.parse('$baseUrl/users/change-password'), headers: await _headers(), body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}));
    return jsonDecode(res.body);
  }

  static Future getProjects() async {
    final res = await http.get(Uri.parse('$baseUrl/projects'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future getProjectById(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/projects/$id'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future createProject(String name, String description) async {
    final res = await http.post(Uri.parse('$baseUrl/projects'), headers: await _headers(), body: jsonEncode({'name': name, 'description': description}));
    return jsonDecode(res.body);
  }

  static Future deleteProject(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/projects/$id'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future getTasks(String projectId, {String search = '', String status = 'All', String priority = 'All', String sortBy = 'createdAt'}) async {
    final uri = Uri.parse('$baseUrl/tasks/project/$projectId').replace(queryParameters: {'search': search, 'status': status, 'priority': priority, 'sortBy': sortBy});
    final res = await http.get(uri, headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future createTask(Map data) async {
    final res = await http.post(Uri.parse('$baseUrl/tasks'), headers: await _headers(), body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  static Future updateTaskStatus(String taskId, String status) async {
    final res = await http.patch(Uri.parse('$baseUrl/tasks/$taskId/status'), headers: await _headers(), body: jsonEncode({'status': status}));
    return jsonDecode(res.body);
  }

  static Future updateTaskPriority(String taskId, String priority) async {
    final res = await http.patch(Uri.parse('$baseUrl/tasks/$taskId/priority'), headers: await _headers(), body: jsonEncode({'priority': priority}));
    return jsonDecode(res.body);
  }

  static Future validateAssignEmails(String taskId, String emails, String permission) async {
    final res = await http.post(Uri.parse('$baseUrl/tasks/$taskId/validate-assign'), headers: await _headers(), body: jsonEncode({'emails': emails, 'permission': permission}));
    return jsonDecode(res.body);
  }

  static Future assignTaskUsers(String taskId, String emails, String permission) async {
    final res = await http.post(Uri.parse('$baseUrl/tasks/$taskId/assign'), headers: await _headers(), body: jsonEncode({'emails': emails, 'permission': permission}));
    return jsonDecode(res.body);
  }

  static Future setLeadAssignee(String taskId, String email) async {
    final res = await http.patch(Uri.parse('$baseUrl/tasks/$taskId/lead'), headers: await _headers(), body: jsonEncode({'email': email}));
    return jsonDecode(res.body);
  }

  static Future shareTask(String taskId, String emails, String permission) async {
    final res = await http.post(Uri.parse('$baseUrl/tasks/$taskId/share'), headers: await _headers(), body: jsonEncode({'emails': emails, 'permission': permission}));
    return jsonDecode(res.body);
  }

  static Future getTaskParticipants(String taskId) async {
    final res = await http.get(Uri.parse('$baseUrl/tasks/$taskId/participants'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future removeTaskParticipant(String taskId, String userId) async {
    final res = await http.delete(Uri.parse('$baseUrl/tasks/$taskId/participants/$userId'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future getNotifications() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future markNotificationRead(String id) async {
    final res = await http.patch(Uri.parse('$baseUrl/notifications/$id/read'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future markAllNotificationsRead() async {
    final res = await http.patch(Uri.parse('$baseUrl/notifications/read-all'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future checkDeadlines() async {
    final res = await http.post(Uri.parse('$baseUrl/notifications/check-deadlines'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future getProjectStats(String projectId) async {
    final res = await http.get(Uri.parse('$baseUrl/tasks/project/$projectId/stats'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future getTaskActivities(String taskId) async {
    final res = await http.get(Uri.parse('$baseUrl/tasks/$taskId/activities'), headers: await _headers());
    return jsonDecode(res.body);
  }
}
