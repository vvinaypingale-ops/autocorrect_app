import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../core/providers.dart';

class ToneTab extends ConsumerStatefulWidget {
  const ToneTab({super.key});

  @override
  ConsumerState<ToneTab> createState() => _ToneTabState();
}

class _ToneTabState extends ConsumerState<ToneTab> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedTone = 'Professional';
  String _output = '';
  String _explanation = '';
  bool _loading = false;

  final List<Map<String, dynamic>> _tones = [
    {'id': 'Professional', 'label': 'Professional', 'icon': Icons.work},
    {'id': 'Formal', 'label': 'Formal', 'icon': Icons.gavel},
    {'id': 'Casual', 'label': 'Casual', 'icon': Icons.chat_bubble},
    {'id': 'Friendly', 'label': 'Friendly', 'icon': Icons.sentiment_satisfied},
    {'id': 'Academic', 'label': 'Academic', 'icon': Icons.school},
    {'id': 'Business', 'label': 'Business', 'icon': Icons.query_stats},
    {'id': 'Marketing', 'label': 'Marketing', 'icon': Icons.storefront},
    {'id': 'Social Media', 'label': 'Social Media', 'icon': Icons.tag},
  ];

  void _convertTone() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final apiKey = ref.read(geminiApiKeyProvider);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/tone'),
        headers: {
          'Content-Type': 'application/json',
          'x-gemini-key': apiKey,
        },
        body: jsonEncode({
          'text': text,
          'tone': _selectedTone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _loading = false;
          _output = data['correctedText'] ?? '';
          _explanation = data['explanation'] ?? '';
        });

        ref.read(historyProvider.notifier).addRecord(
          'Tone Shift (${_selectedTone})',
          text,
          _output,
        );
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _output = '[Local Fallback: $_selectedTone] $text';
        _explanation = 'Server connection offline. Real tone shifts require the backend API.';
      });
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
              'Input Text',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _inputController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Enter text to rephrase... e.g. "I need this done ASAP."',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Target Tone:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.5,
              ),
              itemCount: _tones.length,
              itemBuilder: (context, idx) {
                final tone = _tones[idx];
                final isSelected = _selectedTone == tone['id'];
                return ActionChip(
                  avatar: Icon(tone['icon'], size: 16, color: isSelected ? Colors.white : VinaxTheme.primaryColor),
                  label: Text(tone['label']),
                  backgroundColor: isSelected ? VinaxTheme.primaryColor : null,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontWeight: FontWeight.bold),
                  onPressed: () {
                    setState(() {
                      _selectedTone = tone['id'];
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _convertTone,
              style: ElevatedButton.styleFrom(
                backgroundColor: VinaxTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_loading ? 'Transforming...' : 'Apply Tone Shift'),
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
                  'Re-Toned Version',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (_output.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _output));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied copy output')),
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
                          Icon(Icons.palette, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Select tone and click transform to view.'),
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
                              child: Text(_explanation, style: const TextStyle(fontSize: 13)),
                            )
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
