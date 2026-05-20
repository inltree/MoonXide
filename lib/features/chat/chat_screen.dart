import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../app/mx_widgets.dart';
import '../../core/ai/ai_config_state.dart';
import '../../core/chat/chat_conversation_state.dart';
import '../../core/chat/chat_role.dart';
import '../../core/workflow/ai_workflow_engine.dart';
import '../../core/workflow/ai_task_step_status.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showPlan    = true;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(
    ChatConversationState chat,
    AiConfigState aiConfig,
    AiWorkflowEngine workflow,
  ) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || chat.busy) return;
    _inputCtrl.clear();
    workflow.createTask(text);
    workflow.startAutoRun();
    await chat.sendUserText(text, aiConfig);
    await chat.addToolResult(chat.snapshot().asPromptAttachment());
    await chat.finishAssistantTask(aiConfig);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  IconData _stepIcon(AiTaskStepStatus s) {
    switch (s) {
      case AiTaskStepStatus.pending:   return Icons.radio_button_unchecked;
      case AiTaskStepStatus.running:   return Icons.autorenew_rounded;
      case AiTaskStepStatus.completed: return Icons.check_circle_rounded;
      case AiTaskStepStatus.failed:    return Icons.error_rounded;
    }
  }

  Color _stepColor(BuildContext ctx, AiTaskStepStatus s) {
    final scheme = Theme.of(ctx).colorScheme;
    switch (s) {
      case AiTaskStepStatus.pending:   return scheme.outline;
      case AiTaskStepStatus.running:   return scheme.primary;
      case AiTaskStepStatus.completed: return Colors.green;
      case AiTaskStepStatus.failed:    return scheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat     = context.watch<ChatConversationState>();
    final aiConfig = context.watch<AiConfigState>();
    final workflow = context.watch<AiWorkflowEngine>();
    final plan     = workflow.currentPlan;
    final scheme   = Theme.of(context).colorScheme;
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ── 工具栏 ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          child: Row(
            children: [
              MxIconBtn(
                icon: _showPlan ? Icons.account_tree_rounded : Icons.account_tree_outlined,
                onPressed: () => setState(() => _showPlan = !_showPlan),
                tooltip: '任务规划',
                active: _showPlan && plan != null,
                size: 36,
              ),
              const Spacer(),
              MxIconBtn(icon: Icons.undo_rounded,    onPressed: chat.rollbackLastMessage, tooltip: '撤回', size: 36),
              const SizedBox(width: 4),
              MxIconBtn(icon: Icons.refresh_rounded, onPressed: workflow.reset,           tooltip: '重置', size: 36),
            ],
          ),
        ),

        // ── 任务规划面板 ──────────────────────────────────────────────────
        if (_showPlan && plan != null)
          MxCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(plan.goal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    MxBadge(
                      plan.finished ? '已完成' : (workflow.running ? '执行中' : '已暂停'),
                      color: plan.finished ? Colors.green : (workflow.running ? scheme.primary : Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: plan.steps.isEmpty
                        ? 0
                        : plan.steps.where((e) => e.status == AiTaskStepStatus.completed).length /
                            plan.steps.length,
                    minHeight: 4,
                    backgroundColor: scheme.primary.withOpacity(0.12),
                  ),
                ),
                const SizedBox(height: 8),
                ...plan.steps.map((step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(_stepIcon(step.status), size: 14, color: _stepColor(context, step.status)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(step.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withOpacity(0.75),
                                )),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MxButton(label: '暂停', icon: Icons.pause_rounded,      onPressed: workflow.pause,  filled: false, small: true),
                    const SizedBox(width: 8),
                    MxButton(label: '继续', icon: Icons.play_arrow_rounded, onPressed: workflow.resume, filled: false, small: true),
                  ],
                ),
              ],
            ),
          ),

        // ── 消息列表 ──────────────────────────────────────────────────────
        Expanded(
          child: chat.messages.isEmpty
              ? const MxEmpty(icon: Icons.auto_awesome_rounded, label: '开始对话', hint: '输入问题或开发任务')
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  itemCount: chat.messages.length,
                  itemBuilder: (_, i) {
                    final m      = chat.messages[i];
                    final isUser = m.role == ChatRole.user;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft:     const Radius.circular(18),
                              topRight:    const Radius.circular(18),
                              bottomLeft:  Radius.circular(isUser ? 18 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 18),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: isUser
                                  ? scheme.primary.withOpacity(0.88)
                                  : (isDark ? const Color(0xFF0F2230) : Colors.white).withOpacity(0.72),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUser && m.provider.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '${m.provider}${m.modelId.isEmpty ? '' : ' · ${m.modelId}'}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.primary.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  if (isUser)
                                    SelectableText(
                                      m.content.isEmpty ? '…' : m.content,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    )
                                  else
                                    MarkdownBody(
                                      data: m.content.isEmpty ? '…' : m.content,
                                      selectable: true,
                                      softLineBreak: true,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // ── 输入栏 ────────────────────────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: MxTextField(
                    controller: _inputCtrl,
                    hint: '输入问题或开发任务…',
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                MxIconBtn(
                  icon: chat.busy ? Icons.hourglass_top_rounded : Icons.send_rounded,
                  onPressed: chat.busy ? null : () => _send(chat, aiConfig, workflow),
                  active: true,
                  size: 44,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}