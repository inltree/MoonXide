import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/models/project_identity_config.dart';
import '../../core/services/project_identity_patch_service.dart';
import '../../core/services/project_identity_store.dart';

class ProjectIdentityScreen extends StatefulWidget {
  const ProjectIdentityScreen({super.key});

  @override
  State<ProjectIdentityScreen> createState() => _ProjectIdentityScreenState();
}

class _ProjectIdentityScreenState extends State<ProjectIdentityScreen> {
  final store = ProjectIdentityStore();
  final patcher = ProjectIdentityPatchService();
  final appName = TextEditingController();
  final packageName = TextEditingController();
  final versionName = TextEditingController();
  final versionCode = TextEditingController();
  String? iconPath;
  String? validation;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await store.load();
    appName.text = config.appName;
    packageName.text = config.packageName;
    versionName.text = config.versionName;
    versionCode.text = config.versionCode.toString();
    iconPath = config.iconPath;
    setState(() => loading = false);
  }

  ProjectIdentityConfig _config() => ProjectIdentityConfig(
        appName: appName.text.trim(),
        packageName: packageName.text.trim(),
        versionName: versionName.text.trim(),
        versionCode: int.tryParse(versionCode.text.trim()) ?? 1,
        iconPath: iconPath,
      );

  Future<void> _pickIcon() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => iconPath = path);
  }

  Future<void> _save() async {
    final config = _config();
    final error = patcher.validate(config);
    setState(() => validation = error);
    if (error != null) return;
    await store.save(config);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('项目身份配置已保存')));
  }

  @override
  void dispose() {
    appName.dispose();
    packageName.dispose();
    versionName.dispose();
    versionCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('项目身份配置')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('用于用户项目的 App 名称、包名、版本和图标配置。MoonXide 会在生成/修改项目配置时使用这些值。'),
                const SizedBox(height: 16),
                TextField(controller: appName, decoration: const InputDecoration(labelText: '软件名称', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: packageName, decoration: const InputDecoration(labelText: '软件包名', hintText: 'com.example.app', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: versionName, decoration: const InputDecoration(labelText: '软件版本名', hintText: '1.0.0', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: versionCode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '软件版本号', hintText: '1', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('软件图标'),
                    subtitle: Text(iconPath ?? '未选择，默认使用 Flutter 生成图标'),
                    trailing: OutlinedButton(onPressed: _pickIcon, child: const Text('选择图片')),
                  ),
                ),
                if (validation != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(validation!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('保存配置')),
              ],
            ),
    );
  }
}