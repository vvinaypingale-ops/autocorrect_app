import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/providers.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _dictWordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate API key
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiKeyController.text = ref.read(geminiApiKeyProvider);
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _dictWordController.dispose();
    super.dispose();
  }

  void _saveApiKey() {
    final key = _apiKeyController.text.trim();
    ref.read(geminiApiKeyProvider.notifier).state = key;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini API key saved.')),
    );
  }

  void _addWord() {
    final word = _dictWordController.text.trim();
    if (word.isNotEmpty) {
      ref.read(customDictionaryProvider.notifier).addWord(word);
      _dictWordController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$word" added to custom dictionary.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dictionary = ref.watch(customDictionaryProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final apiCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'API Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure credentials to enable live AI analysis.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 24),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveApiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: VinaxTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save API Key'),
            ),
          ],
        ),
      ),
    );

    final dictCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Custom Dictionary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add specialized vocabulary or names to bypass spelling checks.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dictWordController,
                    decoration: const InputDecoration(
                      labelText: 'Add Word',
                      hintText: 'e.g. Vinax',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addWord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VinaxTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: dictionary.isEmpty
                  ? const Center(child: Text('Dictionary is empty', style: TextStyle(color: Colors.grey)))
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dictionary.map((word) {
                          return InputChip(
                            label: Text(word),
                            onDeleted: () {
                              ref.read(customDictionaryProvider.notifier).removeWord(word);
                            },
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: apiCard),
                const SizedBox(width: 16),
                Expanded(child: dictCard),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                apiCard,
                const SizedBox(height: 16),
                Expanded(child: dictCard),
              ],
            ),
    );
  }
}
