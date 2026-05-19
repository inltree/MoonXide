import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../core/ai/ai_config_state.dart';
import '../../core/chat/chat_conversation_state.dart';
import '../../core/chat/chat_role.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final inputController = TextEditingController();

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatConversationState>();
    final aiConfig = context.watch<AiConfigState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('对话'),
        actions: [
          IconButton(onPressed: chat.rollbackLastMessage, icon: const Icon(Icons.undo)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: chat.messages.length,
              itemBuilder: (_, i) {
                final m = chat.messages[i];
                final isUser = m.role == ChatRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Card(
                      color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser)
                              Text(
                                '${m.provider}${m.modelId.isEmpty ? '' : ' · ${m.modelId}'}${m.streaming ? ' · 流式' : ''}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            if (isUser)
                              SelectableText(m.content.isEmpty ? 'AI 正在处理任务...' : m.content)
                            else
                              MarkdownBody(
                                data: m.content.isEmpty ? 'AI 正在处理任务...' : m.content,
                                selectable: true,
                                softLineBreak: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(hintText: '输入任务或问题', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: chat.busy
                      ? null
                      : () async {
                          await chat.sendUserText(inputController.text, aiConfig);
                          inputController.clear();
                          await chat.addToolResult(chat.snapshot().asPromptAttachment());
                          await chat.finishAssistantTask(aiConfig);
                        },
                  child: const Text('发送'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}