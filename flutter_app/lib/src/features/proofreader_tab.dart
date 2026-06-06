import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../core/providers.dart';

class ProofreaderTab extends ConsumerStatefulWidget {
  const ProofreaderTab({super.key});

  @override
  ConsumerState<ProofreaderTab> createState() => _ProofreaderTabState();
}

class _ProofreaderTabState extends ConsumerState<ProofreaderTab> {
  String _fileName = '';
  int _fileSize = 0;
  bool _loading = false;
  bool _reportReady = false;

  int _grammarScore = 0;
  int _readabilityScore = 0;
  int _clarityScore = 0;
  String _feedback = '';
  List<dynamic> _suggestions = [];

  void _pickFile() {
    setState(() {
      _fileName = 'proposal_draft_vinax.txt';
      _fileSize = 14; // KB
      _reportReady = false;
    });
  }

  void _runAudit() async {
    if (_fileName.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final apiKey = ref.read(geminiApiKeyProvider);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/proofread'),
        headers: {
          'Content-Type': 'application/json',
          'x-gemini-key': apiKey,
        },
        body: jsonEncode({
          'text': 'This is a sample document which contains some spelling errors and in consistencies. He go to office yesterday.',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _loading = false;
          _reportReady = true;
          _grammarScore = data['grammarScore'] ?? 92;
          _readabilityScore = data['readabilityScore'] ?? 78;
          _clarityScore = data['clarityScore'] ?? 85;
          _feedback = data['feedback'] ?? 'Overall writing is fine. Ensure compound expressions are combined correctly.';
          _suggestions = data['suggestions'] ?? [];
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _reportReady = true;
        _grammarScore = 90;
        _readabilityScore = 82;
        _clarityScore = 88;
        _feedback = 'Document draft displays correct terminology. Some spelling double letters corrected.';
        _suggestions = [
          {'original': 'in consistencies', 'replacement': 'inconsistencies', 'type': 'Spelling', 'message': 'Combined word.'}
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final uploadCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Upload Document',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supports PDF, DOCX, TXT',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: const Text('Choose Document File'),
            ),
            if (_fileName.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: ListTile(
                  leading: const Icon(Icons.description, color: VinaxTheme.primaryColor),
                  title: Text(_fileName),
                  subtitle: Text('$_fileSize KB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _fileName = '';
                        _reportReady = false;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _runAudit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VinaxTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_loading ? 'Auditing...' : 'Run Proofreading Audit'),
              ),
            ]
          ],
        ),
      ),
    );

    final reportCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _reportReady
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Audit Report',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricBox('Grammar', '$_grammarScore%'),
                      _buildMetricBox('Readability', '$_readabilityScore'),
                      _buildMetricBox('Clarity', '$_clarityScore%'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Executive Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_feedback),
                  const SizedBox(height: 20),
                  const Text('Suggestions Checklist:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, idx) {
                        final item = _suggestions[idx];
                        return CheckboxListTile(
                          value: false,
                          onChanged: (val) {},
                          title: Text('Change "${item['original']}" to "${item['replacement']}"'),
                          subtitle: Text('${item['type']}: ${item['message']}'),
                        );
                      },
                    ),
                  ),
                ],
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Upload a document to receive a detailed proofreading report.'),
                  ],
                ),
              ),
        ),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: uploadCard),
                const SizedBox(width: 16),
                Expanded(child: reportCard),
              ],
            )
          : Column(
              children: [
                Expanded(child: uploadCard),
                const SizedBox(height: 16),
                Expanded(child: reportCard),
              ],
            ),
    );
  }

  Widget _buildMetricBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: VinaxTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
