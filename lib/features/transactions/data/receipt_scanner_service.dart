import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/providers/shared_prefs_provider.dart';

class ParsedReceipt {
  final double amount;
  final String note;
  final DateTime date;

  ParsedReceipt({required this.amount, required this.note, required this.date});
}

class ReceiptScannerService {
  final Ref ref;

  ReceiptScannerService(this.ref);

  Future<String?> getApiKey() async {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString('gemini_api_key');
  }

  Future<void> saveApiKey(String key) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('gemini_api_key', key);
  }

  Future<ParsedReceipt?> scanReceipt(File imageFile, String apiKey) async {
    final modelNames = ['gemini-1.5-flash', 'gemini-1.5-flash-latest', 'gemini-1.5-pro', 'gemini-1.5-pro-latest', 'gemini-pro-vision'];
    final bytes = await imageFile.readAsBytes();
    final prompt = TextPart('''
You are an AI receipt scanner for an Indonesian user.
Analyze the provided image (which could be a physical receipt, a Gojek/Grab e-receipt, or a bank transfer screenshot like BCA/Mandiri) and extract the following:
1. Total amount (as a number, e.g. 150000). Ignore trailing decimals like ,00.
2. A short descriptive note for the transaction (e.g. "Groceries at Indomaret" or "Transfer to Budi").
3. Date of the transaction (in YYYY-MM-DD format). If not visible, use today's date.

Respond ONLY with a JSON object in this exact format, with no markdown formatting or other text:
{
  "amount": 150000,
  "note": "Groceries at Indomaret",
  "date": "2024-03-21"
}
''');
    
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';
    final imagePart = DataPart(mimeType, bytes);
    
    Exception? lastException;
    
    for (final modelName in modelNames) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );
        
        final response = await model.generateContent([
          Content.multi([prompt, imagePart])
        ]);
        
        final text = response.text;
        if (text == null || text.isEmpty) {
          throw Exception('AI returned empty response.');
        }
        
        String rawText = text.trim();
        if (rawText.startsWith('```')) {
          final lines = rawText.split('\n');
          if (lines.length > 2) {
            rawText = lines.sublist(1, lines.length - 1).join('\n').trim();
          }
        }
        
        final Map<String, dynamic> data = jsonDecode(rawText);
        
        final rawAmount = data['amount'];
        double parsedAmount = 0.0;
        if (rawAmount is num) {
          parsedAmount = rawAmount.toDouble();
        } else if (rawAmount is String) {
          parsedAmount = double.tryParse(rawAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }
        
        return ParsedReceipt(
          amount: parsedAmount,
          note: data['note'] as String? ?? 'Transfer BCA',
          date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
        );
      } catch (e) {
        lastException = Exception('Model $modelName failed: $e');
        print(lastException);
        continue;
      }
    }
    
    throw Exception('All fallback models failed. Last error: $lastException');
  }
}

final receiptScannerProvider = Provider<ReceiptScannerService>((ref) {
  return ReceiptScannerService(ref);
});
