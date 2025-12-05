import 'package:flutter/foundation.dart';
import 'package:hnhsmind_care/pages/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../api_key/api_key.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(); // Removed AuthService dependency

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize auth state from shared preferences
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('user');

      if (userJson != null) {
        _user = User.fromJson(json.decode(userJson));

        // Verify user still exists in database
        final api = ApiPhp(tableName: 'users', whereClause: {'id': _user!.id});

        final response = await api.select();
        if (!response['success'] || response['data'].isEmpty) {
          // User no longer exists in database, log out
          await clearAuthData();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing auth: $e');
      }
      await clearAuthData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LoginResult> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse("https://luvpark.ph/luvtest/login.php");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final res = jsonDecode(response.body);

      if (res["success"]) {
        _user = User.fromJson(res["user"]);
        await _saveAuthData(_user!);
        return LoginResult.success; // Return success status
      } else {
        _error = res["message"];
        return LoginResult.failure; // Return failure status
      }
    } catch (e) {
      _error = "Login failed: $e";
      return LoginResult.error; // Return error status
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register user with ApiPhp
  Future<bool> register(Map<String, dynamic> regParam) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final checkApi = ApiPhp(
        tableName: 'users',
        whereClause: {'email': regParam["email"]},
      );

      final checkResponse = await checkApi.select();

      if (checkResponse['success'] &&
          checkResponse['data'] is List &&
          checkResponse['data'].isNotEmpty) {
        _error = 'Email already registered';
        return false;
      }

      // Register new user
      regParam["created_at"] = DateTime.now().toIso8601String();
      final registerApi = ApiPhp(tableName: 'users', parameters: regParam);

      final response = await registerApi.insert();
      if (response['success']) {
        // Auto-login after successful registration
        _error = null;
        return true;
      } else {
        _error = 'Registration failed: ${response['message']}';
        return false;
      }
    } catch (e) {
      _error = 'Registration error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await clearAuthData();
      _user = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final api = ApiPhp(
        tableName: 'users',
        parameters: updates,
        whereClause: {'id': _user!.id},
      );

      final response = await api.update();

      if (response['success']) {
        // Update local user data
        _user = User.fromJson({..._user!.toJson(), ...updates});

        // Update shared preferences
        await _saveAuthData(_user!);

        notifyListeners();
        return true;
      } else {
        _error = 'Update failed: ${response['message']}';
        return false;
      }
    } catch (e) {
      _error = 'Update error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save auth data to shared preferences
  Future<void> _saveAuthData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
  }

  Future<dynamic> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');

    return data == null ? null : jsonDecode(data);
  }

  // Clear auth data from shared preferences
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}

class User {
  final String id;
  final String username;
  final String email;
  final String? mobileNo;
  final String? dateOfBirth;
  final String? address;
  final String? role;
  final String? roleId;
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.mobileNo,
    this.dateOfBirth,
    this.role,
    this.address,
    this.roleId,
    required this.createdAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      mobileNo: json['mobile_no'],
      dateOfBirth: json['birth_date'],
      address: json['address'],
      role: json['role_id'].toString() == "1" ? "Admin" : "",
      roleId: json['role_id'].toString(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'mobile_no': mobileNo,
      'birth_date': dateOfBirth,
      'address': address,
      'role': role,
      'role_id': roleId.toString(),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isAdmin {
    // Implement your admin logic here
    // Example: check a role field or email pattern
    return email.endsWith('@admin.com') || username == 'admin';
  }
}
