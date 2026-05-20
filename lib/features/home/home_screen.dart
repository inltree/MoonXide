import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/moonxide_theme.dart';
import '../../core/services/app_state.dart';
import '../workspace/workspace_screen.dart';
import '../editor/editor_screen.dart';
import '../chat/chat_screen.dart';
import '../ai_workflow/ai_workflow_screen.dart';
import '../build/build_screen.dart';
import '../release/release_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  static const _items = <_MoonNavItem>[
    _MoonNavItem('工作区', '仓库、文件树与项目入口', Icons.folder_open_rounded),
    _MoonNavItem('编辑器', '代码编辑与提交', Icons.edit_note_rounded),
    _MoonNavItem('AI 对话', '辅助开发、解释与生成', Icons.auto_awesome_rounded),
    _MoonNavItem('AI 工作流', '计划、执行与自动化', Icons.account_tree_rounded),
    _MoonNavItem('云编译', 'Actions、APK 与安装', Icons.cloud_upload_rounded),
    _MoonNavItem('发行版', 'Release 与制品发布', Icons.rocket_launch_rounded),
    _MoonNavItem('设置', '接口、身份与环境配置', Icons.tune_rounded),
  ];

  void _select(int value) {
    setState(() => index = value);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final screens = [
      WorkspaceScreen(state: state),
      const EditorScreen(),
      const ChatScreen(),
      const AiWorkflowScreen(),
      BuildScreen(state: state),
      const ReleaseScreen(),
      SettingsScreen(state: state),
    ];
    final item = _items[index];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.label),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.58),
              ),
            ),
          ],
        ),
      ),
      drawer: _MoonXideDrawer(
        selectedIndex: index,
        items: _items,
        onSelect: _select,
        login: state.login,
        repo: state.selectedOwner == null || state.selectedRepo == null
            ? null
            : '${state.selectedOwner}/${state.selectedRepo}',
      ),
      body: _FrostedMountainShell(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 72),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(index),
                child: screens[index],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoonNavItem {
  const _MoonNavItem(this.label, this.subtitle, this.icon);

  final String label;
  final String subtitle;
  final IconData icon;
}

class _MoonXideDrawer extends StatelessWidget {
  const _MoonXideDrawer({
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
    required this.login,
    required this.repo,
  });

  final int selectedIndex;
  final List<_MoonNavItem> items;
  final ValueChanged<int> onSelect;
  final String? login;
  final String? repo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.82),
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.55))),
              boxShadow: const [
                BoxShadow(color: Color(0x263B8FC7), blurRadius: 34, offset: Offset(12, 0)),
              ],
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                children: [
                  _DrawerHeaderCard(login: login, repo: repo),
                  const SizedBox(height: 18),
                  Text(
                    '功能导航',
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.54),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < items.length; i++)
                    _DrawerNavTile(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(i);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeaderCard extends StatelessWidget {
  const _DrawerHeaderCard({required this.login, required this.repo});

  final String? login;
  final String? repo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.86),
            MoonXideTheme.ice.withOpacity(0.76),
            MoonXideTheme.frost.withOpacity(0.62),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
        boxShadow: const [BoxShadow(color: Color(0x223B8FC7), blurRadius: 28, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                ),
                child: Icon(Icons.terrain_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MoonXide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text('Snow Alpine IDE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(login == null || login!.isEmpty ? 'GitHub 已接入' : '@$login', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            repo == null || repo!.isEmpty ? '选择仓库后开始开发' : repo!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurface.withOpacity(0.58), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({required this.item, required this.selected, required this.onTap});

  final _MoonNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: selected ? scheme.primary.withOpacity(0.12) : Colors.transparent,
            border: Border.all(color: selected ? Colors.white.withOpacity(0.72) : Colors.transparent),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x183B8FC7), blurRadius: 18, offset: Offset(0, 8))]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: selected ? scheme.primary.withOpacity(0.16) : scheme.surfaceContainerHighest.withOpacity(0.62),
                ),
                child: Icon(item.icon, color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.62)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: TextStyle(fontWeight: selected ? FontWeight.w900 : FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.52)),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.chevron_right_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrostedMountainShell extends StatelessWidget {
  const _FrostedMountainShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF071722), Color(0xFF102B3C), Color(0xFF0A1A26)]
                    : const [Color(0xFFF9FDFF), Color(0xFFEAF7FF), Color(0xFFF7FBFF)],
              ),
            ),
          ),
        ),
        Positioned(top: -90, right: -70, child: _GlowBlob(size: 220, color: const Color(0xFF9CD8FF).withOpacity(isDark ? 0.16 : 0.30))),
        Positioned(top: 150, left: -100, child: _GlowBlob(size: 260, color: const Color(0xFFD9F2FF).withOpacity(isDark ? 0.10 : 0.48))),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _MountainPainter(isDark: isDark)),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  const _MountainPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..style = PaintingStyle.fill
      ..color = (isDark ? const Color(0xFF18374A) : const Color(0xFFFFFFFF)).withOpacity(isDark ? 0.22 : 0.68);
    final ridge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = (isDark ? const Color(0xFF8CCDF0) : const Color(0xFFB8DFF4)).withOpacity(isDark ? 0.15 : 0.42);

    final y = size.height * 0.82;
    final path = Path()
      ..moveTo(0, y)
      ..lineTo(size.width * 0.20, y - 78)
      ..lineTo(size.width * 0.35, y - 22)
      ..lineTo(size.width * 0.52, y - 118)
      ..lineTo(size.width * 0.72, y - 36)
      ..lineTo(size.width, y - 96)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, base);

    final line = Path()
      ..moveTo(0, y)
      ..lineTo(size.width * 0.20, y - 78)
      ..lineTo(size.width * 0.35, y - 22)
      ..lineTo(size.width * 0.52, y - 118)
      ..lineTo(size.width * 0.72, y - 36)
      ..lineTo(size.width, y - 96);
    canvas.drawPath(line, ridge);
  }

  @override
  bool shouldRepaint(covariant _MountainPainter oldDelegate) => oldDelegate.isDark != isDark;
}