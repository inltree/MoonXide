import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/workflow/ai_workflow_engine.dart';
import '../../core/workflow/ai_task_step_status.dart';

class AiWorkflowScreen extends StatefulWidget {
  const AiWorkflowScreen({super.key});

  @override
  State<AiWorkflowScreen> createState() => _AiWorkflowScreenState();
}

class _AiWorkflowScreenState extends State<AiWorkflowScreen> {
  final instructionController = TextEditingController();

  @override
  void dispose() {
    instructionController.dispose();
    super.dispose();
  }

  IconData _icon(AiTaskStepStatus status) {
    switch (status) {
      case AiTaskStepStatus.pending:
        return Icons.radio_button_unchecked;
      case AiTaskStepStatus.running:
        return Icons.autorenew;
      case AiTaskStepStatus.completed:
        return Icons.check_circle;
      case AiTaskStepStatus.failed:
        return Icons.error;
    }
  }

  Color _color(BuildContext context, AiTaskStepStatus status) {
    switch (status) {
      case AiTaskStepStatus.pending:
        return Theme.of(context).colorScheme.outline;
      case AiTaskStepStatus.running:
        return Theme.of(context).colorScheme.primary;
      case AiTaskStepStatus.completed:
        return Colors.green;
      case AiTaskStepStatus.failed:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AiWorkflowEngine>();
    final plan = engine.currentPlan;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 工作流程'),
        actions: [
          IconButton(onPressed: engine.reset, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: instructionController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '输入你的开发任务',
              hintText: '例如：给当前 Flutter 项目添加 WebView 页面并配置网络权限，然后构建 Debug 包。',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    engine.createTask(instructionController.text);
                    engine.startAutoRun();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('规划并自动执行'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: engine.pause, icon: const Icon(Icons.pause)),
              IconButton(onPressed: engine.resume, icon: const Icon(Icons.replay)),
            ],
          ),
          const SizedBox(height: 16),
          if (plan != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('任务目标', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(plan.goal),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: plan.steps.isEmpty ? 0 : plan.steps.where((e) => e.status == AiTaskStepStatus.completed).length / plan.steps.length,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...plan.steps.map((step) => Card(
                  child: ListTile(
                    leading: Icon(_icon(step.status), color: _color(context, step.status)),
                    title: Text(step.title),
                    subtitle: Text('${step.detail}\n状态：${step.status.zhName}${step.result == null ? '' : '\n结果：${step.result}'}'),
                    isThreeLine: true,
                  ),
                )),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(engine.eventLog),
              ),
            ),
          ],
        ],
      ),
    );
  }
}