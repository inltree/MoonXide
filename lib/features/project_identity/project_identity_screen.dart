import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../app/mx_widgets.dart';
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
  String _selectedTemplate = 'apk_dart';

  static const _templates = {
    'apk_dart': {'name': 'Flutter / Dart APK', 'icon': Icons.flutter_dash, 'desc': 'flutter create → flutter build apk'},
    'apk_kotlin': {'name': 'Android Kotlin APK', 'icon': Icons.android_rounded, 'desc': 'Gradle Kotlin → assembleRelease'},
    'apk_java': {'name': 'Android Java APK', 'icon': Icons.local_cafe_rounded, 'desc': 'Gradle Java → assembleRelease'},
    'native_cpp': {'name': 'C/C++ 原生可执行', 'icon': Icons.memory_rounded, 'desc': 'clang++ main.cpp -o app'},
  };
  String? iconPath;
  String? validation;
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

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
    appName.dispose(); packageName.dispose(); versionName.dispose(); versionCode.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(16), children: [
                Row(children: [
                  MxIconBtn(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('项目身份配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                ]),
                const MxSectionLabel('基础信息'),
                MxTextField(controller: appName, hint: '软件名称'),
                const SizedBox(height: 10),
                MxTextField(controller: packageName, hint: '软件包名，例如 com.example.app'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: MxTextField(controller: versionName, hint: '版本名 1.0.0')),
                  const SizedBox(width: 10),
                  Expanded(child: MxTextField(controller: versionCode, hint: '版本号 1', keyboardType: TextInputType.number)),
                ]),
                const MxSectionLabel('图标'),
                MxCard(child: Row(children: [
                  Icon(Icons.image_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(iconPath ?? '未选择，默认使用 Flutter 生成图标', maxLines: 2, overflow: TextOverflow.ellipsis)),
                  MxButton(label: '选择', onPressed: _pickIcon, small: true, filled: false),
                ])),
if (validation != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(validation!, style: TextStyle(color: scheme.error))),
                const SizedBox(height: 16),
                MxButton(label: '保存配置', icon: Icons.save_rounded, onPressed: _save),

                const MxSectionLabel('编译模板'),
                ..._templates.entries.map((e) {
                  final selected = _selectedTemplate == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTemplate = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primary.withOpacity(0.10)
                            : scheme.surface.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? scheme.primary.withOpacity(0.55) : scheme.onSurface.withOpacity(0.10),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(e.value['icon'] as IconData, size: 18,
                            color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.value['name'] as String,
                              style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                  color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.85))),
                          Text(e.value['desc'] as String,
                              style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.45))),
                        ])),
                        if (selected) Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary),
                      ]),
                    ),
                  );
                }),
              ]
              ]),
      ),
    );
  }
}