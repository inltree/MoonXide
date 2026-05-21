import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../app/mx_widgets.dart';
import '../../core/services/app_state.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../signing/signing_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _pickBackground() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: false);
    final path = r?.files.single.path;
    if (path == null) return;
    await widget.state.setCustomBackground(path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        const MxSectionLabel('账号'),
        MxCard(
          onTap: () => widget.state.logout(),
          child: Row(children: [
            widget.state.avatarUrl == null
                ? CircleAvatar(radius: 18, backgroundColor: scheme.primary.withOpacity(0.12), child: Icon(Icons.person_rounded, color: scheme.primary))
                : CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.state.avatarUrl!)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.state.login == null ? 'GitHub 未登录' : '@${widget.state.login}', style: const TextStyle(fontWeight: FontWeight.w900)),
              Text('点击退出登录', style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5))),
            ])),
            Icon(Icons.logout_rounded, color: scheme.error, size: 20),
          ]),
        ),

        const MxSectionLabel('AI 接口'),
        _SettingRow(
          icon: Icons.auto_awesome_rounded,
          title: '模型接口配置',
          subtitle: 'OpenAI / Anthropic / 自定义端点',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
        ),

        const MxSectionLabel('签名'),
        _SettingRow(
          icon: Icons.security_rounded,
          title: 'Keystore 签名配置',
          subtitle: 'Release 包签名 · 密钥别名 · 密码',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SigningScreen())),
        ),

        const MxSectionLabel('背景'),
        MxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.wallpaper_rounded, color: scheme.primary, size: 18),
              const SizedBox(width: 10),
              const Expanded(child: Text('自定义背景', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
              if (widget.state.customBackgroundPath != null)
                MxIconBtn(icon: Icons.close_rounded, size: 30,
                  onPressed: () => widget.state.setCustomBackground(null)),
            ]),
            if (widget.state.customBackgroundPath != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(widget.state.customBackgroundPath!),
                    height: 80, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.opacity_rounded, size: 14, color: scheme.onSurface.withOpacity(0.45)),
                const SizedBox(width: 6),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: widget.state.bgOpacity,
                      min: 0.1, max: 1.0,
                      onChanged: widget.state.setBgOpacity,
                    ),
                  ),
                ),
                Text('${(widget.state.bgOpacity * 100).round()}%',
                    style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.5))),
              ]),
            ] else ...[
              const SizedBox(height: 10),
              MxButton(label: '选择图片', icon: Icons.image_rounded,
                  onPressed: _pickBackground, filled: false, small: true),
            ],
          ]),
        ),

        
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MxCard(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: scheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.55))),
        ])),
        Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withOpacity(0.3)),
      ]),
    );
  }
}
