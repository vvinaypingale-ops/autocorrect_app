import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../core/providers.dart';

class EmailTab extends ConsumerStatefulWidget {
  const EmailTab({super.key});

  @override
  ConsumerState<EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends ConsumerState<EmailTab> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  String _selectedTemplate = 'Business';
  String _selectedTone = 'Professional';

  String _subject = '';
  String _body = '';
  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void dispose() {
    _promptController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  void _generateEmail() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final apiKey = ref.read(geminiApiKeyProvider);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/email'),
        headers: {
          'Content-Type': 'application/json',
          'x-gemini-key': apiKey,
        },
        body: jsonEncode({
          'prompt': prompt,
          'template': _selectedTemplate,
          'tone': _selectedTone,
          'recipient': _recipientController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _loading = false;
          _subject = data['subject'] ?? '';
          _body = data['body'] ?? '';
          _suggestions = List<String>.from(data['followUpSuggestions'] ?? []);
        });

        ref.read(historyProvider.notifier).addRecord(
          'Email Draft (${_selectedTemplate})',
          prompt,
          'Subject: $_subject\n\n$_body',
        );
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _subject = 'Draft: ${prompt.substring(0, Math.min(25, prompt.length))}...';
        _body = 'Dear ${_recipientController.text.isEmpty ? '[Recipient]' : _recipientController.text},\n\n'
            'Regarding your prompt: "${prompt}". This is a fallback local response.\n\n'
            'Best Regards,\n[Your Name]';
        _suggestions = ['Inquire about status', 'Confirm next meeting'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final inputCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Email Specification',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What should the email discuss?',
                  hintText: 'e.g. Asking leave tomorrow, requesting budget approval...',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTemplate,
                      decoration: const InputDecoration(labelText: 'Template'),
                      items: ['Business', 'Job Application', 'Leave Request', 'Customer Support', 'Follow-up']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTemplate = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTone,
                      decoration: const InputDecoration(labelText: 'Tone'),
                      items: ['Professional', 'Formal', 'Friendly', 'Casual']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTone = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Name (Optional)',
                  hintText: 'e.g. Mr. Sharma, HR Team',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _generateEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VinaxTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_loading ? 'Drafting...' : 'Generate Email Draft'),
              ),
            ],
          ),
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
                  'Email Output',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (_body.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: 'Subject: $_subject\n\n$_body'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied full email to clipboard')),
                      );
                    },
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _body.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.drafts, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Fill in configurations and click generate to draft.'),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: SelectableText.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Subject: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: _subject),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SelectableText(
                            _body,
                            style: const TextStyle(fontSize: 15, height: 1.6),
                          ),
                          if (_suggestions.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Follow-up Reply Suggestions:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _suggestions.map((sug) {
                                return ActionChip(
                                  label: Text(sug),
                                  onPressed: () {
                                    setState(() {
                                      _promptController.text = 'Reply: "$sug" for the email "$_subject"';
                                    });
                                    _generateEmail();
                                  },
                                );
                              }).toList(),
                            )
                          ]
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
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
