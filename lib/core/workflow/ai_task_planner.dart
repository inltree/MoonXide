import 'package:uuid/uuid.dart';
import 'ai_task_plan.dart';
import 'ai_task_step.dart';

class AiTaskPlanner {
  AiTaskPlan createPlan(String instruction) {
    final id = const Uuid().v4();
    final normalized = instruction.trim();
    final steps = <AiTaskStep>[
      AiTaskStep(id: const Uuid().v4(), title: '理解需求', detail: '解析用户输入，提取目标、限制、项目类型和期望结果。'),
      AiTaskStep(id: const Uuid().v4(), title: '检查工作区', detail: '读取当前仓库、文件树、构建配置、权限和依赖状态。'),
      AiTaskStep(id: const Uuid().v4(), title: '制定执行方案', detail: '把目标拆成可执行步骤，明确每一步的输入、输出和验证方式。'),
      AiTaskStep(id: const Uuid().v4(), title: '修改项目内容', detail: '创建、编辑或删除必要文件，调整代码、配置、权限、依赖或工作流。'),
      AiTaskStep(id: const Uuid().v4(), title: '提交与构建', detail: '保存改动，提交到 GitHub，按 Debug 或 Release 触发云编译。'),
      AiTaskStep(id: const Uuid().v4(), title: '验证结果', detail: '读取编译状态、下载日志或产物，确认任务是否达成。'),
      AiTaskStep(id: const Uuid().v4(), title: '收尾处理', detail: '清理失败日志、记录产物、更新任务状态并给出完成说明。'),
    ];
    return AiTaskPlan(id: id, userInstruction: normalized, goal: normalized.isEmpty ? '完成用户指定的软件开发任务' : normalized, steps: steps);
  }
}