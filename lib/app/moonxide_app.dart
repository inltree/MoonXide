import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'moonxide_theme.dart';
import '../core/services/app_state.dart';
import '../features/token_gate/token_gate_screen.dart';
import '../features/home/home_screen.dart';

class MoonXideApp extends StatelessWidget {
  const MoonXideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoonXide',
      theme: MoonXideTheme.light(),
      darkTheme: MoonXideTheme.dark(),
      themeMode: ThemeMode.system,
      routes: {
        '/token': (_) => const TokenGateScreen(),
        '/home': (_) => const HomeScreen(),
      },
      home: state.token == null || state.token!.isEmpty ? const TokenGateScreen() : const HomeScreen(),
    );
  }
}
