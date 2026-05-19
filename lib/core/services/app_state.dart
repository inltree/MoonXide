import 'dart:io';
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
    } on SocketException catch (e) {
      if (_isDnsFailure(e)) {
        notifyListeners();
        return;
      }
      await tokenStore.clearToken();
      token = null;
      github = null;
    } catch (_) {
      await tokenStore.clearToken();
      token = null;
      github = null;
    }
  }

  Future<bool> acceptToken(String value) async {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      error = '请先填写 GitHub Token';
      notifyListeners();
      return false;
    }
    loading = true;
    error = null;
    notifyListeners();
    final service = GithubService(token: cleaned);
    try {
      final user = await service.getCurrentUser();
      token = cleaned;
      github = service;
      login = user['login'] as String?;
      selectedOwner = login;
      await tokenStore.saveToken(token!);
      loading = false;
      notifyListeners();
      return true;
    } on SocketException catch (e) {
      if (_isDnsFailure(e)) {
        await _acceptOffline(cleaned, service);
        return true;
      }
      error = '网络连接失败：${e.message}';
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final message = e.toString();
      if (_isOfflineError(message)) {
        await _acceptOffline(cleaned, service);
        return true;
      }
      error = 'Token 验证失败：$e';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  bool _isDnsFailure(SocketException e) {
    final message = e.message.toLowerCase();
    return e.osError?.errorCode == 7 || message.contains('failed host lookup') || message.contains('主机查找失败') || message.contains('no address associated');
  }

  bool _isOfflineError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('socketexception') &&
        lower.contains('api.github.com') &&
        (lower.contains('主机查找失败') || lower.contains('failed host lookup') || lower.contains('no address associated') || lower.contains('network is unreachable'));
  }

  Future<void> _acceptOffline(String cleaned, GithubService service) async {
    token = cleaned;
    github = service;
    login = null;
    selectedOwner = null;
    await tokenStore.saveToken(token!);
    error = null;
    loading = false;
    notifyListeners();
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