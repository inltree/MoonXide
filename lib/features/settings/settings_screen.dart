import 'package:flutter/material.dart';
import '../../app/mx_widgets.dart';
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
  final Set<String> _perms = {};
  final Set<String> _deps  = {};
  final _signingStore = SigningStore();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // ── 账号 ──────────────────────────────────────────────────────────
        const MxSectionLabel('账号'),
        MxCard(
          onTap: () => widget.state.logout(),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: scheme.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('退出登录', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      widget.state.login == null ? 'GitHub 未登录' : '@${widget.state.login}',
                      style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withOpacity(0.3)),
            ],
          ),
        ),

        // ── AI 接口 ───────────────────────────────────────────────────────
        const MxSectionLabel('AI 接口'),
        MxCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('模型接口配置', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('OpenAI / Anthropic / 自定义端点', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withOpacity(0.3)),
            ],
          ),
        ),

        // ── 项目身份 ──────────────────────────────────────────────────────
        const MxSectionLabel('项目身份'),
        MxCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectIdentityScreen())),
          child: Row(
            children: [
              Icon(Icons.badge_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('应用名称、包名、版本、图标', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('用于用户项目的发行版本配置', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withOpacity(0.3)),
            ],
          ),
        ),

        // ── 签名 ──────────────────────────────────────────────────────────
        const MxSectionLabel('签名'),
        MxCard(
          onTap: () async {
            await _signingStore.save(
              keystore: '/sdcard/Download/moonxide.jks',
              alias: 'moonxide',
              storePassword: '******',
              keyPassword: '******',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('签名配置已保存')));
            }
          },
          child: Row(
            children: [
              Icon(Icons.security_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keystore 签名配置', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('Release 包签名必备', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withOpacity(0.3)),
            ],
          ),
        ),

        // ── Android 权限 ──────────────────────────────────────────────────
        const MxSectionLabel('Android 权限'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _ActionChip(label: '全选', onTap: () => setState(() => _perms.addAll(PermissionCatalog.android.map((e) => e.name)))),
              _ActionChip(label: '清空', onTap: () => setState(() => _perms.clear())),
            ],
          ),
        ),
        ...PermissionCatalog.android.map((item) => MxCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(item.description, style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _perms.contains(item.name),
                    onChanged: (v) => setState(() => v ? _perms.add(item.name) : _perms.remove(item.name)),
                  ),
                ],
              ),
            )),

        // ── Flutter 依赖 ──────────────────────────────────────────────────
        const MxSectionLabel('Flutter 依赖'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _ActionChip(label: '全选', onTap: () => setState(() => _deps.addAll(DependencyCatalog.flutter.map((e) => e.packageName)))),
              _ActionChip(label: '清空', onTap: () => setState(() => _deps.clear())),
            ],
          ),
        ),
        ...DependencyCatalog.flutter.map((item) => MxCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('${item.packageName}  ·  ${item.description}',
                            style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _deps.contains(item.packageName),
                    onChanged: (v) => setState(() => v ? _deps.add(item.packageName) : _deps.remove(item.packageName)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.primary.withOpacity(0.25)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary)),
      ),
    );
  }
}