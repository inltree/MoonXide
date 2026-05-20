import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/mx_widgets.dart';
import '../../core/services/app_state.dart';
import '../../core/services/editor_state.dart';
import '../../core/services/local_file_upload_service.dart';
import '../../core/models/repository_file_item.dart';

class WorkspaceScreen extends StatefulWidget {
  final AppState state;
  const WorkspaceScreen({super.key, required this.state});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final repoNameController = TextEditingController();
  final descController = TextEditingController();
  bool creatingPrivate = true;
  bool autoInit = true;
  List<Map<String, dynamic>> repos = [];
  List<RepositoryFileItem> files = [];
  String currentPath = '';
  bool loading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  @override
  void dispose() {
    repoNameController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> _loadRepos() async {
    if (widget.state.github == null) return;
    setState(() { loading = true; message = null; });
    try {
      repos = await widget.state.github!.listRepositories();
    } catch (e) {
      message = '仓库读取失败：$e';
    }
    setState(() => loading = false);
  }

  Future<void> _loadFiles([String path = '']) async {
    final owner = widget.state.selectedOwner;
    final repo  = widget.state.selectedRepo;
    if (owner == null || repo == null || widget.state.github == null) return;
    setState(() { loading = true; message = null; });
    try {
      final data = await widget.state.github!.getContents(owner, repo, path: path);
      files = data.map((e) => RepositoryFileItem(
        path: e['path'] as String,
        name: e['name'] as String,
        isDir: e['type'] == 'dir',
        sha: e['sha'] as String?,
        downloadUrl: e['download_url'] as String?,
      )).toList();
      currentPath = path;
    } catch (e) {
      message = '文件树读取失败：$e';
    }
    setState(() => loading = false);
  }

  Future<void> _createRepo() async {
    if (repoNameController.text.trim().isEmpty || widget.state.github == null) return;
    setState(() => loading = true);
    try {
      final repo  = await widget.state.github!.createRepository(
        name: repoNameController.text.trim(),
        private: creatingPrivate,
        autoInit: autoInit,
        description: descController.text.trim(),
      );
      final owner = repo['owner']['login'] as String;
      final name  = repo['name'] as String;
      widget.state.selectRepository(owner, name);
      await _loadRepos();
      await _loadFiles();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => message = '创建仓库失败：$e');
    }
    setState(() => loading = false);
  }

  Future<void> _openFile(RepositoryFileItem item) async {
    final owner = widget.state.selectedOwner;
    final repo  = widget.state.selectedRepo;
    if (owner == null || repo == null || widget.state.github == null) return;
    setState(() => loading = true);
    try {
      final file    = await widget.state.github!.getFile(owner, repo, item.path);
      final raw     = (file['content'] as String).replaceAll('\n', '');
      final content = utf8.decode(base64Decode(raw));
      if (!mounted) return;
      context.read<EditorState>().openFile(item.path, content);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已打开 ${item.name}')));
    } catch (e) {
      setState(() => message = '打开文件失败：$e');
    }
    setState(() => loading = false);
  }

  Future<void> _uploadLocalFile() async {
    final owner = widget.state.selectedOwner;
    final repo  = widget.state.selectedRepo;
    if (owner == null || repo == null || widget.state.github == null) return;
    setState(() => loading = true);
    try {
      final service = LocalFileUploadService();
      final file    = await service.pickOne();
      if (file == null) { setState(() => loading = false); return; }
      final bytes      = await service.bytesOf(file);
      final targetPath = currentPath.isEmpty ? file.name : '$currentPath/${file.name}';
      await widget.state.github!.putFile(
        owner: owner, repo: repo, path: targetPath,
        message: 'Upload ${file.name} by MoonXide',
        contentBase64: base64Encode(bytes),
      );
      await _loadFiles(currentPath);
    } catch (e) {
      setState(() => message = '上传失败：$e');
    }
    setState(() => loading = false);
  }

  void _showCreateRepoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateRepoSheet(
        nameCtrl: repoNameController,
        descCtrl: descController,
        isPrivate: creatingPrivate,
        autoInit: autoInit,
        onPrivateChanged: (v) => setState(() => creatingPrivate = v),
        onAutoInitChanged: (v) => setState(() => autoInit = v),
        onConfirm: _createRepo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.state.selectedRepo;
    final scheme   = Theme.of(context).colorScheme;
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected != null
                      ? '${widget.state.selectedOwner}/$selected'
                      : '选择仓库',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MxIconBtn(icon: Icons.upload_rounded,   onPressed: _uploadLocalFile,     tooltip: '上传文件', size: 36),
              const SizedBox(width: 4),
              MxIconBtn(icon: Icons.sync_rounded,     onPressed: _loadRepos,           tooltip: '刷新',    size: 36),
              const SizedBox(width: 4),
              MxIconBtn(icon: Icons.add_rounded,      onPressed: _showCreateRepoSheet, tooltip: '新建仓库', size: 36),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(message!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        // 内容
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const MxSectionLabel('仓库'),
              if (repos.isEmpty && !loading)
                const MxEmpty(icon: Icons.folder_off_rounded, label: '没有仓库', hint: '点击 + 创建第一个仓库')
              else
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: repos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final r          = repos[i];
                      final name       = r['name'] as String;
                      final owner      = r['owner']['login'] as String;
                      final isSelected = selected == name;
                      return GestureDetector(
                        onTap: () {
                          widget.state.selectRepository(owner, name);
                          _loadFiles();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 170,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary.withOpacity(0.14)
                                : (isDark ? const Color(0xFF0F2230) : Colors.white).withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary.withOpacity(0.45)
                                  : Colors.white.withOpacity(isDark ? 0.08 : 0.45),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                r['private'] == true ? Icons.lock_rounded : Icons.folder_open_rounded,
                                color: isSelected ? scheme.primary : scheme.onSurface.withOpacity(0.55),
                                size: 18,
                              ),
                              const SizedBox(height: 6),
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isSelected ? scheme.primary : null,
                                  )),
                              Text(
                                r['private'] == true ? '私有' : '公开',
                                style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.45)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const MxSectionLabel('文件'),
              if (currentPath.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_rounded, size: 14, color: scheme.onSurface.withOpacity(0.45)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('/$currentPath',
                            style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.55))),
                      ),
                      GestureDetector(
                        onTap: () => _loadFiles(''),
                        child: Text('根目录',
                            style: TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              if (files.isEmpty && !loading && selected != null)
                const MxEmpty(icon: Icons.description_outlined, label: '目录为空', hint: '上传文件或切换仓库')
              else
                ...files.map((item) => MxCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      onTap: () => item.isDir ? _loadFiles(item.path) : _openFile(item),
                      child: Row(
                        children: [
                          Icon(
                            item.isDir ? Icons.folder_rounded : _fileIcon(item.name),
                            color: item.isDir ? const Color(0xFFF5A623) : scheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(item.path,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.45))),
                              ],
                            ),
                          ),
                          Icon(
                            item.isDir ? Icons.chevron_right_rounded : Icons.open_in_new_rounded,
                            size: 16,
                            color: scheme.onSurface.withOpacity(0.30),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':                    return Icons.flutter_dash;
      case 'kt': case 'java':         return Icons.code_rounded;
      case 'json': case 'yaml': case 'yml': return Icons.data_object_rounded;
      case 'md':                      return Icons.article_rounded;
      case 'png': case 'jpg': case 'jpeg': case 'svg': return Icons.image_rounded;
      default:                        return Icons.insert_drive_file_rounded;
    }
  }
}

// ─── 新建仓库底部弹窗 ─────────────────────────────────────────────────────────
class _CreateRepoSheet extends StatelessWidget {
  const _CreateRepoSheet({
    required this.nameCtrl,
    required this.descCtrl,
    required this.isPrivate,
    required this.autoInit,
    required this.onPrivateChanged,
    required this.onAutoInitChanged,
    required this.onConfirm,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final bool isPrivate;
  final bool autoInit;
  final ValueChanged<bool> onPrivateChanged;
  final ValueChanged<bool> onAutoInitChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF0A1E2E) : Colors.white).withOpacity(0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.10 : 0.55)),
          boxShadow: [BoxShadow(color: const Color(0xFF3B8FC7).withOpacity(0.14), blurRadius: 32, offset: const Offset(0, -8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 拖拽把手
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('新建仓库', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            MxTextField(controller: nameCtrl, hint: '仓库名称', prefix: const Icon(Icons.folder_rounded, size: 18)),
            const SizedBox(height: 10),
            MxTextField(controller: descCtrl, hint: '描述（可选）', prefix: const Icon(Icons.notes_rounded, size: 18)),
            const SizedBox(height: 12),
            _SwitchRow(label: '私有仓库',     value: isPrivate, onChanged: onPrivateChanged),
            _SwitchRow(label: '初始化 README', value: autoInit,  onChanged: onAutoInitChanged),
            const SizedBox(height: 16),
            MxButton(label: '创建并作为工作区', icon: Icons.add_rounded, onPressed: onConfirm),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}