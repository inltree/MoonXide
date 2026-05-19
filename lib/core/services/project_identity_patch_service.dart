import '../models/project_identity_config.dart';

class ProjectIdentityPatchService {
  static final _packageRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');
  static final _versionRegex = RegExp(r'^\d+\.\d+\.\d+([+\-][0-9A-Za-z.\-]+)?$');

  String? validate(ProjectIdentityConfig config) {
    if (config.appName.trim().isEmpty) return '软件名称不能为空';
    if (!_packageRegex.hasMatch(config.packageName.trim())) return '包名格式不正确，例如 com.example.app';
    if (!_versionRegex.hasMatch(config.versionName.trim())) return '版本名格式不正确，例如 1.0.0';
    if (config.versionCode < 1) return '版本号必须大于 0';
    return null;
  }

  String patchPubspec(String content, ProjectIdentityConfig config) {
    final version = '${config.versionName}+${config.versionCode}';
    if (RegExp(r'^version:\s*.*$', multiLine: true).hasMatch(content)) {
      return content.replaceFirst(RegExp(r'^version:\s*.*$', multiLine: true), 'version: $version');
    }
    return '$content\nversion: $version\n';
  }

  String patchAndroidManifest(String content, ProjectIdentityConfig config) {
    var next = content;
    if (RegExp(r'android:label="[^"]*"').hasMatch(next)) {
      next = next.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="${_xml(config.appName)}"');
    } else {
      next = next.replaceFirst('<application', '<application android:label="${_xml(config.appName)}"');
    }
    if (config.iconPath != null && config.iconPath!.trim().isNotEmpty) {
      if (RegExp(r'android:icon="[^"]*"').hasMatch(next)) {
        next = next.replaceFirst(RegExp(r'android:icon="[^"]*"'), 'android:icon="@mipmap/ic_launcher"');
      } else {
        next = next.replaceFirst('<application', '<application android:icon="@mipmap/ic_launcher"');
      }
    }
    return next;
  }

  String patchBuildGradle(String content, ProjectIdentityConfig config) {
    var next = content;
    next = next.replaceAllMapped(RegExp(r'namespace\s*=\s*"[^"]+"'), (_) => 'namespace = "${config.packageName}"');
    next = next.replaceAllMapped(RegExp(r'applicationId\s*=\s*"[^"]+"'), (_) => 'applicationId = "${config.packageName}"');
    next = next.replaceAllMapped(RegExp(r'versionCode\s*=\s*\d+'), (_) => 'versionCode = ${config.versionCode}');
    next = next.replaceAllMapped(RegExp(r'versionName\s*=\s*"[^"]+"'), (_) => 'versionName = "${config.versionName}"');
    return next;
  }

  String _xml(String value) => value.replaceAll('&', '&amp;').replaceAll('"', '"').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}