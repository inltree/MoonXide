import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_state.dart';

import 'package:flutter/material.dart';

class _GitHubLogo extends StatelessWidget {
  const _GitHubLogo({this.width = 44, this.height = 44, this.color});
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? Colors.white : Colors.black);
    final hexColor = '#${c.value.toRadixString(16).substring(2).padLeft(6, '0')}';
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GitHubLogoPainter(c),
      ),
    );
  }
}

class _GitHubLogoPainter extends CustomPainter {
  const _GitHubLogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // 缩放路径至目标画布大小
    final scaleX = size.width / 16.0;
    final scaleY = size.height / 16.0;

    // SVG: d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"
    // 用绝对控制点精确绘制路径
    path.moveTo(8 * scaleX, 0 * scaleY);
    path.cubicTo(3.58 * scaleX, 0 * scaleY, 0 * scaleX, 3.58 * scaleY, 0 * scaleX, 8 * scaleY);
    path.cubicTo(0 * scaleX, 11.54 * scaleY, 2.29 * scaleX, 14.53 * scaleY, 5.47 * scaleX, 15.59 * scaleY);
    path.cubicTo(5.87 * scaleX, 15.66 * scaleY, 6.02 * scaleX, 15.42 * scaleY, 6.02 * scaleX, 15.21 * scaleY);
    path.cubicTo(6.02 * scaleX, 15.02 * scaleY, 6.01 * scaleX, 14.39 * scaleY, 6.01 * scaleX, 13.72 * scaleY);
    path.cubicTo(3.99 * scaleX, 14.09 * scaleY, 3.47 * scaleX, 13.23 * scaleY, 3.31 * scaleX, 12.78 * scaleY);
    path.cubicTo(3.22 * scaleX, 12.55 * scaleY, 2.83 * scaleX, 11.84 * scaleY, 2.49 * scaleX, 11.65 * scaleY);
    path.cubicTo(2.21 * scaleX, 11.5 * scaleY, 1.81 * scaleX, 11.13 * scaleY, 2.48 * scaleX, 11.12 * scaleY);
    path.cubicTo(3.11 * scaleX, 11.11 * scaleY, 3.56 * scaleX, 11.7 * scaleY, 3.71 * scaleX, 11.94 * scaleY);
    path.cubicTo(4.43 * scaleX, 13.15 * scaleY, 5.58 * scaleX, 12.81 * scaleY, 6.04 * scaleX, 12.6 * scaleY);
    path.cubicTo(6.11 * scaleX, 12.08 * scaleY, 6.32 * scaleX, 11.73 * scaleY, 6.55 * scaleX, 11.53 * scaleY);
    path.cubicTo(4.77 * scaleX, 11.33 * scaleY, 2.91 * scaleX, 10.64 * scaleY, 2.91 * scaleX, 7.58 * scaleY);
    path.cubicTo(2.91 * scaleX, 6.71 * scaleY, 3.22 * scaleX, 5.99 * scaleY, 3.73 * scaleX, 5.43 * scaleY);
    path.cubicTo(3.65 * scaleX, 5.23 * scaleY, 3.37 * scaleX, 4.41 * scaleY, 3.81 * scaleX, 3.31 * scaleY);
    path.cubicTo(3.81 * scaleX, 3.31 * scaleY, 4.48 * scaleX, 3.1 * scaleY, 6.01 * scaleX, 4.13 * scaleY);
    path.cubicTo(6.65 * scaleX, 3.95 * scaleY, 7.33 * scaleX, 3.86 * scaleY, 8.01 * scaleX, 3.86 * scaleY);
    path.cubicTo(8.69 * scaleX, 3.86 * scaleY, 9.37 * scaleX, 3.95 * scaleY, 10.01 * scaleX, 4.13 * scaleY);
    path.cubicTo(11.54 * scaleX, 3.09 * scaleY, 12.21 * scaleX, 3.31 * scaleY, 12.21 * scaleX, 3.31 * scaleY);
    path.cubicTo(12.65 * scaleX, 4.41 * scaleY, 12.37 * scaleX, 5.23 * scaleY, 12.29 * scaleX, 5.43 * scaleY);
    path.cubicTo(12.8 * scaleX, 5.99 * scaleY, 13.11 * scaleX, 6.7 * scaleY, 13.11 * scaleX, 7.58 * scaleY);
    path.cubicTo(13.11 * scaleX, 10.65 * scaleY, 11.24 * scaleX, 11.33 * scaleY, 9.46 * scaleX, 11.53 * scaleY);
    path.cubicTo(9.75 * scaleX, 11.78 * scaleY, 10.0 * scaleX, 12.26 * scaleY, 10.0 * scaleX, 13.01 * scaleY);
    path.cubicTo(10.0 * scaleX, 14.08 * scaleY, 9.99 * scaleX, 14.94 * scaleY, 9.99 * scaleX, 15.21 * scaleY);
    path.cubicTo(9.99 * scaleX, 15.42 * scaleY, 10.14 * scaleX, 15.67 * scaleY, 10.54 * scaleX, 15.59 * scaleY);
    path.cubicTo(13.71 * scaleX, 14.53 * scaleY, 16.0 * scaleX, 11.54 * scaleY, 16.0 * scaleX, 8.0 * scaleY);
    path.cubicTo(16.0 * scaleX, 3.58 * scaleY, 12.42 * scaleX, 0 * scaleY, 8.0 * scaleX, 0 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TokenGateScreen extends StatefulWidget {
  const TokenGateScreen({super.key});

  @override
  State<TokenGateScreen> createState() => _TokenGateScreenState();
}

class _TokenGateScreenState extends State<TokenGateScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _openTokenPage() async {
    final uri = Uri.https('github.com', '/settings/tokens/new', {
      'description': 'MoonXide',
      'scopes': 'repo,workflow,read:user,write:packages,delete_repo',
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开浏览器，请手动访问 GitHub Token 页面')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.token != null && state.token!.isNotEmpty && _ctrl.text.isEmpty) {
      _ctrl.text = state.token!;
    }

    // 图片中背景是纯白色（或者纯黑色，取决于深浅模式，一般以纯白为主风格，这里我们支持主题色或者极简白/极简黑）
    final bgColor = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF5F6368);
    final fieldLabelColor = isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF202124);
    final inputBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderCol = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFDADCE0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),

              // ── 顶部居中的 GitHub Logo ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _GitHubLogo(
                    width: 44,
                    height: 44,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 使用 Token 登录 ──
              Text(
                '使用 Token 登录',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // ── 使用 GitHub Personal Access Token 安全登录并访问您的资源 ──
              Text(
                '使用 GitHub Personal Access Token\n安全登录并访问您的资源',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 48),

              // ── Personal Access Token 标签 ──
              Text(
                'Personal Access Token',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fieldLabelColor,
                ),
              ),
              const SizedBox(height: 8),

              // ── 输入框 ──
              Container(
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol, width: 1.2),
                ),
                child: TextField(
                  controller: _ctrl,
                  obscureText: true,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ghp_••••••••••••••••••••••••',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.25)
                          : Colors.black.withOpacity(0.25),
                      fontFamily: 'monospace',
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Token 以 “ghp_”、“github_pat_” 或 “v1.” 开头 ──
              Text(
                'Token 以 “ghp_”、“github_pat_” 或 “v1.” 开头',
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 48),

              // ── 登录按钮 ──
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: state.loading
                      ? null
                      : () {
                          context.read<AppState>().acceptToken(_ctrl.text.trim());
                        },
                  child: state.loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 您的 Token 将安全存储，仅用于 API 访问 ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: subtitleColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '您的 Token 将安全存储，仅用于 API 访问',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 错误或者状态反馈，优雅提示出来而不在布局里占大卡片
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (state.tokenStatus != null && state.tokenValidated)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.tokenStatus!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 48),

              // ── 如何创建 Token? ──────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: _openTokenPage,
                  style: TextButton.styleFrom(
                    foregroundColor: subtitleColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '如何创建 Token?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF1A73E8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
