import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/editor_state.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final contentController = TextEditingController();
  final searchController = TextEditingController();
  final replaceController = TextEditingController();
  int page = 0;
  static const int pageLines = 300;

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

  List<String> _pageLines(String content) {
    final lines = content.split('\n');
    final start = page * pageLines;
    final end = (start + pageLines).clamp(0, lines.length);
    if (start >= lines.length) return [];
    return lines.sublist(start, end);
  }

  Future<void> _save(BuildContext context, EditorState editor, AppState app) async {
    final owner = app.selectedOwner;
    final repo = app.selectedRepo;
    if (owner == null || repo == null || app.github == null || editor.currentPath.isEmpty) return;
    try {
      String? sha;
      try {
        final file = await app.github!.getFile(owner, repo, editor.currentPath);
        sha = file['sha'] as String?;
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
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存并提交到 GitHub')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }

  void _replace(EditorState editor) {
    final next = contentController.text.replaceAll(searchController.text, replaceController.text);
    contentController.text = next;
    editor.updateContent(next);
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorState>();
    final app = context.watch<AppState>();
    _sync(editor);
    final previewLines = _pageLines(contentController.text);
    return Scaffold(
      appBar: AppBar(
        title: Text(editor.currentPath.isEmpty ? '代码编辑器' : editor.currentPath),
        actions: [
          IconButton(onPressed: () => _save(context, editor, app), icon: const Icon(Icons.save)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: searchController, decoration: const InputDecoration(labelText: '搜索', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: replaceController, decoration: const InputDecoration(labelText: '替换为', border: OutlineInputBorder()))),
                IconButton(onPressed: () => _replace(editor), icon: const Icon(Icons.find_replace)),
              ],
            ),
          ),
          if (contentController.text.split('\n').length > pageLines)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: page > 0 ? () => setState(() => page--) : null, child: const Text('上一页')),
                Text('第 ${page + 1} 页，每页 $pageLines 行'),
                TextButton(onPressed: () => setState(() => page++), child: const Text('下一页')),
              ],
            ),
          Expanded(
            child: editor.currentPath.isEmpty
                ? const Center(child: Text('请先在工作区选择并打开文件'))
                : TextField(
                    controller: contentController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      helperText: '预览分页 ${previewLines.length} 行；编辑区保存完整内容。',
                    ),
                    onChanged: editor.updateContent,
                  ),
          ),
        ],
      ),
    );
  }
}