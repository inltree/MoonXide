import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/build_center_state.dart';
import '../../core/services/artifact_downloader.dart';
import '../../core/services/log_parser.dart';
import '../../core/platform/android_installer.dart';
import '../../core/models/build_profile.dart';

class BuildScreen extends StatelessWidget {
  final AppState state;
  final downloader = const _DownloaderHolder();

  BuildScreen({super.key, required this.state});

  Future<void> _trigger(BuildContext context) async {
    final build = context.read<BuildCenterState>();
    final owner = state.selectedOwner;
    final repo = state.selectedRepo;
    if (owner == null || repo == null || state.github == null) {
      build.setStatus('请先选择仓库');
      return;
    }
    try {
      build.setStatus('正在触发 GitHub Actions...');
      await state.github!.dispatchWorkflow(
        owner: owner,
        repo: repo,
        workflowFile: 'android-apk.yml',
        inputs: {'build_type': state.buildProfile == BuildProfile.debug ? 'debug' : 'release', 'publish_release': 'false', 'release_tag': 'latest'},
      );
      build.setStatus('已触发构建。');
    } catch (e) {
      build.setStatus('触发失败：$e');
    }
  }

  Future<void> _poll(BuildContext context) async {
    final build = context.read<BuildCenterState>();
    final owner = state.selectedOwner;
    final repo = state.selectedRepo;
    if (owner == null || repo == null || state.github == null) return;
    try {
      build.setStatus('正在读取最新构建...');
      final runs = await state.github!.listWorkflowRuns(owner, repo);
      if (runs.isEmpty) {
        build.setStatus('没有构建记录');
        return;
      }
      final run = runs.first;
      final status = run['status'];
      final conclusion = run['conclusion'];
      final htmlUrl = run['html_url'];
      build.setStatus('状态：$status / 结果：${conclusion ?? '运行中'}\n$htmlUrl');
      if (status == 'completed' && conclusion == 'success') {
        final artifacts = await state.github!.listArtifacts(owner, repo, run['id'] as int);
        if (artifacts.isNotEmpty) build.setArtifact(downloadUrl: artifacts.first['archive_download_url'] as String?);
        build.setLog(null);
      }
      if (status == 'completed' && conclusion != 'success') {
        final bytes = await state.github!.downloadRunLogs(owner, repo, run['id'] as int);
        final summary = LogParser().summarize(String.fromCharCodes(bytes));
        build.setLog(summary);
      }
    } catch (e) {
      build.setStatus('读取状态失败：$e');
    }
  }

  Future<void> _download(BuildContext context) async {
    final build = context.read<BuildCenterState>();
    if (build.artifactDownloadUrl == null || state.token == null) return;
    try {
      final path = await ArtifactDownloader().download(url: build.artifactDownloadUrl!, token: state.token!, fileName: 'moonxide-artifact.zip');
      build.setArtifact(localPath: path, downloadUrl: build.artifactDownloadUrl);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已下载到 $path')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下载失败：$e')));
    }
  }

  Future<void> _install(BuildContext context) async {
    final build = context.read<BuildCenterState>();
    if (build.artifactLocalPath == null) return;
    try {
      await AndroidInstaller().openApk(build.artifactLocalPath!);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('安装失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final build = context.watch<BuildCenterState>();
    return Scaffold(
      appBar: AppBar(title: const Text('编译中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('选择构建类型'),
          const SizedBox(height: 8),
          SegmentedButton<BuildProfile>(
            segments: const [ButtonSegment(value: BuildProfile.debug, label: Text('Debug 调试包')), ButtonSegment(value: BuildProfile.release, label: Text('Release 正式包'))],
            selected: {state.buildProfile},
            onSelectionChanged: (value) => state.setBuildProfile(value.first),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => _trigger(context), child: const Text('触发编译')),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: () => _poll(context), child: const Text('查看最新构建状态')),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(build.status))),
          if (build.artifactDownloadUrl != null)
            Card(
              child: Column(children: [
                ListTile(title: const Text('发现 APK 产物'), subtitle: Text(build.artifactDownloadUrl!)),
                ButtonBar(children: [TextButton(onPressed: () => _download(context), child: const Text('下载到本地')), TextButton(onPressed: build.artifactLocalPath == null ? null : () => _install(context), child: const Text('安装'))]),
              ]),
            ),
          if (build.logText != null) Card(child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(build.logText!))),
        ],
      ),
    );
  }
}

class _DownloaderHolder {
  const _DownloaderHolder();
}