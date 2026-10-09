import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://localhost:4500";

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

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 201) {
      return true;
    }

    return false;
  }
}