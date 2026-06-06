import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/theme.dart';
import 'src/features/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: VinaxAutoCorrectApp(),
    ),
  );
}

class VinaxAutoCorrectApp extends ConsumerWidget {
  const VinaxAutoCorrectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Vinax AutoCorrect AI',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: VinaxTheme.lightTheme,
      darkTheme: VinaxTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
