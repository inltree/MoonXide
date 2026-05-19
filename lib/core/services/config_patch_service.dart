import 'dart:convert';
import '../models/project_identity_config.dart';
import 'project_identity_patch_service.dart';

class ConfigPatchService {
  String addManifestPermissions(String manifest, Iterable<String> permissions) {
    final existing = permissions.where((p) => !manifest.contains('android:name="$p"')).map((p) => '    <uses-permission android:name="$p" />').join('\n');
    if (existing.isEmpty) return manifest;
    if (manifest.contains('<manifest')) {
      final index = manifest.indexOf('>') + 1;
      return '${manifest.substring(0, index)}\n$existing${manifest.substring(index)}';
    }
    return '$existing\n$manifest';
  }

  String addFlutterDependencies(String pubspec, Iterable<String> packages) {
    final missing = packages.where((p) => !RegExp('^\\s*$p:', multiLine: true).hasMatch(pubspec)).toList();
    if (missing.isEmpty) return pubspec;
    final lines = missing.map((p) => '  $p: any').join('\n');
    final depIndex = pubspec.indexOf('dependencies:');
    if (depIndex < 0) return 'dependencies:\n$lines\n\n$pubspec';
    final insert = pubspec.indexOf('\n', depIndex) + 1;
    return '${pubspec.substring(0, insert)}$lines\n${pubspec.substring(insert)}';
  }

  String applyProjectIdentityToPubspec(String pubspec, ProjectIdentityConfig config) {
    return ProjectIdentityPatchService().patchPubspec(pubspec, config);
  }

  String applyProjectIdentityToAndroidManifest(String manifest, ProjectIdentityConfig config) {
    return ProjectIdentityPatchService().patchAndroidManifest(manifest, config);
  }

  String applyProjectIdentityToBuildGradle(String buildGradle, ProjectIdentityConfig config) {
    return ProjectIdentityPatchService().patchBuildGradle(buildGradle, config);
  }

  String? validateProjectIdentity(ProjectIdentityConfig config) {
    return ProjectIdentityPatchService().validate(config);
  }

  String encodeContent(String content) => base64Encode(utf8.encode(content));
}