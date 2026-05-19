import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../workspace/workspace_screen.dart';
import '../editor/editor_screen.dart';
import '../chat/chat_screen.dart';
import '../ai_workflow/ai_workflow_screen.dart';
import '../build/build_screen.dart';
import '../release/release_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final screens = [
      WorkspaceScreen(state: state),
      const EditorScreen(),
      const ChatScreen(),
      const AiWorkflowScreen(),
      BuildScreen(state: state),
      const ReleaseScreen(),
      SettingsScreen(state: state),
    ];
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.folder_open), label: '工作区'),
          NavigationDestination(icon: Icon(Icons.edit), label: '编辑器'),
          NavigationDestination(icon: Icon(Icons.chat), label: '对话'),
          NavigationDestination(icon: Icon(Icons.psychology), label: '任务'),
          NavigationDestination(icon: Icon(Icons.cloud_upload), label: '编译'),
          NavigationDestination(icon: Icon(Icons.rocket_launch), label: '发行版'),
          NavigationDestination(icon: Icon(Icons.tune), label: '设置'),
        ],
      ),
    );
  }
}