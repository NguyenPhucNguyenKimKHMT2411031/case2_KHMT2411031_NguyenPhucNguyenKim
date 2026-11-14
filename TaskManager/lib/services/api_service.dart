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

  // --- MODULE A ---
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

  // --- MODULE B ---
  static Future<dynamic> getProjects() async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.get(Uri.parse('$baseUrl/projects'), headers: headers);
    return jsonDecode(res.body);
  }

  static Future<dynamic> createProject(String name, String description) async {
    final headers = Map<String, String>.from(await _authHeaders());
    final res = await http.post(Uri.parse('$baseUrl/projects'), headers: headers, body: jsonEncode({'name': name, 'description': description}));
    return jsonDecode(res.body);
  }
}
