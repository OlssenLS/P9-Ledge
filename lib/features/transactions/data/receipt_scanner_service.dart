import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ParsedReceipt {
  final double amount;
  final String note;
  final DateTime date;

  ParsedReceipt({required this.amount, required this.note, required this.date});
}

class ReceiptScannerService {
  final Ref ref;

  ReceiptScannerService(this.ref);

  Future<ParsedReceipt?> scanReceipt(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      final text = recognizedText.text;
      if (text.isEmpty) {
        throw Exception('No text found in image.');
      }

      // Simple heuristic parsing for Indonesian receipts (e.g., BCA, Gojek, Indomaret)
      double amount = 0.0;
      String note = 'Manual Scan';
      DateTime date = DateTime.now();

      final lines = text.split('\n');

      // 1. Extract Amount: Find all sequences of numbers, dots, and commas
      // e.g. 101,000.00 or 101.000,00 or 150000
      final priceRegex = RegExp(r'\b([0-9]{1,3}(?:[\.\,][0-9]{3})+(?:[\.\,][0-9]{2})?)\b');
      final matches = priceRegex.allMatches(text);
      for (final match in matches) {
        String matchStr = match.group(1)!;
        // Chop off .00 or ,00 decimals
        if (matchStr.endsWith('.00') || matchStr.endsWith(',00')) {
          matchStr = matchStr.substring(0, matchStr.length - 3);
        }
        String cleanStr = matchStr.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanStr.isNotEmpty) {
           double val = double.parse(cleanStr);
           if (val > amount) amount = val;
        }
      }

      // Fallback: Look for "Rp" or "IDR" followed by numbers
      if (amount == 0.0) {
         final rpRegex = RegExp(r'(?:rp|idr)[\s\:\.\,]*([0-9]+(?:[\.\,][0-9]+)*)', caseSensitive: false);
         final rpMatches = rpRegex.allMatches(text);
         for (final m in rpMatches) {
            String matchStr = m.group(1)!;
            if (matchStr.endsWith('.00') || matchStr.endsWith(',00')) {
              matchStr = matchStr.substring(0, matchStr.length - 3);
            }
            String cleanStr = matchStr.replaceAll(RegExp(r'[^0-9]'), '');
            if (cleanStr.isNotEmpty) {
               double val = double.parse(cleanStr);
               if (val > amount) amount = val;
            }
         }
      }

      // 2. Extract Date: Look for DD/MM/YYYY or DD-MM-YYYY
      final dateRegex = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})');
      for (final line in lines) {
        final match = dateRegex.firstMatch(line);
        if (match != null) {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);
          date = DateTime(year, month, day);
          break;
        }
      }

      // 3. Extract Note: Try to find a merchant name or "Transfer to"
      for (final line in lines) {
        final lower = line.toLowerCase();
        if (lower.contains('ke :') || lower.contains('to:')) {
           note = 'Transfer $line';
           break;
        } else if (lower.contains('indomaret') || lower.contains('alfamart')) {
           note = 'Groceries';
           break;
        } else if (lower.contains('gojek') || lower.contains('grab')) {
           note = 'Transport/Food';
           break;
        }
      }

      return ParsedReceipt(
        amount: amount,
        note: note,
        date: date,
      );
    } catch (e) {
      throw Exception('OCR Failed: $e');
    } finally {
      textRecognizer.close();
    }
  }
}

final receiptScannerProvider = Provider<ReceiptScannerService>((ref) {
  return ReceiptScannerService(ref);
});
