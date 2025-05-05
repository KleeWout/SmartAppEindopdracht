// inspiratie/vb code: https://github.com/Cheneth/receipt-bubble
//https://github.com/brendawon/receipt-hacker/blob/master/lib/text_brain.dart
//https://blog.codemagic.io/text-recognition-using-firebase-ml-kit-flutter/

import 'dart:collection';
import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_item.dart';

// Models for spatial text analysis
class WordBox {
  String text;
  List<List<double>> vertices;
  List<List<double>>? boundingBox;
  int lineNum = 0;
  List match = [];
  bool matched = false;

  WordBox(this.text, this.vertices);

  void setBox(List<List<double>> boundingBox) {
    this.boundingBox = boundingBox;
  }

  void pushMatch(HashMap<String, int> match) {
    this.match.add(match);
  }

  void setlineNum(int lineNum) {
    this.lineNum = lineNum;
  }

  void setMatched(bool matched) {
    this.matched = matched;
  }
}

class Item {
  String name;
  double totalCost;
  double unitCost;
  int quantity;

  Item(this.name, this.totalCost, this.unitCost, this.quantity);
}

class ReceiptInfo {
  List<Item> items;
  double finalTotal;
  double finalTax;

  ReceiptInfo(this.items, this.finalTotal, this.finalTax);
}

class ReceiptData {
  final String merchantName;
  final double totalAmount;
  final DateTime? date;
  final String possibleCategory;
  final List<ReceiptItem> items;
  final double? taxAmount;

  ReceiptData({
    required this.merchantName,
    required this.totalAmount,
    this.date,
    required this.possibleCategory,
    required this.items,
    this.taxAmount,
  });
}

class ReceiptAnalyzerService {
  final _textRecognizer = TextRecognizer();
  final _uuid = Uuid();

  // Common regex patterns (for both languages)
  final RegExp _moneyExpCommon = RegExp(r'([0-9]{1,3}[.,][0-9][0-9])');

  // English patterns
  final RegExp _totalExpEn = RegExp(r'([Tt][Oo][Tt][Aa][Ll])');
  final RegExp _subtotalExpEn = RegExp(r'[Ss][Uu][Bb]\s?[Tt][Oo][Tt][Aa][Ll]');
  final RegExp _taxExpEn =
      RegExp(r'([Tt][Aa][Xx])|([Hh][Ss][Tt])|([Gg][Ss][Tt])');
  final RegExp _tipExpEn =
      RegExp(r'([Tt][Ii][Pp]|[Gg][Rr][Aa][Tt][Uu][Ii][Tt][Yy])');

  // Dutch patterns
  final RegExp _totalExpNl =
      RegExp(r'([Tt][Oo][Tt][Aa][Aa][Ll])|([Ss][Oo][Mm])');
  final RegExp _subtotalExpNl = RegExp(
      r'([Ss][Uu][Bb][Tt][Oo][Tt][Aa][Aa][Ll])|([Tt][Uu][Ss][Ss][Ee][Nn][Ss][Oo][Mm])');
  final RegExp _taxExpNl =
      RegExp(r'([Bb][Tt][Ww])|([Bb][Ee][Ll][Aa][Ss][Tt][Ii][Nn][Gg])');
  final RegExp _tipExpNl = RegExp(r'([Ff][Oo][Oo][Ii])|([Tt][Ii][Pp])');

  // Other patterns
  final RegExp _quantityExp =
      RegExp(r'^([0-9]{1,3})\s?[xX]?\s|[(]([0-9]{1,3})');
  final RegExp _priceWithCurrencyExp =
      RegExp(r'[€$£¥]?\s*[0-9]{1,3}(?:[,.][0-9]{3})*[,.][0-9]{2}');

  // Dutch date formats
  final RegExp _dateExpNl = RegExp(r'(\d{1,2})[-./](\d{1,2})[-./](\d{2,4})');

  Future<ReceiptData> analyzeReceipt(String imagePath) async {
    // Start with default values
    String merchantName = '';
    double totalAmount = 0.0;
    DateTime? receiptDate;
    String possibleCategory = '';
    List<ReceiptItem> extractedItems = [];
    double? taxAmount;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Use spatial analysis for better text understanding
      List<String> processedLines = _getSpatiallyProcessedText(recognizedText);

      // Auto-detect language (Dutch or English) based on receipt keywords
      bool isDutchReceipt = _detectDutchLanguage(processedLines);

      // Apply TextBrain-inspired approach to improve parsing
      final parsedData =
          _parseReceiptWithEnhancedLogic(processedLines, isDutchReceipt);

      merchantName = _extractMerchantName(processedLines);
      totalAmount = parsedData.finalTotal;
      taxAmount = parsedData.finalTax;

      // Convert parsed items to ReceiptItem objects
      extractedItems = parsedData.items
          .map((item) => ReceiptItem(
              id: _uuid.v4(), name: item.name.trim(), price: item.totalCost))
          .toList();

      // Extract date (using both formats)
      receiptDate = _extractDate(processedLines, isDutchReceipt);

      // Determine possible category based on merchant or items
      possibleCategory =
          _determinePossibleCategory(processedLines, isDutchReceipt);
    } catch (e) {
      // print('Error analyzing receipt: $e');
    } finally {
      // Always close the text recognizer when done
      _textRecognizer.close();
    }

    return ReceiptData(
      merchantName: merchantName,
      totalAmount: totalAmount,
      date: receiptDate,
      possibleCategory: possibleCategory,
      items: extractedItems,
      taxAmount: taxAmount,
    );
  }

  // Detect if the receipt is in Dutch by looking for Dutch-specific words
  bool _detectDutchLanguage(List<String> lines) {
    int dutchScore = 0;
    int englishScore = 0;

    // Common Dutch receipt words
    final dutchKeywords = [
      'btw',
      'totaal',
      'som',
      'contant',
      'pinnen',
      'bon',
      'kassa',
      'subtotaal',
      'kassabon',
      'bedrag',
      'aantal',
      'korting',
      'prijs',
      'stuks',
      'betaald',
      'terug',
      'bedankt',
      'euro',
      'artikel'
    ];

    // Common English receipt words
    final englishKeywords = [
      'total',
      'subtotal',
      'tax',
      'change',
      'cash',
      'amount',
      'card',
      'payment',
      'receipt',
      'discount',
      'price',
      'quantity',
      'thank',
      'paid',
      'balance',
      'due'
    ];

    // Count occurrences of Dutch and English keywords
    for (final line in lines) {
      final lowerLine = line.toLowerCase();

      for (final keyword in dutchKeywords) {
        if (lowerLine.contains(keyword)) {
          dutchScore++;
        }
      }

      for (final keyword in englishKeywords) {
        if (lowerLine.contains(keyword)) {
          englishScore++;
        }
      }

      // Dutch currency format check (€ symbol or EUR)
      if (lowerLine.contains('€') || lowerLine.contains(' eur')) {
        dutchScore += 2;
      }

      // Dutch uses comma as decimal separator
      if (RegExp(r'\d+,\d{2}').hasMatch(lowerLine)) {
        dutchScore++;
      }

      // English uses period as decimal separator
      if (RegExp(r'\d+\.\d{2}').hasMatch(lowerLine)) {
        englishScore++;
      }
    }

    return dutchScore > englishScore;
  }

  // Spatial text processing for better recognition of receipt structure
  List<String> _getSpatiallyProcessedText(RecognizedText recognizedText) {
    List<WordBox> mergedLines = [];

    // Convert ML Kit text blocks to our WordBox format for spatial analysis
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        List<List<double>> tempVertices = [];
        String words = "";

        // Extract corner points
        for (math.Point point in line.cornerPoints) {
          tempVertices.add([point.x.toDouble(), point.y.toDouble()]);
        }

        // Concatenate text elements
        for (TextElement element in line.elements) {
          words = words + " " + element.text;
        }
        words = words.trim();

        mergedLines.add(WordBox(words, tempVertices));
      }
    }

    // Apply spatial analysis
    _getBoundingPolygon(mergedLines);
    _combineBoundingPolygon(mergedLines);
    List<String> finalLines = _constructLinesWithBoundingPolygon(mergedLines);

    // Print processed lines for debugging
    print('--- Spatially Processed Lines ---');
    for (String line in finalLines) {
      print(line);
    }

    return finalLines;
  }

  // Process bounding polygons for each text line
  void _getBoundingPolygon(List<WordBox> mergedLines) {
    for (int i = 0; i < mergedLines.length; i++) {
      var points = <List<double>>[];

      // Calculate height of the text line
      double h1 =
          (mergedLines[i].vertices[0][1] - mergedLines[i].vertices[3][1]).abs();
      double h2 =
          (mergedLines[i].vertices[1][1] - mergedLines[i].vertices[2][1]).abs();

      double h = math.max(h1, h2);
      double avgHeight = h * 0.6;
      double threshold = h * 1;

      // Get top line points
      points.add(mergedLines[i].vertices[1]);
      points.add(mergedLines[i].vertices[0]);
      List<double> topLine = _getLineMesh(points, avgHeight, true);

      // Get bottom line points
      points = <List<double>>[];
      points.add(mergedLines[i].vertices[2]);
      points.add(mergedLines[i].vertices[3]);
      List<double> bottomLine = _getLineMesh(points, avgHeight, false);

      // Set bounding box with expanded threshold for better text grouping
      mergedLines[i].setBox([
        [topLine[0], topLine[2] - threshold],
        [topLine[1], topLine[3] - threshold],
        [bottomLine[1], bottomLine[3] + threshold],
        [bottomLine[0], bottomLine[2] + threshold]
      ]);

      mergedLines[i].setlineNum(i);
    }
  }

  // Calculate line mesh for bounding polygon
  List<double> _getLineMesh(
      List<List<double>> p, double avgHeight, bool isTopLine) {
    if (isTopLine) {
      // Expand the bounding box
      p[1][1] += avgHeight;
      p[0][1] += avgHeight;
    } else {
      p[1][1] -= avgHeight;
      p[0][1] -= avgHeight;
    }

    double xDiff = (p[1][0] - p[0][0]);
    double yDiff = (p[1][1] - p[0][1]);

    double gradient = xDiff != 0 ? yDiff / xDiff : 0; // Avoid division by zero

    double xThreshMin = 1; // min width of the image
    double xThreshMax = 3000;
    double yMin = 0;
    double yMax = 0;

    if (gradient == 0) {
      // If line is flat
      yMin = p[0][1];
      yMax = p[0][1];
    } else {
      // There will be variance in y
      yMin = p[0][1] - (gradient * (p[0][0] - xThreshMin));
      yMax = p[0][1] + (gradient * (xThreshMax - p[0][0]));
    }

    return [xThreshMin, xThreshMax, yMin, yMax];
  }

  // Combine texts that belong together spatially
  void _combineBoundingPolygon(List<WordBox> mergedLines) {
    for (int i = 0; i < mergedLines.length; i++) {
      if (mergedLines[i].boundingBox == null) continue;

      for (int k = i + 1; k < mergedLines.length; k++) {
        if (k != i && !mergedLines[k].matched) {
          int insideCount = 0;

          // Check if vertices of one box are inside another box
          for (int j = 0;
              j < math.min(4, mergedLines[k].vertices.length);
              j++) {
            var coordinate = mergedLines[k].vertices[j];
            if (mergedLines[i].boundingBox == null) continue;

            if (_isPointInsidePolygon(
                coordinate, mergedLines[i].boundingBox!)) {
              insideCount++;
            }
          }

          // If all vertices are inside the bounding box
          if (insideCount == math.min(4, mergedLines[k].vertices.length)) {
            print('MATCH:');
            print(mergedLines[i].text);
            print(mergedLines[k].text);
            print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

            var match = HashMap<String, int>();
            match['matchCount'] = insideCount;
            match['matchLineNum'] = k;
            mergedLines[i].pushMatch(match);
            mergedLines[k].setMatched(true);
          }
        }
      }
    }
  }

  // Check if a point is inside a polygon
  bool _isPointInsidePolygon(List<double> point, List<List<double>> polygon) {
    // Implementation of point-in-polygon algorithm using ray casting
    bool inside = false;
    int nvert = polygon.length;

    for (int i = 0, j = nvert - 1; i < nvert; j = i++) {
      if (((polygon[i][1] > point[1]) != (polygon[j][1] > point[1])) &&
          (point[0] <
              (polygon[j][0] - polygon[i][0]) *
                      (point[1] - polygon[i][1]) /
                      (polygon[j][1] - polygon[i][1]) +
                  polygon[i][0])) {
        inside = !inside;
      }
    }

    return inside;
  }

  // Construct final text lines from bounding polygons
  List<String> _constructLinesWithBoundingPolygon(List<WordBox> mergedLines) {
    var finalLines = <String>[];

    for (int i = 0; i < mergedLines.length; i++) {
      if (!mergedLines[i].matched) {
        if (mergedLines[i].match.isEmpty) {
          finalLines.add(mergedLines[i].text);
        } else {
          finalLines.add(_arrangeWordsInOrder(mergedLines, i));
        }
      }
    }

    return finalLines;
  }

  // Arrange words in reading order based on their spatial position
  String _arrangeWordsInOrder(List<WordBox> mergedLines, int i) {
    String mergedLine = '';
    var line = mergedLines[i].match;

    for (int j = 0; j < line.length; j++) {
      int index = line[j]['matchLineNum'];
      String matchedWordForLine = mergedLines[index].text;

      // Order by top left x vertex (reading order)
      double mainX = mergedLines[i].vertices[0][0];
      double compareX = mergedLines[index].vertices[0][0];

      if (compareX > mainX) {
        mergedLine = mergedLines[i].text + ' ' + matchedWordForLine;
      } else {
        mergedLine = matchedWordForLine + ' ' + mergedLines[i].text;
      }
    }

    return mergedLine;
  }

  // Improved receipt parsing logic with language support
  ReceiptInfo _parseReceiptWithEnhancedLogic(List<String> lines, bool isDutch) {
    // Separate cost lines from word lines for better analysis
    List<String> costLines = [];
    List<String> wordLines = [];
    List<Item> items = [];

    double scanTotal = 0.0;
    double subtotal = 0.0;
    double scanTax = 0.0;

    // Select the appropriate regex patterns based on language
    final totalExp = isDutch ? _totalExpNl : _totalExpEn;
    final subtotalExp = isDutch ? _subtotalExpNl : _subtotalExpEn;
    final taxExp = isDutch ? _taxExpNl : _taxExpEn;
    final tipExp = isDutch ? _tipExpNl : _tipExpEn;

    // In Dutch receipts, numbers use comma as decimal separator
    // We need to normalize all numbers for processing
    List<String> normalizedLines = lines.map((line) {
      if (isDutch) {
        // Replace Dutch number format (comma decimal separator) with standard format
        return line.replaceAllMapped(RegExp(r'(\d+),(\d{2})'),
            (match) => '${match.group(1)}.${match.group(2)}');
      }
      return line;
    }).toList();

    // Classify lines into costs or text
    for (int i = 0; i < normalizedLines.length; i++) {
      if (_moneyExpCommon.hasMatch(normalizedLines[i])) {
        costLines.add(normalizedLines[i]);
      } else {
        wordLines.add(normalizedLines[i]);
      }
    }

    // Find total (largest number) - TextBrain approach
    int totalLineIndex = -1;
    for (int i = 0; i < normalizedLines.length; i++) {
      if (_moneyExpCommon.hasMatch(normalizedLines[i])) {
        double foundPrice = double.parse(
            _moneyExpCommon.stringMatch(normalizedLines[i]) ?? "0.0");
        if (foundPrice > scanTotal) {
          scanTotal = foundPrice;
          totalLineIndex = i;
        }
      }
    }

    // Find total by also looking for the total keyword
    for (int i = 0; i < normalizedLines.length; i++) {
      if (totalExp.hasMatch(normalizedLines[i]) &&
          _moneyExpCommon.hasMatch(normalizedLines[i])) {
        double foundPrice = double.parse(
            _moneyExpCommon.stringMatch(normalizedLines[i]) ?? "0.0");
        // If there is a line with the word "total" and a reasonable amount, prioritize it
        if (foundPrice > 0 && foundPrice <= scanTotal * 1.1) {
          scanTotal = foundPrice;
          totalLineIndex = i;
          break;
        }
      }
    }

    // Remove lines after total line as they're usually not relevant
    if (totalLineIndex >= 0 && totalLineIndex < normalizedLines.length - 1) {
      normalizedLines = normalizedLines.sublist(0, totalLineIndex + 1);
    }

    // Find tax amount specifically
    for (int i = 0; i < normalizedLines.length; i++) {
      if (taxExp.hasMatch(normalizedLines[i]) &&
          _moneyExpCommon.hasMatch(normalizedLines[i])) {
        scanTax = double.parse(
            _moneyExpCommon.stringMatch(normalizedLines[i]) ?? "0.0");
        // Remove tax line to avoid processing it as an item
        normalizedLines.removeAt(i);
        i--; // Adjust index after removal
      }
    }

    // Find subtotal
    subtotal = _findSubtotal(normalizedLines, isDutch);

    // If we have both total and subtotal, verify tax
    if (subtotal > 0 && scanTotal > subtotal) {
      // If tax wasn't found explicitly, derive it
      if (scanTax == 0.0) {
        scanTax = scanTotal - subtotal;
      }
    }

    // Extract items using improved logic
    items = _extractItems(normalizedLines, scanTotal, isDutch);

    return ReceiptInfo(items, scanTotal, scanTax);
  }

  // Improved item extraction with language support
  List<Item> _extractItems(List<String> lines, double total, bool isDutch) {
    List<Item> items = [];
    double runningTotal = 0.0;

    // Select appropriate patterns based on language
    final totalExp = isDutch ? _totalExpNl : _totalExpEn;
    final subtotalExp = isDutch ? _subtotalExpNl : _subtotalExpEn;
    final taxExp = isDutch ? _taxExpNl : _taxExpEn;
    final tipExp = isDutch ? _tipExpNl : _tipExpEn;

    // Dutch-specific quantity pattern that includes "x" (e.g., "2 x koffie")
    final quantityExpDutch = RegExp(r'(\d+)\s*[xX]\s');

    for (String line in lines) {
      // Skip lines that clearly aren't items
      if (totalExp.hasMatch(line) ||
          subtotalExp.hasMatch(line) ||
          taxExp.hasMatch(line) ||
          tipExp.hasMatch(line)) {
        continue;
      }

      // Check if line has a price
      if (_moneyExpCommon.hasMatch(line)) {
        String rawCost = _moneyExpCommon.stringMatch(line) ?? "0.0";
        double itemCost = double.parse(rawCost);

        // Skip if this is likely the total or larger than remaining expected total
        if (itemCost >= total || runningTotal + itemCost > total * 1.1) {
          continue;
        }

        // Look for quantity with language-specific patterns
        int quantity = 1;
        String? qtyMatch;

        if (isDutch) {
          qtyMatch = quantityExpDutch.stringMatch(line);
        }

        if (qtyMatch == null) {
          // Fall back to common quantity pattern
          qtyMatch = _quantityExp.stringMatch(line);
        }

        if (qtyMatch != null) {
          RegExp numOnly = RegExp(r'(\d+)');
          String? qtyStr = numOnly.stringMatch(qtyMatch);
          if (qtyStr != null) {
            quantity = int.parse(qtyStr);
          }
        }

        // Calculate unit cost
        double unitCost = quantity > 1 ? itemCost / quantity : itemCost;

        // Clean up the item name by removing the price and quantity
        String itemName =
            line.replaceAll(rawCost, '').replaceAll(qtyMatch ?? '', '').trim();

        // Additional clean-up for Dutch receipts
        if (isDutch) {
          // Remove common Dutch text patterns like "á €" (price indicator)
          itemName = itemName.replaceAll(RegExp(r'á\s*€'), '');
        }

        // Add item if we have a valid name
        if (itemName.isNotEmpty) {
          runningTotal += itemCost;
          items.add(Item(itemName, itemCost, unitCost, quantity));
        }
      }
    }

    return items;
  }

  // Improved subtotal finder with language support
  double _findSubtotal(List<String> lines, bool isDutch) {
    // Select appropriate regex based on language
    final subtotalExp = isDutch ? _subtotalExpNl : _subtotalExpEn;
    final totalExp = isDutch ? _totalExpNl : _totalExpEn;

    // Look for lines with "subtotal" specifically
    for (int i = 0; i < lines.length; i++) {
      if (subtotalExp.hasMatch(lines[i]) &&
          _moneyExpCommon.hasMatch(lines[i])) {
        return double.parse(_moneyExpCommon.stringMatch(lines[i]) ?? "0.0");
      }
    }

    // Alternative approach: look for a value before the total
    double possibleSubtotal = 0.0;
    bool foundTotal = false;

    for (int i = lines.length - 1; i >= 0; i--) {
      if (totalExp.hasMatch(lines[i]) && _moneyExpCommon.hasMatch(lines[i])) {
        foundTotal = true;
      } else if (foundTotal &&
          _moneyExpCommon.hasMatch(lines[i]) &&
          !_taxExpNl.hasMatch(lines[i]) &&
          !_taxExpEn.hasMatch(lines[i])) {
        possibleSubtotal =
            double.parse(_moneyExpCommon.stringMatch(lines[i]) ?? "0.0");
        break;
      }
    }

    return possibleSubtotal > 0 ? possibleSubtotal : -1;
  }

  String _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return '';

    // Improved merchant name extraction:
    // Try multiple approaches to increase accuracy

    // 1. First check for common receipt patterns
    // Many receipts have store name in all CAPS in the first 3 lines
    for (int i = 0; i < math.min(3, lines.length); i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty && line == line.toUpperCase() && line.length > 3) {
        return line;
      }
    }

    // 2. Look for the longest line in the first 3-4 lines that isn't a date or price
    final potentialNames = <String>[];
    for (int i = 0; i < math.min(4, lines.length); i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty &&
              !line.contains(
                RegExp(r'\d{2}[/.-]\d{2}[/.-]\d{2,4}'),
              ) && // Skip if it's a date
              !line.contains(
                  RegExp(r'\$?\s*\d+\.\d{2}')) && // Skip if it's a price
              !line.contains(
                RegExp(r'receipt|invoice|order|transaction',
                    caseSensitive: false),
              ) // Skip if it's a receipt keyword
          ) {
        potentialNames.add(line);
      }
    }

    // 3. Return the longest potential name if found
    if (potentialNames.isNotEmpty) {
      return potentialNames.reduce((a, b) => a.length > b.length ? a : b);
    }

    // 4. Fallback: return the first non-empty line
    return lines.firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
  }

  // Extract date with support for Dutch and English date formats
  DateTime? _extractDate(List<String> lines, bool isDutch) {
    // Dutch date formats typically use DD-MM-YYYY
    final List<DateFormat> dateFormats = isDutch
        ? [
            // Common Dutch date formats
            DateFormat('dd-MM-yyyy'),
            DateFormat('d-M-yyyy'),
            DateFormat('dd/MM/yyyy'),
            DateFormat('d/M/yyyy'),
            DateFormat('dd.MM.yyyy'),
            DateFormat('d.M.yyyy'),
          ]
        : [
            // Common English date formats
            DateFormat('MM/dd/yyyy'),
            DateFormat('M/d/yyyy'),
            DateFormat('dd/MM/yyyy'),
            DateFormat('d/M/yyyy'),
            DateFormat('yyyy/MM/dd'),
            DateFormat('yyyy-MM-dd'),
          ];

    // Regex patterns tailored for the language
    final List<RegExp> datePatterns = isDutch
        ? [
            RegExp(r'(\d{1,2})[-./](\d{1,2})[-./](\d{2,4})'), // DD-MM-YYYY
            RegExp(r'(\d{1,2})\s+([a-zA-Z]+)\s+(\d{2,4})'), // DD Month YYYY
          ]
        : [
            RegExp(
                r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})'), // MM/DD/YYYY or DD/MM/YYYY
            RegExp(r'(\d{2,4})[/.-](\d{1,2})[/.-](\d{1,2})'), // YYYY/MM/DD
            RegExp(
                r'([a-zA-Z]+)\s+(\d{1,2})[,]?\s+(\d{2,4})'), // Month DD, YYYY
          ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            // Try all appropriate date formats
            for (final format in dateFormats) {
              try {
                return format.parse(line.substring(match.start, match.end));
              } catch (_) {
                // Try next format
              }
            }

            // For Dutch month names in text format
            if (isDutch &&
                RegExp(r'(\d{1,2})\s+([a-zA-Z]+)\s+(\d{2,4})').hasMatch(line)) {
              final parts = line.split(RegExp(r'\s+'));
              for (int i = 0; i < parts.length - 2; i++) {
                if (RegExp(r'^\d{1,2}$').hasMatch(parts[i]) &&
                    RegExp(r'^[a-zA-Z]+$').hasMatch(parts[i + 1]) &&
                    RegExp(r'^\d{2,4}$').hasMatch(parts[i + 2])) {
                  final day = int.parse(parts[i]);
                  final monthText = parts[i + 1].toLowerCase();
                  final year = int.parse(parts[i + 2]);

                  // Map Dutch month names to numbers
                  final dutchMonths = {
                    'januari': 1,
                    'februari': 2,
                    'maart': 3,
                    'april': 4,
                    'mei': 5,
                    'juni': 6,
                    'juli': 7,
                    'augustus': 8,
                    'september': 9,
                    'oktober': 10,
                    'november': 11,
                    'december': 12,
                    'jan': 1,
                    'feb': 2,
                    'mrt': 3,
                    'apr': 4,
                    'mei': 5,
                    'jun': 6,
                    'jul': 7,
                    'aug': 8,
                    'sep': 9,
                    'okt': 10,
                    'nov': 11,
                    'dec': 12
                  };

                  final month = dutchMonths[monthText];
                  if (month != null) {
                    return DateTime(year, month, day);
                  }
                }
              }
            }
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
      }
    }

    // Return current date if no date found
    return DateTime.now();
  }

  // Enhanced category detection with Dutch support
  String _determinePossibleCategory(List<String> lines, bool isDutch) {
    // Define keywords for common receipt categories in both languages
    final Map<String, List<String>> englishKeywords = {
      'grocery': [
        'grocery',
        'supermarket',
        'food',
        'market',
        'produce',
        'bakery',
      ],
      'restaurant': [
        'restaurant',
        'cafe',
        'diner',
        'bistro',
        'eatery',
        'food',
        'menu',
      ],
      'shopping': [
        'clothing',
        'apparel',
        'mall',
        'store',
        'retail',
        'shop',
        'dress',
        'tee',
        'gloss',
      ],
      'electronics': [
        'electronics',
        'computer',
        'phone',
        'device',
        'tech',
        'digital',
      ],
      'entertainment': ['cinema', 'movie', 'theater', 'concert', 'ticket'],
      'transport': [
        'gas',
        'fuel',
        'petrol',
        'transportation',
        'transit',
        'travel',
      ],
      'health': [
        'pharmacy',
        'drug',
        'medicine',
        'health',
        'medical',
        'fitness',
      ],
    };

    final Map<String, List<String>> dutchKeywords = {
      'grocery': [
        'supermarkt',
        'voedsel',
        'markt',
        'groenten',
        'bakkerij',
        'albert heijn',
        'jumbo',
        'lidl',
        'aldi',
        'plus',
        'dirk',
        'deka',
        'slager',
        'kruidenier'
      ],
      'restaurant': [
        'restaurant',
        'café',
        'eetcafé',
        'bistro',
        'eethuis',
        'eten',
        'menu',
        'brasserie',
        'koffie',
        'lunch',
        'diner',
        'maaltijd',
        'snackbar',
        'friet'
      ],
      'shopping': [
        'kleding',
        'mode',
        'winkelcentrum',
        'winkel',
        'retail',
        'shop',
        'jurk',
        'broek',
        'schoenen',
        'kledingzaak',
        'boetiek',
        'warenhuis'
      ],
      'electronics': [
        'elektronica',
        'computer',
        'telefoon',
        'apparaat',
        'tech',
        'digitaal',
        'media markt',
        'coolblue',
        'bcc',
        'electronica'
      ],
      'entertainment': [
        'bioscoop',
        'film',
        'theater',
        'concert',
        'kaartje',
        'ticket',
        'voorstelling',
        'evenement',
        'festival',
        'uitje',
        'entertainment'
      ],
      'transport': [
        'benzine',
        'brandstof',
        'vervoer',
        'reizen',
        'trein',
        'bus',
        'tram',
        'metro',
        'taxi',
        'ov',
        'ns',
        'tankstation',
        'shell',
        'bp',
        'esso'
      ],
      'health': [
        'apotheek',
        'geneesmiddel',
        'medicijn',
        'gezondheid',
        'medisch',
        'fitness',
        'etos',
        'kruidvat',
        'drogist',
        'dokter',
        'zorg',
        'fysiotherapie'
      ],
    };

    // Use the appropriate keyword set based on language
    final categoryKeywords = isDutch ? dutchKeywords : englishKeywords;

    // Count the occurrences of keywords for each category
    final categoryScores = <String, int>{};
    for (final category in categoryKeywords.keys) {
      categoryScores[category] = 0;

      for (final keyword in categoryKeywords[category]!) {
        for (final line in lines) {
          if (line.toLowerCase().contains(keyword)) {
            categoryScores[category] = (categoryScores[category] ?? 0) + 1;
          }
        }
      }
    }

    // Find the category with the highest score
    String bestCategory = '';
    int highestScore = 0;

    categoryScores.forEach((category, score) {
      if (score > highestScore) {
        highestScore = score;
        bestCategory = category;
      }
    });

    // If no category found, return empty string
    return bestCategory;
  }
}
