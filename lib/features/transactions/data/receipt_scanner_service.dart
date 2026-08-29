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
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final bytes = await imageFile.readAsBytes();
    final prompt = TextPart('''
You are an AI receipt scanner for an Indonesian user.
Analyze the receipt image and extract the following:
1. Total amount (as a number, e.g. 150000)
2. A short descriptive note for the transaction (e.g. "Groceries at Indomaret")
3. Date of the transaction (in YYYY-MM-DD format). If not visible, use today's date.

Respond ONLY with a JSON object in this exact format, with no markdown formatting or other text:
{
  "amount": 150000,
  "note": "Groceries at Indomaret",
  "date": "2024-03-21"
}
''');
    
    final imagePart = DataPart('image/jpeg', bytes);
    
    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
      
      final text = response.text;
      if (text == null) return null;
      
      final Map<String, dynamic> data = jsonDecode(text.trim());
      
      return ParsedReceipt(
        amount: (data['amount'] as num).toDouble(),
        note: data['note'] as String? ?? 'Receipt Scan',
        date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      // Error is caught by caller
      return null;
    }
  }
}

final receiptScannerProvider = Provider<ReceiptScannerService>((ref) {
  return ReceiptScannerService(ref);
});
