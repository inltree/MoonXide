import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/mx_widgets.dart';
import '../../core/services/app_state.dart';
import '../../core/services/editor_state.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  EditorScreenState createState() => EditorScreenState();
}

class EditorScreenState extends State<EditorScreen> {
  final contentController = TextEditingController();
  final searchController  = TextEditingController();
  final replaceController = TextEditingController();
  bool showFind = false;

  @override
  void dispose() {
    contentController.dispose();
    searchController.dispose();
    replaceController.dispose();
    super.dispose();
  }

  void _sync(EditorState state) {
    if (contentController.text != state.currentContent) {
      contentController.text = state.currentContent;
    }
  }

  // ── 公开方法供 HomeScreen 调用 ──────────────────────────────────────────────
  void toggleFind() => setState(() => showFind = !showFind);

  Future<void> save(BuildContext ctx) async {
    final editor = ctx.read<EditorState>();
    final app    = ctx.read<AppState>();
    final owner  = app.selectedOwner;
    final repo   = app.selectedRepo;
    if (owner == null || repo == null || app.github == null ||
        editor.currentPath.isEmpty) return;
    try {
      String? sha;
      try {
        final f = await app.github!.getFile(owner, repo, editor.currentPath);
        sha = f['sha'] as String?;
      } catch (_) {}
      await app.github!.putFile(
        owner: owner,
        repo: repo,
        path: editor.currentPath,
        message: 'Update ${editor.currentPath} by MoonXide',
        contentBase64: base64Encode(utf8.encode(contentController.text)),
        sha: sha,
      );
      editor.openFile(editor.currentPath, contentController.text);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('已保存并提交到 GitHub')));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  void insertText(String text, EditorState editor) {
    final value     = contentController.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end   = selection.isValid ? selection.end   : value.text.length;
    final next  = value.text.replaceRange(start, end, text);
    contentController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: start + text.length));
    editor.updateContent(next);
  }

  void _replace(EditorState editor) {
    if (searchController.text.isEmpty) return;
    final next = contentController.text
        .replaceAll(searchController.text, replaceController.text);
    contentController.text = next;
    editor.updateContent(next);
  }

  // ── 构建 ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _sync(editor);
    final lineCount = contentController.text.isEmpty
        ? 1
        : contentController.text.split('\n').length;

    final gutterBg    = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFEFF4F8);
    final gutterText  = isDark ? const Color(0xFF4A6A80) : const Color(0xFF8A9BAA);
    final editorBg    = isDark ? const Color(0xFF0A1929) : const Color(0xFFFAFDFF);
    final editorText  = isDark ? const Color(0xFFD4E8F5) : const Color(0xFF1A2B38);
    final dividerColor= isDark ? const Color(0xFF1A3448) : const Color(0xFFD8E8F0);

    return Column(
      children: [
        // ── 查找替换栏（可选显示） ────────────────────────────────────────────
        if (showFind)
          Container(
            color: (isDark ? const Color(0xFF0F2230) : Colors.white)
                .withOpacity(0.95),
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                Expanded(
                    child: MxTextField(
                        controller: searchController, hint: '搜索')),
                const SizedBox(width: 8),
                Expanded(
                    child: MxTextField(
                        controller: replaceController, hint: '替换为')),
                const SizedBox(width: 6),
                MxIconBtn(
                    icon: Icons.find_replace_rounded,
                    onPressed: () => _replace(editor),
                    size: 36),
                MxIconBtn(
                    icon: Icons.close_rounded,
                    onPressed: () => setState(() => showFind = false),
                    size: 36),
              ],
            ),
          ),

        // ── 代码编辑区 ────────────────────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 行号栏
              Container(
                width: 52,
                color: gutterBg,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: lineCount,
                  itemBuilder: (_, i) => SizedBox(
                    height: 21.7,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: gutterText)),
                      ),
                    ),
                  ),
                ),
              ),
              // 分割线
              Container(width: 1, color: dividerColor),
              // 代码区
              Expanded(
                child: TextField(
                  controller: contentController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.55,
                      color: editorText),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: editorBg,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.fromLTRB(10, 2, 12, 12),
                    hintText: editor.currentPath.isEmpty
                        ? '打开工作区选择文件'
                        : null,
                    hintStyle: TextStyle(
                        color: editorText.withOpacity(0.3),
                        fontFamily: 'monospace'),
                  ),
                  onChanged: editor.updateContent,
                ),
              ),
            ],
          ),
        ),

        // ── 符号快捷栏 ────────────────────────────────────────────────────────
        _SymbolBar(
            isDark: isDark,
            onInsert: (text) => insertText(text, editor)),
      ],
    );
  }
}

// ─── 符号快捷栏 ───────────────────────────────────────────────────────────────
class _SymbolBar extends StatelessWidget {
  const _SymbolBar({required this.isDark, required this.onInsert});
  final bool isDark;
  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    const symbols = [
      '{', '}', '(', ')', '[', ']', ';', ':', '.', ',',
      '=>', '==', '!=', '&&', '||', '/', '_', '"', "'", '\t'
    ];
    final bg = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFEFF4F8);
    final fg = isDark ? const Color(0xFF8ECFEE) : const Color(0xFF2F6A8C);
    return SafeArea(
      top: false,
      child: Container(
        height: 44,
        color: bg,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          itemCount: symbols.length,
          separatorBuilder: (_, __) => const SizedBox(width: 2),
          itemBuilder: (_, i) {
            final s = symbols[i];
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onInsert(s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s == '\t' ? '⇥' : s,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
