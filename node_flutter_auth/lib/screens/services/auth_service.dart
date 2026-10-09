import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:4500';

  // ================= LOGIN =================

  Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'];

      // JWT token save
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      print('LOGIN SUCCESSFUL');
      print('TOKEN SAVED');

      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  // ================= GET PROFILE =================

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to get profile');
    }
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');

    print('LOGOUT SUCCESSFUL');
    print('JWT TOKEN DELETED');
  }
}