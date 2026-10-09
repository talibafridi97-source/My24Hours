import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://localhost:4500";

  // ================= SIGNUP =================

  Future<bool> signup(
      String name,
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/signup"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    print("SIGNUP STATUS: ${response.statusCode}");
    print("SIGNUP RESPONSE: ${response.body}");

    if (response.statusCode == 201) {
      return true;
    }

    return false;
  }

  // ================= LOGIN =================

  Future<Map<String, dynamic>?> login(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // JWT token save karo
      final token = data["token"];

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("token", token);

      print("================================");
      print("LOGIN SUCCESSFUL");
      print("TOKEN SAVED SUCCESSFULLY");
      print("================================");

      return data;
    }

    return null;
  }

  // ================= GET TOKEN =================

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("token");
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");

    print("================================");
    print("LOGOUT SUCCESSFUL");
    print("JWT TOKEN DELETED");
    print("================================");
  }

  // ================= PROFILE =================

  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();

    if (token == null) {
      print("NO TOKEN FOUND");
      return null;
    }

    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("PROFILE STATUS: ${response.statusCode}");
    print("PROFILE RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}