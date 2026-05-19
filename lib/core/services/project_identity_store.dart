import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/project_identity_config.dart';

class ProjectIdentityStore {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/moonxide_project_identity.json');
  }

  Future<ProjectIdentityConfig> load() async {
    final file = await _file();
    if (!await file.exists()) return ProjectIdentityConfig.defaults();
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return ProjectIdentityConfig.defaults();
    return ProjectIdentityConfig.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> save(ProjectIdentityConfig config) async {
    final file = await _file();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(config.toJson()));
  }
}