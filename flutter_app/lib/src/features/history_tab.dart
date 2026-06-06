import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/providers.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text(
                  'Correction Logs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (history.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(historyProvider.notifier).clearHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs cleared.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VinaxTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear History'),
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No past correction records available.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, idx) {
                        final record = history[idx];
                        return Card(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.between,
                              children: [
                                Text(
                                  record.feature,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: VinaxTheme.primaryColor),
                                ),
                                Text(
                                  record.timestamp,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.top(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      children: [
                                        const TextSpan(text: 'Original: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                        TextSpan(text: record.original),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      children: [
                                        const TextSpan(text: 'Polished: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                        TextSpan(text: record.corrected),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
  }
}
