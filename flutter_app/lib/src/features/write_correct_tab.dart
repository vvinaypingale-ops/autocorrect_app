import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/providers.dart';

class WriteCorrectTab extends ConsumerStatefulWidget {
  const WriteCorrectTab({super.key});

  @override
  ConsumerState<WriteCorrectTab> createState() => _WriteCorrectTabState();
}

class _WriteCorrectTabState extends ConsumerState<WriteCorrectTab> {
  final TextEditingController _textController = TextEditingController();
  List<dynamic> _suggestions = [];
  bool _loading = false;
  String _correctedText = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkGrammar() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final service = ref.read(grammarServiceProvider);
    final result = await service.checkGrammar(text);

    setState(() {
      _loading = false;
      _suggestions = result['corrections'] ?? [];
      _correctedText = result['correctedText'] ?? text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['isDemo'] == true
              ? 'Demo corrections loaded. Add API key in Settings.'
              : 'Grammar check completed!',
        ),
        backgroundColor: VinaxTheme.primaryColor,
      ),
    );
  }

  void _applySuggestion(int index) {
    final correction = _suggestions[index];
    final original = correction['original'];
    final replacement = correction['replacement'];
    
    String currentText = _textController.text;
    currentText = currentText.replaceAll(original, replacement);
    
    setState(() {
      _textController.text = currentText;
      _suggestions.removeAt(index);
    });
  }

  void _applyAll() {
    setState(() {
      _textController.text = _correctedText;
      _suggestions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    final editorCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text(
                  'Compose Text',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '${_textController.text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length} words',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Type something to verify... e.g. "Helo how aree you"',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (val) {
                  setState(() {}); // refresh word counter
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        _textController.clear();
                        setState(() {
                          _suggestions.clear();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic_none),
                      onPressed: () {
                        // voice typing simulation
                        setState(() {
                          _textController.text = 'Helo how aree you today? I go to office yesterday.';
                        });
                        _checkGrammar();
                      },
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _checkGrammar,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(_loading ? 'Auditing...' : 'Check Writing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VinaxTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final suggestionsCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text(
                  'AI Corrections (${_suggestions.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (_suggestions.isNotEmpty)
                  TextButton(
                    onPressed: _applyAll,
                    child: const Text('Apply All'),
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _suggestions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                          SizedBox(height: 8),
                          Text('No active spelling or grammar issues!'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final item = _suggestions[index];
                        return Card(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item['original'],
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_right_alt, color: Colors.grey),
                                    Text(
                                      item['replacement'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['explanation'],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _suggestions.removeAt(index);
                                        });
                                      },
                                      child: const Text('Ignore', style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _applySuggestion(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: VinaxTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Correct'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
              children: [
                Expanded(flex: 3, child: editorCard),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: suggestionsCard),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 3, child: editorCard),
                const SizedBox(height: 16),
                Expanded(flex: 2, child: suggestionsCard),
              ],
            ),
    );
  }
}
