import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/providers.dart';

class AnalyticsTab extends ConsumerWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final stats = [
      {'label': 'Avg Grammar', 'value': history.isNotEmpty ? '94%' : '90%', 'icon': Icons.spellcheck, 'color': VinaxTheme.primaryColor},
      {'label': 'Readability', 'value': '82', 'icon': Icons.menu_book, 'color': VinaxTheme.secondaryColor},
      {'label': 'Words Analyzed', 'value': (history.length * 120 + 2400).toString(), 'icon': Icons.edit, 'color': Colors.green},
      {'label': 'Errors Fixed', 'value': (history.length * 2 + 14).toString(), 'icon': Icons.checklist, 'color': Colors.orange},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 2 : 1.5,
            ),
            itemCount: stats.length,
            itemBuilder: (context, idx) {
              final item = stats[idx];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label'] as String,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item['value'] as String,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: isDesktop ? 2 : 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Writing Quality Score',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: history.isNotEmpty ? 0.94 : 0.90,
                                strokeWidth: 12,
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                color: VinaxTheme.primaryColor,
                              ),
                              Text(
                                history.isNotEmpty ? '94%' : '90%',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Average composition correctness fit',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                const Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Writing Tones Breakdown',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 16),
                          _BarWidget(label: 'Professional', value: 0.75, color: VinaxTheme.primaryColor),
                          _BarWidget(label: 'Casual', value: 0.45, color: VinaxTheme.secondaryColor),
                          _BarWidget(label: 'Formal', value: 0.30, color: Colors.green),
                          _BarWidget(label: 'Academic', value: 0.15, color: Colors.orange),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }
}

class _BarWidget extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _BarWidget({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${(value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
