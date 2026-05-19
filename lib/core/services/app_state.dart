import 'package:flutter/foundation.dart';
import '../models/build_profile.dart';
import 'github_service.dart';
import 'token_store.dart';

class AppState extends ChangeNotifier {
  final TokenStore tokenStore;
  GithubService? github;

  String? token;
  String? login;
  String? selectedOwner;
  String? selectedRepo;
  bool loading = false;
  String? error;
  BuildProfile buildProfile = BuildProfile.debug;

  AppState({required this.tokenStore});

  Future<void> restore() async {
    token = await tokenStore.readToken();
    if (token == null || token!.isEmpty) return;
    github = GithubService(token: token!);
    try {
      final user = await github!.getCurrentUser();
      login = user['login'] as String?;
      selectedOwner = login;
      notifyListeners();
    } catch (_) {
      await tokenStore.clearToken();
      token = null;
      github = null;
    }
  }

  Future<bool> acceptToken(String value) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final service = GithubService(token: value.trim());
      final user = await service.getCurrentUser();
      token = value.trim();
      github = service;
      login = user['login'] as String?;
      selectedOwner = login;
      await tokenStore.saveToken(token!);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Token 验证失败：$e';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await tokenStore.clearToken();
    token = null;
    github = null;
    login = null;
    selectedOwner = null;
    selectedRepo = null;
    notifyListeners();
  }

  void selectRepository(String owner, String repo) {
    selectedOwner = owner;
    selectedRepo = repo;
    notifyListeners();
  }

  void setBuildProfile(BuildProfile value) {
    buildProfile = value;
    notifyListeners();
  }
}