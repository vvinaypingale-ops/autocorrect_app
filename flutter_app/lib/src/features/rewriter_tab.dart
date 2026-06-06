import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/providers.dart';

class RewriterTab extends ConsumerStatefulWidget {
  const RewriterTab({super.key});

  @override
  ConsumerState<RewriterTab> createState() => _RewriterTabState();
}

class _RewriterTabState extends ConsumerState<RewriterTab> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedMode = 'shorten';
  String _output = '';
  String _explanation = '';
  bool _loading = false;

  final List<Map<String, String>> _modes = [
    {'id': 'shorten', 'label': 'Shorten', 'icon': 'compress'},
    {'id': 'expand', 'label': 'Expand', 'icon': 'expand'},
    {'id': 'simplify', 'label': 'Simplify', 'icon': 'bolt'},
    {'id': 'persuasive', 'label': 'Persuasive', 'icon': 'campaign'},
    {'id': 'humanize', 'label': 'Humanize AI', 'icon': 'face'},
    {'id': 'readability', 'label': 'Flow', 'icon': 'menu_book'},
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _rewrite() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final service = ref.read(grammarServiceProvider);
    final result = await service.rewriteText(text, _selectedMode);

    setState(() {
      _loading = false;
      _output = result['correctedText'] ?? '';
      _explanation = result['explanation'] ?? '';
    });
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'compress': return Icons.compress;
      case 'expand': return Icons.expand;
      case 'bolt': return Icons.bolt;
      case 'campaign': return Icons.campaign;
      case 'face': return Icons.face;
      case 'menu_book': return Icons.menu_book;
      default: return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final inputCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Text to Enhance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _inputController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Enter text here you want to rewrite or rephrase...',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.map((mode) {
                final isSelected = _selectedMode == mode['id'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIcon(mode['icon']!), size: 16, color: isSelected ? Colors.white : null),
                      const SizedBox(width: 4),
                      Text(mode['label']!),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: VinaxTheme.primaryColor,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMode = mode['id']!;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _rewrite,
              style: ElevatedButton.styleFrom(
                backgroundColor: VinaxTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_loading ? 'Processing...' : 'Rewrite with AI'),
            ),
          ],
        ),
      ),
    );

    final outputCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text(
                  'Improved Version',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (_output.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _output));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _output.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Select mode & click rewrite to generate content.'),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _output,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                          if (_explanation.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: VinaxTheme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: VinaxTheme.primaryColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                _explanation,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ],
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
              children: [
                Expanded(child: inputCard),
                const SizedBox(width: 16),
                Expanded(child: outputCard),
              ],
            )
          : Column(
              children: [
                Expanded(child: inputCard),
                const SizedBox(height: 16),
                Expanded(child: outputCard),
              ],
            ),
    );
  }
}
