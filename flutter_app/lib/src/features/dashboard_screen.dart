import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/providers.dart';
import 'write_correct_tab.dart';
import 'rewriter_tab.dart';
import 'email_tab.dart';
import 'proofreader_tab.dart';
import 'tone_tab.dart';
import 'analytics_tab.dart';
import 'history_tab.dart';
import 'settings_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const WriteCorrectTab(),
    const RewriterTab(),
    const EmailTab(),
    const ProofreaderTab(),
    const ToneTab(),
    const AnalyticsTab(),
    const HistoryTab(),
    const SettingsTab(),
  ];

  final List<String> _titles = [
    'Write & Correct',
    'Smart Rewriter',
    'Email Assistant',
    'Proofreader',
    'Tone Converter',
    'Writing Analytics',
    'History logs',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          // Language selection
          DropdownButton<String>(
            value: ref.watch(activeLanguageProvider),
            underline: const SizedBox(),
            icon: const Icon(Icons.language, size: 20),
            onChanged: (lang) {
              if (lang != null) {
                ref.read(activeLanguageProvider.notifier).state = lang;
              }
            },
            items: ['English', 'Hindi', 'Spanish', 'French', 'German', 'Arabic', 'Japanese', 'Chinese']
                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                .toList(),
          ),
          const SizedBox(width: 16),
          // Theme toggler
          IconButton(
            icon: Icon(
              currentTheme == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeNotifier.state =
                  currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          if (isLargeScreen)
            NavigationRail(
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Icon(Icons.auto_fix_high, size: 36, color: VinaxTheme.primaryColor),
              ),
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.edit_note),
                  label: Text('Write'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.transform),
                  label: Text('Rewrite'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.mail),
                  label: Text('Email'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics),
                  label: Text('Proofread'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.psychology),
                  label: Text('Tone'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart),
                  label: Text('Stats'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          Expanded(
            child: _tabs[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: !isLargeScreen
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.edit_note), label: 'Write'),
                NavigationDestination(icon: Icon(Icons.transform), label: 'Rewrite'),
                NavigationDestination(icon: Icon(Icons.mail), label: 'Email'),
                NavigationDestination(icon: Icon(Icons.analytics), label: 'Proofread'),
                NavigationDestination(icon: Icon(Icons.psychology), label: 'Tone'),
              ],
            )
          : null,
    );
  }
}
