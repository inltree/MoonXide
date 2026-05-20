import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/moonxide_theme.dart';
import '../../app/mx_widgets.dart';
import '../../core/services/app_state.dart';
import '../../core/services/editor_state.dart';
import '../workspace/workspace_screen.dart';
import '../editor/editor_screen.dart';
import '../chat/chat_screen.dart';
import '../build/build_screen.dart';
import '../release/release_screen.dart';
import '../settings/settings_screen.dart';

enum _Panel { none, workspace, ai, build, release, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  _Panel _panel = _Panel.none;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _openPanel(_Panel p) {
    if (_panel == p) { _closePanel(); return; }
    setState(() => _panel = p);
    _anim.forward(from: 0);
  }

  void _closePanel() {
    _anim.reverse().then((_) { if (mounted) setState(() => _panel = _Panel.none); });
  }

  Widget _buildPanel(AppState state) {
    switch (_panel) {
      case _Panel.workspace: return WorkspaceScreen(state: state);
      case _Panel.ai:        return const ChatScreen();
      case _Panel.build:     return BuildScreen(state: state);
      case _Panel.release:   return const ReleaseScreen();
      case _Panel.settings:  return SettingsScreen(state: state);
      case _Panel.none:      return const SizedBox.shrink();
    }
  }

  String _panelTitle() {
    switch (_panel) {
      case _Panel.workspace: return '工作区';
      case _Panel.ai:        return 'AI 助手';
      case _Panel.build:     return '云编译';
      case _Panel.release:   return '发行版';
      case _Panel.settings:  return '设置';
      case _Panel.none:      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final editor = context.watch<EditorState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final sw     = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF071722) : MoonXideTheme.snow,
      body: Stack(
        children: [
          // ── 背景光斑 ──────────────────────────────────────────────────────
          Positioned(top: -100, right: -80,
              child: _Blob(size: 260, color: const Color(0xFF9CD8FF).withOpacity(isDark ? 0.12 : 0.26))),
          Positioned(bottom: 60, left: -100,
              child: _Blob(size: 280, color: const Color(0xFFD9F2FF).withOpacity(isDark ? 0.07 : 0.34))),

          // ── 编辑器全屏底层 ────────────────────────────────────────────────
          const Positioned.fill(child: EditorScreen()),

          // ── 面板遮罩 ──────────────────────────────────────────────────────
          if (_panel != _Panel.none)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePanel,
                child: FadeTransition(
                  opacity: _fade,
                  child: ColoredBox(color: Colors.black.withOpacity(0.30)),
                ),
              ),
            ),

          // ── 右侧滑入面板 ──────────────────────────────────────────────────
          if (_panel != _Panel.none)
            Positioned(
              top: 0, right: 0, bottom: 0,
              width: sw * 0.88,
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0), end: Offset.zero,
                  ).animate(_fade),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                      child: Container(
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF0A1E2E) : Colors.white).withOpacity(0.90),
                          border: Border(left: BorderSide(
                              color: Colors.white.withOpacity(isDark ? 0.10 : 0.55))),
                          boxShadow: [BoxShadow(
                              color: const Color(0xFF3B8FC7).withOpacity(0.18),
                              blurRadius: 40, offset: const Offset(-12, 0))],
                        ),
                        child: Column(
                          children: [
                            SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                                child: Row(
                                  children: [
                                    Text(_panelTitle(),
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                                    const Spacer(),
                                    MxIconBtn(icon: Icons.close_rounded,
                                        onPressed: _closePanel, tooltip: '关闭'),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(child: _buildPanel(state)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── 顶部浮层工具栏 ────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Row(
                  children: [
                    // 三横杠 → 工作区
                    MxIconBtn(
                      icon: Icons.menu_rounded,
                      onPressed: () => _openPanel(_Panel.workspace),
                      tooltip: '工作区',
                      active: _panel == _Panel.workspace,
                    ),
                    const SizedBox(width: 8),
                    // 文件名胶囊
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: (isDark ? const Color(0xFF0F2230) : Colors.white)
                                  .withOpacity(0.62),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(isDark ? 0.10 : 0.50)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file_rounded,
                                    size: 14, color: scheme.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    editor.currentPath.isEmpty
                                        ? '未打开文件'
                                        : editor.currentPath,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.onSurface.withOpacity(0.72)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 右侧功能图标
                    MxIconBtn(icon: Icons.auto_awesome_rounded,
                        onPressed: () => _openPanel(_Panel.ai),
                        tooltip: 'AI', active: _panel == _Panel.ai),
                    const SizedBox(width: 4),
                    MxIconBtn(icon: Icons.play_arrow_rounded,
                        onPressed: () => _openPanel(_Panel.build),
                        tooltip: '编译', active: _panel == _Panel.build),
                    const SizedBox(width: 4),
                    MxIconBtn(icon: Icons.rocket_launch_rounded,
                        onPressed: () => _openPanel(_Panel.release),
                        tooltip: '发行', active: _panel == _Panel.release),
                    const SizedBox(width: 4),
                    MxIconBtn(icon: Icons.tune_rounded,
                        onPressed: () => _openPanel(_Panel.settings),
                        tooltip: '设置', active: _panel == _Panel.settings),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 背景光斑 ─────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
      child: Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    );
  }
}