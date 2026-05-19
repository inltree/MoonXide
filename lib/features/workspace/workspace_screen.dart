import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Future<void> _loadRepos() async {
    if (widget.state.github == null) return;
    setState(() => loading = true);
    try {
      repos = await widget.state.github!.listRepositories();
      message = null;
    } catch (e) {
      message = '仓库读取失败：$e';
    }
    setState(() => loading = false);
  }

  Future<void> _loadFiles([String path = '']) async {
    final owner = widget.state.selectedOwner;
    final repo = widget.state.selectedRepo;
    if (owner == null || repo == null || widget.state.github == null) return;
    setState(() => loading = true);
    try {
      final data = await widget.state.github!.getContents(owner, repo, path: path);
      files = data
          .map((e) => RepositoryFileItem(
                path: e['path'] as String,
                name: e['name'] as String,
                isDir: e['type'] == 'dir',
                sha: e['sha'] as String?,
                downloadUrl: e['download_url'] as String?,
              ))
          .toList();
      currentPath = path;
      message = null;
    } catch (e) {
      message = '文件树读取失败：$e';
    }
    setState(() => loading = false);
  }

  Future<void> _createRepo() async {
    if (repoNameController.text.trim().isEmpty || widget.state.github == null) return;
    setState(() => loading = true);
    try {
      final repo = await widget.state.github!.createRepository(
        name: repoNameController.text.trim(),
        private: creatingPrivate,
        autoInit: autoInit,
        description: descController.text.trim(),
      );
      final owner = repo['owner']['login'] as String;
      final name = repo['name'] as String;
      widget.state.selectRepository(owner, name);
      await _loadRepos();
      await _loadFiles();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      message = '创建仓库失败：$e';
    }
    setState(() => loading = false);
  }

  Future<void> _openFile(RepositoryFileItem item) async {
    final owner = widget.state.selectedOwner;
    final repo = widget.state.selectedRepo;
    if (owner == null || repo == null || widget.state.github == null) return;
    setState(() => loading = true);
    try {
      final file = await widget.state.github!.getFile(owner, repo, item.path);
      final raw = (file['content'] as String).replaceAll('\n', '');
      final content = utf8.decode(base64Decode(raw));
      if (!mounted) return;
      context.read<EditorState>().openFile(item.path, content);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已打开 ${item.path}')));
    } catch (e) {
      message = '打开文件失败：$e';
    }
    setState(() => loading = false);
  }

  Future<void> _uploadLocalFile() async {
    final owner = widget.state.selectedOwner;
    final repo = widget.state.selectedRepo;
    if (owner == null || repo == null || widget.state.github == null) return;
    setState(() => loading = true);
    try {
      final service = LocalFileUploadService();
      final file = await service.pickOne();
      if (file == null) {
        setState(() => loading = false);
        return;
      }
      final bytes = await service.bytesOf(file);
      final targetPath = currentPath.isEmpty ? file.name : '$currentPath/${file.name}';
      await widget.state.github!.putFile(
        owner: owner,
        repo: repo,
        path: targetPath,
        message: 'Upload ${file.name} by MoonXide',
        contentBase64: base64Encode(bytes),
      );
      await _loadFiles(currentPath);
      message = '已上传 $targetPath';
    } catch (e) {
      message = '上传失败：$e';
    }
    setState(() => loading = false);
  }

  void _showCreateRepoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('创建 GitHub 仓库', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: repoNameController, decoration: const InputDecoration(labelText: '仓库名称', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descController, decoration: const InputDecoration(labelText: '仓库描述', border: OutlineInputBorder())),
            SwitchListTile(value: creatingPrivate, onChanged: (v) => setState(() => creatingPrivate = v), title: const Text('私有仓库')),
            SwitchListTile(value: autoInit, onChanged: (v) => setState(() => autoInit = v), title: const Text('初始化 README')),
            FilledButton(onPressed: _createRepo, child: const Text('创建并作为工作区')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.state.selectedRepo;
    return Scaffold(
      appBar: AppBar(
        title: const Text('仓库工作区'),
        actions: [
          IconButton(onPressed: _showCreateRepoSheet, icon: const Icon(Icons.add)),
          IconButton(onPressed: _uploadLocalFile, icon: const Icon(Icons.upload_file)),
          IconButton(onPressed: _loadRepos, icon: const Icon(Icons.sync)),
        ],
      ),
      body: Column(
        children: [
          if (loading) const LinearProgressIndicator(),
          if (message != null) Padding(padding: const EdgeInsets.all(8), child: Text(message!, style: const TextStyle(color: Colors.red))),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: repos.length,
              itemBuilder: (_, i) {
                final r = repos[i];
                final name = r['name'] as String;
                final owner = r['owner']['login'] as String;
                return SizedBox(
                  width: 220,
                  child: Card(
                    child: ListTile(
                      selected: selected == name,
                      title: Text(name),
                      subtitle: Text(r['private'] == true ? '私有仓库' : '公开仓库'),
                      onTap: () {
                        widget.state.selectRepository(owner, name);
                        _loadFiles();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: Text('当前路径：/${currentPath.isEmpty ? '' : currentPath}')),
              if (currentPath.isNotEmpty) TextButton(onPressed: () => _loadFiles(''), child: const Text('回到根目录')),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (_, i) {
                final item = files[i];
                return ListTile(
                  leading: Icon(item.isDir ? Icons.folder : Icons.description),
                  title: Text(item.name),
                  subtitle: Text(item.path),
                  onTap: () => item.isDir ? _loadFiles(item.path) : _openFile(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}