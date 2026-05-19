import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';

class TokenGateScreen extends StatefulWidget {
  const TokenGateScreen({super.key});

  @override
  State<TokenGateScreen> createState() => _TokenGateScreenState();
}

class _TokenGateScreenState extends State<TokenGateScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub 接入')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('MoonXide 需要 GitHub Token 才能创建仓库、读写代码、触发编译、下载产物与发布发行版。'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.open_in_new), label: const Text('前往 GitHub 创建令牌')),
            const SizedBox(height: 12),
            TextField(controller: controller, decoration: const InputDecoration(labelText: '粘贴 GitHub Token', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const Text('建议权限：repo、workflow、read:user、write:packages、delete_repo。公开/私有仓库、Actions 和 Release 都需要对应权限。'),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            FilledButton(
              onPressed: state.loading
                  ? null
                  : () async {
                      final ok = await context.read<AppState>().acceptToken(controller.text);
                      if (ok && mounted) Navigator.of(context).pushReplacementNamed('/home');
                    },
              child: state.loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('验证并进入 MoonXide'),
            ),
          ],
        ),
      ),
    );
  }
}