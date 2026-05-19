import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ai/ai_api_mode.dart';
import '../../core/ai/ai_config_state.dart';
import '../../core/ai/ai_api_client.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final baseController = TextEditingController();
  final pathController = TextEditingController();
  final keyController = TextEditingController();
  final modelController = TextEditingController();
  final temperatureController = TextEditingController();
  final topPController = TextEditingController();
  final maxTokensController = TextEditingController();
  final systemController = TextEditingController();
  final testController = TextEditingController(text: '请用一句话回复：接口配置正常。');
  bool synced = false;

  @override
  void dispose() {
    baseController.dispose();
    pathController.dispose();
    keyController.dispose();
    modelController.dispose();
    temperatureController.dispose();
    topPController.dispose();
    maxTokensController.dispose();
    systemController.dispose();
    testController.dispose();
    super.dispose();
  }

  void _sync(AiConfigState state) {
    if (synced || !state.loaded) return;
    final c = state.config;
    baseController.text = c.baseUrl;
    pathController.text = c.endpointPath;
    keyController.text = c.apiKey;
    modelController.text = c.model;
    temperatureController.text = c.temperature;
    topPController.text = c.topP;
    maxTokensController.text = c.maxTokens;
    systemController.text = c.systemPrompt;
    synced = true;
  }

  Future<void> _save(AiConfigState state) async {
    var next = state.config.copyWith(
      baseUrl: baseController.text,
      endpointPath: pathController.text,
      apiKey: keyController.text,
      model: modelController.text,
      temperature: temperatureController.text,
      topP: topPController.text,
      maxTokens: maxTokensController.text,
      systemPrompt: systemController.text,
    );
    next = next.copyWith(
      baseUrl: state.normalizer.normalizeBaseUrl(next.baseUrl),
      endpointPath: state.normalizer.normalizePath(next.endpointPath, next.mode),
    );
    await state.update(next);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI 接口配置已保存')));
  }

  Future<void> _test(AiConfigState state) async {
    await _save(state);
    try {
      final body = await AiApiClient().send(state.config, testController.text);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('测试响应'),
            content: SingleChildScrollView(child: SelectableText(body)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('测试失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AiConfigState>();
    _sync(state);
    final actual = state.normalizer.actualUrl(baseUrl: baseController.text, endpointPath: pathController.text, mode: state.config.mode);
    return Scaffold(
      appBar: AppBar(title: const Text('AI 接口设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<AiApiMode>(
            value: state.config.mode,
            decoration: const InputDecoration(labelText: '接口模式', border: OutlineInputBorder()),
            items: AiApiMode.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
            onChanged: (v) async {
              if (v == null) return;
              pathController.text = v.defaultPath;
              await state.setMode(v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: baseController,
            decoration: InputDecoration(
              labelText: '请求地址 / 域名',
              hintText: 'api.openai.com 或 https://api.openai.com',
              helperText: actual.isEmpty ? '实际请求地址会显示在这里' : '实际请求地址：$actual',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            onEditingComplete: () {
              baseController.text = state.normalizer.normalizeBaseUrl(baseController.text);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pathController,
            decoration: InputDecoration(
              labelText: 'API 端点',
              hintText: state.config.mode.defaultPath,
              helperText: actual.isEmpty ? '可自定义端点；为空时使用当前模式默认端点' : '实际请求地址：$actual',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(controller: keyController, obscureText: true, decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: modelController, decoration: const InputDecoration(labelText: '模型名', hintText: 'gpt-4o-mini / claude-3-5-sonnet-latest / 自定义模型', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: temperatureController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'temperature，空则不传', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: topPController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'top_p，空则不传', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: maxTokensController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'max_tokens，空则不传', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: systemController, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: '系统提示词，空则不传', border: OutlineInputBorder())),
          SwitchListTile(
            value: state.config.stream,
            onChanged: state.setStream,
            title: const Text('SSE 流式模式'),
            subtitle: const Text('开启后请求体传 stream=true；关闭则不传流式参数。'),
          ),
          const Divider(),
          TextField(controller: testController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: '测试输入', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => _save(state), child: const Text('保存配置')),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: () => _test(state), child: const Text('保存并测试请求')),
        ],
      ),
    );
  }
}