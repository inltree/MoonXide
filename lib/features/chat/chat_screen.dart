import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../app/mx_widgets.dart';
import '../../core/ai/ai_api_client.dart';
import '../../core/ai/ai_config_state.dart';
import '../../core/ai/ai_tool_call.dart';
import '../../core/ai/ai_tool_executor.dart';
import '../../core/chat/chat_conversation_state.dart';
import '../../core/chat/chat_message_record.dart';
import '../../core/chat/chat_role.dart';
import '../../core/services/app_state.dart';
import '../../core/services/editor_state.dart';
import '../../core/workflow/ai_task_step_status.dart';
import '../../core/workflow/ai_workflow_engine.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  final List<AiToolCall> _toolCalls = [];
  bool _autoApproveTools = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(ChatConversationState chat, AiConfigState aiConfig, AiWorkflowEngine workflow) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || chat.busy) return;
    _inputCtrl.clear();
    setState(() => _toolCalls.clear());

    // 注入真实步骤执行器
    workflow.setExecutor((title, detail, goal) async {
      final cfg = aiConfig.config;
      if (cfg.baseUrl.trim().isEmpty || cfg.apiKey.trim().isEmpty) return '未配置 AI，跳过步骤。';
      final stepPrompt = '你正在执行开发任务的一个步骤。必须基于真实上下文行动，不要编造文件、编译结果或工具结果。\n\n总目标：$goal\n当前步骤：$title\n步骤说明：$detail\n\n${AiToolExecutor.toolsDescription}\n\n请完成此步骤：需要仓库/代码事实时先输出工具调用 JSON；已有足够信息时直接给出真实结论。';
      final cfgStep = cfg.copyWith(systemPrompt: stepPrompt, stream: false);
      try {
        final raw = await AiApiClient().sendWithHistory(cfgStep, [], goal);
        final reply = _extractReply(raw, false);
        final calls = AiToolExecutor.parseFromText(reply);
        if (calls.isNotEmpty && mounted) {
          setState(() => _toolCalls.addAll(calls));
          final executor = AiToolExecutor(appState: context.read<AppState>(), editorState: context.read<EditorState>());
          final buf = StringBuffer();
          for (var i = 0; i < _toolCalls.length; i++) {
            final c = _toolCalls[i];
            if (c.status != AiToolCallStatus.pending) continue;
            setState(() => _toolCalls[i] = c.copyWith(status: AiToolCallStatus.running));
            final res = await executor.execute(c);
            setState(() => _toolCalls[i] = c.copyWith(status: AiToolCallStatus.completed, result: res));
            buf.writeln(res);
          }
          return '$reply\n\n工具结果：\n${buf.toString()}';
        }
        return reply.isEmpty ? '步骤完成（无输出）' : reply;
      } catch (e) {
        return '步骤执行失败：$e';
      }
    });

    workflow.createTask(text);
    workflow.startAutoRun();
    await chat.sendUserText(text, aiConfig);
    _scrollToBottom();

    try {
      final cfg = aiConfig.config;
      if (cfg.baseUrl.trim().isEmpty || cfg.apiKey.trim().isEmpty) {
        chat.appendAssistantDelta('请先在设置中配置 AI 接口地址和 API Key。');
      } else {
        final history = chat.messages
            .where((m) => !m.taskOpen)
            .map((m) => {'role': m.role == ChatRole.user ? 'user' : 'assistant', 'content': m.content})
            .toList();
        final toolPrompt = '${cfg.systemPrompt}\n\n${AiToolExecutor.toolsDescription}\n必须基于真实工具返回继续，禁止虚构文件内容、构建结果或仓库状态。';
        final cfgWithTools = cfg.copyWith(systemPrompt: toolPrompt);
        final rawBody = await AiApiClient().sendWithHistory(cfgWithTools, history, text);
        final reply = _extractReply(rawBody, cfg.stream);
        if (reply.isNotEmpty) chat.appendAssistantDelta(reply);

        final parsed = AiToolExecutor.parseFromText(reply);
        if (parsed.isNotEmpty) {
          setState(() => _toolCalls.addAll(parsed));
          await chat.addToolResult('检测到 ${parsed.length} 个工具调用，等待执行。');
          final toolSummary = await _handleToolCalls(chat);
          if (toolSummary.trim().isNotEmpty) {
            final followUp = await AiApiClient().sendWithHistory(
              cfgWithTools.copyWith(stream: false),
              [
                ...history,
                {'role': 'assistant', 'content': reply},
                {'role': 'user', 'content': '以下是工具执行结果，请基于结果继续完成任务，必要时继续给出下一步工具调用或直接给出结论：\n\n$toolSummary'},
              ],
              '继续',
            );
            final nextReply = _extractReply(followUp, false);
            if (nextReply.trim().isNotEmpty) {
              chat.appendAssistantDelta('\n\n$nextReply');
              final nextCalls = AiToolExecutor.parseFromText(nextReply);
              if (nextCalls.isNotEmpty) {
                setState(() => _toolCalls.addAll(nextCalls));
                await _handleToolCalls(chat);
              }
            }
          }
        }
      }
    } catch (e) {
      chat.appendAssistantDelta('\n\n请求失败：$e');
    }

    await chat.finishAssistantTask(aiConfig);
    _scrollToBottom();
  }

  String _extractReply(String rawBody, bool stream) {
    if (rawBody.trim().isEmpty) return '';
    if (stream) {
      final buf = StringBuffer();
      for (final line in rawBody.split('\n')) {
        final l = line.trim();
        if (!l.startsWith('data:')) continue;
        final data = l.substring(5).trim();
        if (data == '[DONE]') break;
        try {
          final j = jsonDecode(data) as Map;
          buf.write((j['choices'] as List?)?.first['delta']?['content'] as String? ?? '');
        } catch (_) {}
      }
      return buf.toString();
    }
    try {
      final j = jsonDecode(rawBody) as Map;
      return (j['choices'] as List?)?.first['message']?['content'] as String?
          ?? (j['content'] as List?)?.first['text'] as String?
          ?? rawBody;
    } catch (_) {
      return rawBody;
    }
  }

  Future<String> _handleToolCalls(ChatConversationState chat) async {
    final executor = AiToolExecutor(
      appState: context.read<AppState>(),
      editorState: context.read<EditorState>(),
    );
    final summary = StringBuffer();
    for (var i = 0; i < _toolCalls.length; i++) {
      var call = _toolCalls[i];
      if (!_autoApproveTools) {
        final ok = await _confirmTool(call);
        if (!ok) {
          setState(() => _toolCalls[i] = call.copyWith(status: AiToolCallStatus.denied, error: '用户拒绝执行'));
          await chat.addToolResult('工具 ${call.name} 已被拒绝。');
          continue;
        }
      }
      setState(() => _toolCalls[i] = call.copyWith(status: AiToolCallStatus.running));
      final result = await executor.execute(call);
      summary.writeln('## ${call.name}');
      summary.writeln('参数：${jsonEncode(call.args)}');
      summary.writeln(result);
      summary.writeln();
      final failed = result.startsWith('错误') || result.contains('失败');
      setState(() => _toolCalls[i] = call.copyWith(
        status: failed ? AiToolCallStatus.failed : AiToolCallStatus.completed,
        result: result,
        error: failed ? result : null,
      ));
      final changeSummary = call.name == 'write_file'
          ? '\n\n${_formatFileChange(call, result)}'
          : '';
      await chat.addToolResult('工具：${call.name}\n参数：${jsonEncode(call.args)}\n结果：\n$result$changeSummary');
      _scrollToBottom();
    }
    return summary.toString();
  }

  String _formatFileChange(AiToolCall call, String result) {
    final path = call.args['path'] as String? ?? 'unknown';
    final name = path.split('/').last;
    final content = call.args['content'] as String? ?? '';
    final newLines = content.isEmpty ? 0 : content.split('\n').length;
    final m = RegExp(r'变更统计：\+(\d+)\s+-(\d+)').firstMatch(result);
    final removed = m?.group(2) ?? '?';
    final status = result.startsWith('已写入') ? '代码变更' : '变更失败';
    return '```diff\n$status  $name\n+ $newLines\n- $removed\n```';
  }

  Future<bool> _confirmTool(AiToolCall call) {
    return MxDialog.show(
      context,
      title: '执行 AI 工具？',
      content: '${call.name}\n\n${jsonEncode(call.args)}',
      confirmLabel: '执行',
      cancelLabel: '拒绝',
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
      }
    });
  }

  Future<void> _showHistory(ChatConversationState chat) async {
    final files = await chat.store.listFiles();
    if (!mounted) return;
    MxBottomSheet.show(
      context,
      title: '对话历史',
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: files.isEmpty
              ? const MxEmpty(icon: Icons.history_rounded, label: '暂无历史对话')
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, i) {
                    final f = File(files[i].path);
                    final id = f.uri.pathSegments.last.replaceAll('.txt', '');
                    final stat = f.statSync();
                    return MxCard(
                      child: Row(children: [
                        const Icon(Icons.description_rounded, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(id, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${stat.modified}', style: const TextStyle(fontSize: 11)),
                        ])),
                        MxIconBtn(icon: Icons.open_in_new_rounded, size: 32, onPressed: () { Navigator.pop(context); chat.loadHistoryAsContext(id); }),
                        MxIconBtn(icon: Icons.delete_rounded, size: 32, onPressed: () async { await chat.deleteHistory(id); if (mounted) Navigator.pop(context); }),
                      ]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _stepIcon(AiTaskStepStatus s) {
    switch (s) {
      case AiTaskStepStatus.pending: return Icons.radio_button_unchecked;
      case AiTaskStepStatus.running: return Icons.autorenew_rounded;
      case AiTaskStepStatus.completed: return Icons.check_circle_rounded;
      case AiTaskStepStatus.failed: return Icons.error_rounded;
    }
  }

  Color _stepColor(BuildContext ctx, AiTaskStepStatus s) {
    final scheme = Theme.of(ctx).colorScheme;
    switch (s) {
      case AiTaskStepStatus.pending: return scheme.outline;
      case AiTaskStepStatus.running: return scheme.primary;
      case AiTaskStepStatus.completed: return Colors.green;
      case AiTaskStepStatus.failed: return scheme.error;
    }
  }

  String _planProgressText(dynamic plan) {
    if (plan == null || plan.steps.isEmpty) return '0/0';
    final steps = plan.steps as List;
    final active = steps.indexWhere((e) => e.status == AiTaskStepStatus.running);
    if (active >= 0) return '${active + 1}/${steps.length}';
    final done = steps.where((e) => e.status == AiTaskStepStatus.completed).length;
    return '${done.clamp(0, steps.length)}/${steps.length}';
  }

  Future<void> _showPlanSheet(AiWorkflowEngine workflow) async {
    final plan = workflow.currentPlan;
    if (plan == null) return;
    final scheme = Theme.of(context).colorScheme;
    await MxBottomSheet.show(
      context,
      title: '任务执行',
      children: [
        _PlanCard(
          plan: plan,
          workflow: workflow,
          scheme: scheme,
          stepIcon: _stepIcon,
          stepColor: _stepColor,
          compact: false,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: MxButton(
              label: workflow.running ? '暂停' : '继续',
              icon: workflow.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              filled: false,
              onPressed: () {
                if (workflow.running) {
                  workflow.pause();
                } else {
                  workflow.resume();
                }
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MxButton(
              label: '重置',
              icon: Icons.refresh_rounded,
              filled: false,
              color: scheme.error,
              onPressed: () {
                workflow.reset();
                Navigator.pop(context);
              },
            ),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatConversationState>();
    final aiConfig = context.watch<AiConfigState>();
    final workflow = context.watch<AiWorkflowEngine>();
    final plan = workflow.currentPlan;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 10, 4),
        child: Row(children: [
          _ToolModeChip(value: _autoApproveTools, onChanged: (v) => setState(() => _autoApproveTools = v)),
          const Spacer(),
          MxIconBtn(icon: Icons.add_comment_rounded, onPressed: chat.newConversation, tooltip: '新对话', size: 34),
          MxIconBtn(icon: Icons.manage_search_rounded, onPressed: () => _showHistory(chat), tooltip: '历史', size: 34),
          MxIconBtn(icon: Icons.undo_rounded, onPressed: chat.rollbackLastMessage, tooltip: '撤回', size: 34),
        ]),
      ),
      if (_toolCalls.isNotEmpty)
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            itemCount: _toolCalls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _ToolCallCard(call: _toolCalls[i]),
          ),
        ),
      Expanded(
        child: chat.messages.isEmpty
            ? const MxEmpty(icon: Icons.auto_awesome_rounded, label: '开始对话', hint: '输入问题或开发任务')
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                itemCount: chat.messages.length,
                itemBuilder: (_, i) {
                  final m = chat.messages[i];
                  final isUser = m.role == ChatRole.user;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
                      child: _Bubble(message: m, isUser: isUser, isDark: isDark, scheme: scheme),
                    ),
                  );
                },
              ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (plan != null) ...[
                _PlanCapsule(
                  label: _planProgressText(plan),
                  running: workflow.running,
                  finished: plan.finished,
                  onTap: () => _showPlanSheet(workflow),
                ),
                const SizedBox(height: 6),
              ],
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: _InlineChatInput(
                    controller: _inputCtrl,
                    focusNode: _inputFocus,
                    busy: chat.busy,
                    onSend: () => _send(chat, aiConfig, workflow),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _InlineChatInput extends StatefulWidget {
  const _InlineChatInput({required this.controller, required this.focusNode, required this.busy, required this.onSend});
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final VoidCallback onSend;

  @override
  State<_InlineChatInput> createState() => _InlineChatInputState();
}

class _InlineChatInputState extends State<_InlineChatInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_refresh);
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showSend = widget.focusNode.hasFocus || widget.controller.text.trim().isNotEmpty || widget.busy;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(13, 5, 5, 5),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F2230) : Colors.white).withOpacity(isDark ? 0.78 : 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: widget.focusNode.hasFocus ? scheme.primary.withOpacity(0.42) : scheme.outlineVariant.withOpacity(0.38)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            minLines: 1,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            style: TextStyle(fontSize: 14, color: scheme.onSurface),
            decoration: InputDecoration(
              hintText: '输入开发任务，AI 可规划并调用工具…',
              hintStyle: TextStyle(fontSize: 14, color: scheme.onSurface.withOpacity(0.34)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        AnimatedScale(
          scale: showSend ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: showSend ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: SizedBox(
              width: showSend ? 38 : 0,
              height: 38,
              child: Material(
                color: widget.busy ? scheme.onSurface.withOpacity(0.10) : scheme.primary,
                borderRadius: BorderRadius.circular(19),
                child: InkWell(
                  borderRadius: BorderRadius.circular(19),
                  onTap: widget.busy ? null : widget.onSend,
                  child: Icon(widget.busy ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded, size: 18, color: widget.busy ? scheme.onSurface.withOpacity(0.42) : Colors.white),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PlanCapsule extends StatelessWidget {
  const _PlanCapsule({required this.label, required this.running, required this.finished, required this.onTap});
  final String label;
  final bool running;
  final bool finished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = finished ? Colors.green : (running ? scheme.primary : Colors.orange);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.36)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(finished ? Icons.check_circle_rounded : (running ? Icons.autorenew_rounded : Icons.account_tree_rounded), size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ]),
        ),
      ),
    );
  }
}

class _ToolModeChip extends StatelessWidget {
  const _ToolModeChip({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: value ? scheme.primary.withOpacity(0.13) : scheme.onSurface.withOpacity(0.06), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(value ? Icons.flash_on_rounded : Icons.verified_user_outlined, size: 13, color: value ? scheme.primary : scheme.onSurface.withOpacity(0.55)),
          const SizedBox(width: 4),
          Text(value ? '自动工具' : '工具确认', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: value ? scheme.primary : scheme.onSurface.withOpacity(0.62))),
        ]),
      ),
    );
  }
}

class _ToolCallCard extends StatelessWidget {
  const _ToolCallCard({required this.call});
  final AiToolCall call;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (call.status) {
      AiToolCallStatus.pending => Colors.orange,
      AiToolCallStatus.running => scheme.primary,
      AiToolCallStatus.approved => scheme.primary,
      AiToolCallStatus.denied => Colors.grey,
      AiToolCallStatus.completed => Colors.green,
      AiToolCallStatus.failed => scheme.error,
    };
    final icon = switch (call.status) {
      AiToolCallStatus.pending => Icons.pending_actions_rounded,
      AiToolCallStatus.running => Icons.autorenew_rounded,
      AiToolCallStatus.approved => Icons.play_circle_rounded,
      AiToolCallStatus.denied => Icons.block_rounded,
      AiToolCallStatus.completed => Icons.check_circle_rounded,
      AiToolCallStatus.failed => Icons.error_rounded,
    };
    return Container(
      width: 210,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.26))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 15, color: color), const SizedBox(width: 6), Expanded(child: Text(call.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)))]),
        const SizedBox(height: 6),
        Text(jsonEncode(call.args), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: scheme.onSurface.withOpacity(0.55), fontFamily: 'monospace')),
        const Spacer(),
        Text(call.result ?? call.error ?? call.status.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: scheme.onSurface.withOpacity(0.55))),
      ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.workflow,
    required this.scheme,
    required this.stepIcon,
    required this.stepColor,
    this.compact = true,
  });
  final dynamic plan;
  final AiWorkflowEngine workflow;
  final ColorScheme scheme;
  final IconData Function(AiTaskStepStatus) stepIcon;
  final Color Function(BuildContext, AiTaskStepStatus) stepColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final body = MxCard(
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_rounded, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(plan.goal, maxLines: compact ? 1 : 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
          MxBadge(plan.finished ? '已完成' : (workflow.running ? '执行中' : '已暂停'), color: plan.finished ? Colors.green : (workflow.running ? scheme.primary : Colors.orange)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: plan.steps.isEmpty ? 0 : plan.steps.where((e) => e.status == AiTaskStepStatus.completed).length / plan.steps.length,
            minHeight: 3,
            backgroundColor: scheme.primary.withOpacity(0.10),
          ),
        ),
        const SizedBox(height: 8),
        ...plan.steps.map<Widget>((step) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(stepIcon(step.status), size: 14, color: stepColor(context, step.status)),
            const SizedBox(width: 7),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(step.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurface.withOpacity(0.76))),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(step.detail, style: TextStyle(fontSize: 11, height: 1.35, color: scheme.onSurface.withOpacity(0.56))),
                if ((step.result ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text((step.result ?? '').toString(), maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, height: 1.35, color: scheme.onSurface.withOpacity(0.48))),
                ],
              ],
            ])),
          ]),
        )),
      ]),
    );
    return compact ? Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 4), child: body) : body;
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final parts = content.split('[工具返回]');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MarkdownBody(data: parts.first.trim().isEmpty ? '…' : parts.first.trim(), selectable: true, softLineBreak: true),
      for (final raw in parts.skip(1)) ...[
        const SizedBox(height: 8),
        _ToolResultView(raw: raw.trim()),
      ],
    ]);
  }
}

class _ToolResultView extends StatelessWidget {
  const _ToolResultView({required this.raw});
  final String raw;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diff = RegExp(r'```diff\n([\s\S]*?)```').firstMatch(raw)?.group(1)?.trim();
    final title = RegExp(r'工具：([^\n]+)').firstMatch(raw)?.group(1)?.trim() ?? '工具执行';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.16)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.terminal_rounded, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: scheme.primary))),
        ]),
        if (diff != null) ...[
          const SizedBox(height: 8),
          _DiffBadge(diff: diff),
        ] else ...[
          const SizedBox(height: 6),
          Text(raw, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, height: 1.35, color: scheme.onSurface.withOpacity(0.60))),
        ],
      ]),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.diff});
  final String diff;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = diff.split('\n');
    final header = lines.isNotEmpty ? lines.first : '代码变更 unknown';
    final plus = lines.firstWhere((e) => e.trim().startsWith('+'), orElse: () => '+ ?').replaceFirst('+', '').trim();
    final minus = lines.firstWhere((e) => e.trim().startsWith('-'), orElse: () => '- ?').replaceFirst('-', '').trim();
    final file = header.split(RegExp(r'\s+')).last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.74),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(children: [
        Icon(Icons.difference_rounded, size: 15, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(file, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
        Text('+$plus', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.green)),
        const SizedBox(width: 8),
        Text('-$minus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: scheme.error)),
      ]),
    );
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({required this.message, required this.isUser, required this.isDark, required this.scheme});
  final ChatMessageRecord message;
  final bool isUser;
  final bool isDark;
  final ColorScheme scheme;
  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: Offset(widget.isUser ? 0.12 : -0.12, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
  }
  @override
  void dispose() { _ac.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: GestureDetector(
            onLongPress: () => Clipboard.setData(ClipboardData(text: widget.message.content)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: widget.isUser ? widget.scheme.primary.withOpacity(0.90) : (widget.isDark ? const Color(0xFF0F2230) : Colors.white).withOpacity(widget.isDark ? 0.88 : 0.92),
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(widget.isUser ? 16 : 4), bottomRight: Radius.circular(widget.isUser ? 4 : 16)),
                border: widget.isUser ? null : Border.all(color: widget.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05)),
              ),
              child: widget.isUser
                  ? SelectableText(widget.message.content.isEmpty ? '…' : widget.message.content, style: const TextStyle(color: Colors.white, fontSize: 14))
                  : _AssistantMessage(content: widget.message.content.isEmpty ? '…' : widget.message.content),
            ),
          ),
        ),
      ),
    );
  }
}
