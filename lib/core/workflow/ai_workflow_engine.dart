import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_task_plan.dart';
import 'ai_task_planner.dart';
import 'ai_task_step.dart';
import 'ai_task_step_status.dart';

class AiWorkflowEngine extends ChangeNotifier {
  final AiTaskPlanner planner;
  AiTaskPlan? currentPlan;
  bool running = false;
  bool paused = false;
  String eventLog = '';

  AiWorkflowEngine({AiTaskPlanner? planner}) : planner = planner ?? AiTaskPlanner();

  void createTask(String instruction) {
    currentPlan = planner.createPlan(instruction);
    eventLog = '已创建任务目标：${currentPlan!.goal}';
    running = false;
    paused = false;
    notifyListeners();
  }

  Future<void> startAutoRun() async {
    if (currentPlan == null || running) return;
    running = true;
    paused = false;
    notifyListeners();
    while (running && !paused && currentPlan != null && !currentPlan!.finished) {
      final index = currentPlan!.steps.indexWhere((e) => e.status == AiTaskStepStatus.pending || e.status == AiTaskStepStatus.failed);
      if (index < 0) {
        currentPlan = currentPlan!.copyWith(finished: true);
        eventLog = '$eventLog\n全部任务步骤已完成。';
        running = false;
        notifyListeners();
        break;
      }
      await runStep(index);
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> runStep(int index) async {
    final plan = currentPlan;
    if (plan == null || index < 0 || index >= plan.steps.length) return;
    _updateStep(index, plan.steps[index].copyWith(status: AiTaskStepStatus.running));
    eventLog = '$eventLog\n正在执行：${plan.steps[index].title}';
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final result = _executeVirtualStep(plan.steps[index]);
      _updateStep(index, plan.steps[index].copyWith(status: AiTaskStepStatus.completed, result: result));
      eventLog = '$eventLog\n已完成：${plan.steps[index].title}';
    } catch (e) {
      _updateStep(index, plan.steps[index].copyWith(status: AiTaskStepStatus.failed, result: e.toString()));
      eventLog = '$eventLog\n失败：${plan.steps[index].title}，$e';
      running = false;
    }
    notifyListeners();
  }

  String _executeVirtualStep(AiTaskStep step) {
    switch (step.title) {
      case '理解需求':
        return '已提取任务目标和限制条件。';
      case '检查工作区':
        return '已读取当前仓库上下文、文件结构和构建状态。';
      case '制定执行方案':
        return '已生成可执行任务步骤，并启用自动连续执行。';
      case '修改项目内容':
        return '已根据目标准备代码、配置、权限、依赖或工作流修改。';
      case '提交与构建':
        return '已进入保存、提交、Debug/Release 构建链路。';
      case '验证结果':
        return '已检查构建状态、日志、产物和可安装结果。';
      case '收尾处理':
        return '已清理临时状态并完成任务记录。';
      default:
        return '步骤已完成。';
    }
  }

  void _updateStep(int index, AiTaskStep next) {
    final steps = [...currentPlan!.steps];
    steps[index] = next;
    final finished = steps.every((e) => e.status == AiTaskStepStatus.completed);
    currentPlan = currentPlan!.copyWith(steps: steps, finished: finished);
  }

  void pause() {
    paused = true;
    running = false;
    eventLog = '$eventLog\n任务已暂停。';
    notifyListeners();
  }

  void resume() {
    if (currentPlan == null || currentPlan!.finished) return;
    startAutoRun();
  }

  void reset() {
    currentPlan = null;
    running = false;
    paused = false;
    eventLog = '';
    notifyListeners();
  }
}