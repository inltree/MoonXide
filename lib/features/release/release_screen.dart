import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/build_center_state.dart';
import '../../core/services/artifact_downloader.dart';
import '../../core/platform/android_installer.dart';

class ReleaseScreen extends StatefulWidget {
  const ReleaseScreen({super.key});

  @override
  State<ReleaseScreen> createState() => _ReleaseScreenState();
}

class _ReleaseScreenState extends State<ReleaseScreen> {
  final tagController = TextEditingController(text: 'v1.0.0');
  final titleController = TextEditingController(text: 'MoonXide Release');
  final bodyController = TextEditingController(text: '由 MoonXide 移动 IDE 发布。');
  bool prerelease = false;
  bool loading = false;
  List<Map<String, dynamic>> releases = [];

  @override
  void dispose() {
    tagController.dispose();
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> _publish(BuildContext context) async {
    final app = context.read<AppState>();
    final owner = app.selectedOwner;
    final repo = app.selectedRepo;
    if (owner == null || repo == null || app.github == null) return;
    setState(() => loading = true);
    try {
      await app.github!.createRelease(owner: owner, repo: repo, tagName: tagController.text.trim(), name: titleController.text.trim(), body: bodyController.text, prerelease: prerelease);
      await _load(context);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发行版已创建')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败：$e')));
    }
    setState(() => loading = false);
  }

  Future<void> _load(BuildContext context) async {
    final app = context.read<AppState>();
    final owner = app.selectedOwner;
    final repo = app.selectedRepo;
    if (owner == null || repo == null || app.github == null) return;
    setState(() => loading = true);
    try {
      releases = await app.github!.listReleases(owner, repo);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('读取发行版失败：$e')));
    }
    setState(() => loading = false);
  }

  Future<void> _downloadAndInstall(BuildContext context) async {
    final app = context.read<AppState>();
    final build = context.read<BuildCenterState>();
    if (build.artifactDownloadUrl == null || app.token == null) return;
    final path = await ArtifactDownloader().download(url: build.artifactDownloadUrl!, token: app.token!, fileName: 'moonxide-artifact.zip');
    build.setArtifact(localPath: path, downloadUrl: build.artifactDownloadUrl);
    await AndroidInstaller().openApk(path);
  }

  @override
  Widget build(BuildContext context) {
    final build = context.watch<BuildCenterState>();
    return Scaffold(
      appBar: AppBar(title: const Text('发行版'), actions: [IconButton(onPressed: () => _load(context), icon: const Icon(Icons.refresh))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loading) const LinearProgressIndicator(),
          Card(
            child: ListTile(
              title: const Text('本地 APK 下载与安装'),
              subtitle: Text(build.artifactLocalPath ?? build.artifactDownloadUrl ?? '暂无构建产物'),
              trailing: IconButton(icon: const Icon(Icons.install_mobile), onPressed: build.artifactDownloadUrl == null ? null : () => _downloadAndInstall(context)),
            ),
          ),
          const Divider(),
          const Text('发布到 GitHub Releases', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: tagController, decoration: const InputDecoration(labelText: '版本标签，例如 v1.0.0', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: titleController, decoration: const InputDecoration(labelText: '发行版标题', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: bodyController, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: '版本说明', border: OutlineInputBorder())),
          SwitchListTile(value: prerelease, onChanged: (v) => setState(() => prerelease = v), title: const Text('预发布版本')),
          FilledButton(onPressed: () => _publish(context), child: const Text('创建发行版')),
          const Divider(),
          const Text('历史发行版', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ...releases.map((r) => Card(
                child: ListTile(
                  title: Text(r['name']?.toString() ?? r['tag_name']?.toString() ?? '未命名发行版'),
                  subtitle: Text(r['html_url']?.toString() ?? ''),
                  trailing: r['prerelease'] == true ? const Chip(label: Text('预发布')) : const Chip(label: Text('正式')),
                ),
              )),
        ],
      ),
    );
  }
}