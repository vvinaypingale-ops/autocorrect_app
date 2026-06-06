import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// State providers
final geminiApiKeyProvider = StateProvider<String>((ref) => '');
final activeLanguageProvider = StateProvider<String>((ref) => 'English');
final customDictionaryProvider = StateNotifierProvider<DictionaryNotifier, List<String>>((ref) {
  return DictionaryNotifier();
});

class DictionaryNotifier extends StateNotifier<List<String>> {
  DictionaryNotifier() : super(['Vinax', 'AutoCorrect', 'DeepMind']);

  void addWord(String word) {
    if (word.isNotEmpty && !state.contains(word)) {
      state = [...state, word];
    }
  }

  void removeWord(String word) {
    state = state.where((w) => w != word).toList();
  }
}

// Correction record model
class CorrectionRecord {
  final String feature;
  final String original;
  final String corrected;
  final String timestamp;

  CorrectionRecord({
    required this.feature,
    required this.original,
    required this.corrected,
    required this.timestamp,
  });
}

// History provider
final historyProvider = StateNotifierProvider<HistoryNotifier, List<CorrectionRecord>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<List<CorrectionRecord>> {
  HistoryNotifier() : super([]);

  void addRecord(String feature, String original, String corrected) {
    final record = CorrectionRecord(
      feature: feature,
      original: original,
      corrected: corrected,
      timestamp: DateTime.now().toLocal().toString().substring(11, 19),
    );
    state = [record, ...state];
  }

  void clearHistory() {
    state = [];
  }
}

// Grammar Correction Service provider
final grammarServiceProvider = Provider((ref) => GrammarService(ref));

class GrammarService {
  final Ref _ref;
  static const String baseUrl = 'http://localhost:5000';

  GrammarService(this._ref);

  Future<Map<String, dynamic>> checkGrammar(String text) async {
    final apiKey = _ref.read(geminiApiKeyProvider);
    final language = _ref.read(activeLanguageProvider);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/correct'),
        headers: {
          'Content-Type': 'application/json',
          'x-gemini-key': apiKey,
        },
        body: jsonEncode({
          'text': text,
          'language': language,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save history automatically
        _ref.read(historyProvider.notifier).addRecord(
          'Grammar Check',
          text,
          data['correctedText'] ?? text,
        );
        return data;
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Local fallback simulator if server is offline
      return _generateLocalFallback(text);
    }
  }

  Future<Map<String, dynamic>> rewriteText(String text, String mode) async {
    final apiKey = _ref.read(geminiApiKeyProvider);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rewrite'),
        headers: {
          'Content-Type': 'application/json',
          'x-gemini-key': apiKey,
        },
        body: jsonEncode({
          'text': text,
          'mode': mode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _ref.read(historyProvider.notifier).addRecord(
          'Rewriter ($mode)',
          text,
          data['correctedText'] ?? text,
        );
        return data;
      }
      throw Exception('Server failed');
    } catch (e) {
      return {
        'correctedText': '[Local Fallback: $mode] $text',
        'explanation': 'Local fallback generated. Server connection failed.',
      };
    }
  }

  Map<String, dynamic> _generateLocalFallback(String text) {
    String corrected = text;
    final list = <Map<String, String>>[];

    if (text.toLowerCase().contains('helo')) {
      corrected = corrected.replaceAll(RegExp('helo', caseSensitive: false), 'Hello');
      list.add({
        'original': 'helo',
        'replacement': 'Hello',
        'explanation': 'Correct spelling of greeting.',
      });
    }
    if (text.toLowerCase().contains('aree')) {
      corrected = corrected.replaceAll(RegExp('aree', caseSensitive: false), 'are');
      list.add({
        'original': 'aree',
        'replacement': 'are',
        'explanation': 'Fixed spelling double letter typo.',
      });
    }
    if (text.toLowerCase().contains('he go')) {
      corrected = corrected.replaceAll(RegExp('he go', caseSensitive: false), 'he went');
      list.add({
        'original': 'he go',
        'replacement': 'he went',
        'explanation': 'Fixed tense agreement for past action.',
      });
    }

    _ref.read(historyProvider.notifier).addRecord('Grammar Check (Fallback)', text, corrected);

    return {
      'correctedText': corrected,
      'corrections': list,
      'isDemo': true,
    };
  }
}
