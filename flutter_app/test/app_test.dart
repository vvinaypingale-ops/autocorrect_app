import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/src/core/providers.dart';

void main() {
  group('Vinax AutoCorrect AI Unit Tests', () {
    test('Custom Dictionary Notifier adds and removes words', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify initial words list
      var dict = container.read(customDictionaryProvider);
      expect(dict.contains('Vinax'), true);
      expect(dict.contains('NewWord'), false);

      // Add a word
      container.read(customDictionaryProvider.notifier).addWord('NewWord');
      dict = container.read(customDictionaryProvider);
      expect(dict.contains('NewWord'), true);

      // Remove the word
      container.read(customDictionaryProvider.notifier).removeWord('NewWord');
      dict = container.read(customDictionaryProvider);
      expect(dict.contains('NewWord'), false);
    });

    test('History Notifier adds records and clears history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state
      var history = container.read(historyProvider);
      expect(history.length, 0);

      // Add a history item
      container.read(historyProvider.notifier).addRecord('Grammar Check', 'helo', 'Hello');
      history = container.read(historyProvider);
      expect(history.length, 1);
      expect(history.first.feature, 'Grammar Check');
      expect(history.first.original, 'helo');
      expect(history.first.corrected, 'Hello');

      // Clear history
      container.read(historyProvider.notifier).clearHistory();
      history = container.read(historyProvider);
      expect(history.length, 0);
    });
  });
}
