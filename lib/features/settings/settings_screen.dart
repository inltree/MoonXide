import 'package:flutter/material.dart';
import '../../core/services/app_state.dart';
import '../../core/services/signing_store.dart';
import '../../core/catalogs/permission_catalog.dart';
import '../../core/catalogs/dependency_catalog.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../project_identity/project_identity_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;

  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Set<String> selectedPermissions = {};
  final Set<String> selectedDependencies = {};
  final signingStore = SigningStore();
  bool saveToken = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('AI 接口配置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('模型接口、端点、SSE 流式模式'),
              subtitle: const Text('兼容 OpenAI Chat Completions、OpenAI Responses、Anthropic Messages。'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
            ),
          ),
          const SizedBox(height: 24),
          const Text('项目身份配置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('软件图标、名称、包名、版本'),
              subtitle: const Text('用于用户项目的应用身份与发行版本配置。'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectIdentityScreen())),
            ),
          ),
          const SizedBox(height: 24),
          const Text('权限快捷配置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: () => setState(() => selectedPermissions.addAll(PermissionCatalog.android.map((e) => e.name))), child: const Text('全选权限')),
              OutlinedButton(onPressed: () => setState(() => selectedPermissions.clear()), child: const Text('清空权限')),
            ],
          ),
          const SizedBox(height: 8),
          ...PermissionCatalog.android.map((item) => Card(
                child: CheckboxListTile(
                  value: selectedPermissions.contains(item.name),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedPermissions.add(item.name);
                      } else {
                        selectedPermissions.remove(item.name);
                      }
                    });
                  },
                  title: Text(item.name),
                  subtitle: Text(item.description),
                ),
              )),
          const SizedBox(height: 24),
          const Text('Flutter 依赖快捷添加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: () => setState(() => selectedDependencies.addAll(DependencyCatalog.flutter.map((e) => e.packageName))), child: const Text('全选依赖')),
              OutlinedButton(onPressed: () => setState(() => selectedDependencies.clear()), child: const Text('清空依赖')),
            ],
          ),
          const SizedBox(height: 8),
          ...DependencyCatalog.flutter.map((item) => Card(
                child: CheckboxListTile(
                  value: selectedDependencies.contains(item.packageName),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedDependencies.add(item.packageName);
                      } else {
                        selectedDependencies.remove(item.packageName);
                      }
                    });
                  },
                  title: Text(item.name),
                  subtitle: Text('${item.packageName}\n${item.description}'),
                ),
              )),
          const SizedBox(height: 24),
          const Text('签名配置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('配置 keystore / alias / 密码'),
              subtitle: const Text('release 包签名必备，建议存本地加密配置。'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await signingStore.save(keystore: '/sdcard/Download/moonxide.jks', alias: 'moonxide', storePassword: '******', keyPassword: '******');
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('签名配置已保存')));
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('主题与体验', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              title: Text('动态主题与视觉层级'),
              subtitle: Text('根据系统深浅色、项目状态、编译状态进行实时配色切换。'),
            ),
          ),
          SwitchListTile(
            value: saveToken,
            onChanged: (v) => setState(() => saveToken = v),
            title: const Text('自动保存 Token'),
          ),
          ListTile(
            title: const Text('退出登录'),
            onTap: () => widget.state.logout(),
          ),
        ],
      ),
    );
  }
}