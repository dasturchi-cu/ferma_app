// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'package:excel/excel.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:intl/intl.dart';
// import '../models/farm.dart';
// import '../models/customer.dart';

// enum ExportFormat { excel, pdf, csv }

// class ExportResult {
//   final bool success;
//   final String message;
//   final String? filePath;
//   final int? fileSize;

//   ExportResult({
//     required this.success,
//     required this.message,
//     this.filePath,
//     this.fileSize,
//   });
// }

// class ExportService {
//   static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
//   static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

//   // Export farm data to Excel
//   static Future<ExportResult> exportToExcel(Farm farm) async {
//     // Farm parameter is non-nullable in Dart, so no need for null check

//     try {
//       // Validate farm data before export
//       if (!_validateFarmData(farm)) {
//         return ExportResult(
//           success: false,
//           message: 'Noto\'g\'ri ferma ma\'lumotlari',
//         );
//       }

//       final excel = Excel.createExcel();

//       try {
//         // Create sheets with error handling for each
//         await _createSummarySheet(excel, farm);
//         await _createChickensSheet(excel, farm);
//         await _createEggsSheet(excel, farm);
//         await _createCustomersSheet(excel, farm);
//         await _createSalesSheet(excel, farm);

//         // Remove default sheet
//         try {
//           excel.delete('Sheet1');
//         } catch (e) {
//           print('Warning: Could not delete default sheet: $e');
//         }

//         // Save file
//         final bytes = excel.encode();
//         if (bytes == null || bytes.isEmpty) {
//           return ExportResult(
//             success: false,
//             message: 'Excel faylni yaratishda xatolik',
//           );
//         }

//         final fileName =
//             'ferma_hisobot_${DateTime.now().millisecondsSinceEpoch}.xlsx';
//         final filePath = await _saveFile(bytes, fileName);

//         if (filePath.isEmpty) {
//           return ExportResult(
//             success: false,
//             message: 'Faylni saqlashda xatolik',
//           );
//         }

//         // Verify file was created
//         final file = File(filePath);
//         if (!await file.exists()) {
//           return ExportResult(
//             success: false,
//             message: 'Fayl yaratib bo\'lmadi',
//           );
//         }

//         return ExportResult(
//           success: true,
//           message: 'Excel hisobot muvaffaqiyatli yaratildi',
//           filePath: filePath,
//           fileSize: bytes.length,
//         );
//       } catch (e) {
//         // Clean up if any error occurs during export
//         try {
//           excel.delete('Sheet1');
//         } catch (_) {}
//         rethrow;
//       }
//     } catch (e, stackTrace) {
//       print('Excel export error: $e\n$stackTrace');
//       return ExportResult(
//         success: false,
//         message: 'Excel export xatolik: ${e.toString().split('\n').first}',
//       );
//     }
//   }

//   // Validate farm data before export
//   static bool _validateFarmData(Farm farm) {
//     try {
//       if (farm.id.isEmpty) return false;
//       if (farm.name.isEmpty) return false;
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   // Export farm data to PDF
//   static Future<ExportResult> exportToPdf(Farm farm) async {
//     try {
//       final pdf = pw.Document();

//       // Add summary page
//       pdf.addPage(await _createPdfSummaryPage(farm));

//       // Add chickens page
//       pdf.addPage(await _createPdfChickensPage(farm));

//       // Add eggs page
//       pdf.addPage(await _createPdfEggsPage(farm));

//       // Add customers page
//       pdf.addPage(await _createPdfCustomersPage(farm));

//       // Save PDF
//       final bytes = await pdf.save();
//       final fileName =
//           'ferma_hisobot_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final filePath = await _saveFile(bytes, fileName);

//       return ExportResult(
//         success: true,
//         message: 'PDF hisobot muvaffaqiyatli yaratildi',
//         filePath: filePath,
//         fileSize: bytes.length,
//       );
//     } catch (e) {
//       print('PDF export error: $e');
//       return ExportResult(
//         success: false,
//         message: 'PDF export xatolik: ${e.toString()}',
//       );
//     }
//   }

//   // Export to CSV
//   static Future<ExportResult> exportToCsv(Farm farm) async {
//     try {
//       final csv = StringBuffer();

//       // Add header
//       csv.writeln(
//         'Sana,Tuxum yigʻilgan,Tuxum sotilgan,Siniq tuxum,Katta tuxum,Tovuq ölimi,Kunlik daromad',
//       );

//       // Add data (this would need to be expanded based on actual data structure)
//       final todayActivity = farm.todayActivity;
//       csv.writeln(
//         '${_dateFormat.format(DateTime.now())},${todayActivity['eggsCollected'] ?? 0},${todayActivity['eggsSold'] ?? 0},${todayActivity['brokenEggs'] ?? 0},${todayActivity['largeEggs'] ?? 0},${todayActivity['chickenDeaths'] ?? 0},${todayActivity['dailyRevenue'] ?? 0}',
//       );

//       final bytes = utf8.encode(csv.toString());
//       final fileName =
//           'ferma_hisobot_${DateTime.now().millisecondsSinceEpoch}.csv';
//       final filePath = await _saveFile(bytes, fileName);

//       return ExportResult(
//         success: true,
//         message: 'CSV hisobot muvaffaqiyatli yaratildi',
//         filePath: filePath,
//         fileSize: bytes.length,
//       );
//     } catch (e) {
//       print('CSV export error: $e');
//       return ExportResult(
//         success: false,
//         message: 'CSV export xatolik: ${e.toString()}',
//       );
//     }
//   }

//   // Share export file
//   static Future<void> shareFile(String filePath, String title) async {
//     await Share.shareXFiles([XFile(filePath)], text: title);
//   }

//   // Print PDF
//   static Future<void> printPdf(Uint8List pdfBytes) async {
//     await Printing.layoutPdf(onLayout: (format) => pdfBytes);
//   }

//   // Helper method to save file
//   static Future<String> _saveFile(List<int> bytes, String fileName) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/$fileName');
//     await file.writeAsBytes(bytes);
//     return file.path;
//   }

//   // Create summary sheet for Excel
//   static Future<void> _createSummarySheet(Excel excel, Farm farm) async {
//     final sheet = excel['Umumiy maʻlumot'];

//     // Header
//     sheet.cell(CellIndex.indexByString('A1')).value = const TextCellValue(
//       'FERMA HISOBOTI',
//     );
//     sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
//       'Ferma nomi: ${farm.name}',
//     );
//     sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
//       'Hisobot sanasi: ${_dateFormat.format(DateTime.now())}',
//     );

//     // Stats
//     int row = 5;
//     final stats = farm.farmStats;
//     if (stats.isNotEmpty) {
//       stats.forEach((key, value) {
//         sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(key);
//         sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
//           value?.toString() ?? 'N/A',
//         );
//         row++;
//       });
//     } else {
//       sheet.cell(CellIndex.indexByString('A$row')).value = const TextCellValue(
//         'Ma\'lumot yo\'q',
//       );
//     }
//   }

//   // Create chickens sheet for Excel
//   static Future<void> _createChickensSheet(Excel excel, Farm farm) async {
//     final sheet = excel['Tovuqlar'];

//     // Header
//     sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
//       'Jami tovuqlar',
//     );
//     sheet.cell(CellIndex.indexByString('B1')).value = IntCellValue(
//       farm.farmStats['totalChickens'] is int
//           ? farm.farmStats['totalChickens'] as int
//           : 0,
//     );

//     // Today's activity
//     sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
//       'Bugungi holat',
//     );
//     sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
//       'Oʻlgan tovuqlar',
//     );
//     sheet.cell(CellIndex.indexByString('B4')).value = IntCellValue(
//       farm.todayActivity['chickenDeaths'] is int
//           ? farm.todayActivity['chickenDeaths'] as int
//           : 0,
//     );
//   }

//   // Create eggs sheet for Excel
//   static Future<void> _createEggsSheet(Excel excel, Farm farm) async {
//     final sheet = excel['Tuxumlar'];

//     // Header
//     sheet.cell(CellIndex.indexByString('A1')).value = 'Sana';
//     sheet.cell(CellIndex.indexByString('B1')).value = 'Yigʻilgan';
//     sheet.cell(CellIndex.indexByString('C1')).value = 'Sotilgan';
//     sheet.cell(CellIndex.indexByString('D1')).value = 'Siniq';
//     sheet.cell(CellIndex.indexByString('E1')).value = 'Katta';

//     // Today's data
//     final todayActivity = farm.todayActivity;
//     sheet.cell(CellIndex.indexByString('A2')).value = _dateFormat.format(
//       DateTime.now(),
//     );
//     sheet.cell(CellIndex.indexByString('B2')).value =
//         todayActivity['eggsCollected'] ?? 0;
//     sheet.cell(CellIndex.indexByString('C2')).value =
//         todayActivity['eggsSold'] ?? 0;
//     sheet.cell(CellIndex.indexByString('D2')).value =
//         todayActivity['brokenEggs'] ?? 0;
//     sheet.cell(CellIndex.indexByString('E2')).value =
//         todayActivity['largeEggs'] ?? 0;
//   }

//   // Create customers sheet for Excel
//   static Future<void> _createCustomersSheet(Excel excel, Farm farm) async {
//     final sheet = excel['Mijozlar'];

//     // Header
//     sheet.cell(CellIndex.indexByString('A1')).value = 'Ism';
//     sheet.cell(CellIndex.indexByString('B1')).value = 'Telefon';
//     sheet.cell(CellIndex.indexByString('C1')).value = 'Manzil';
//     sheet.cell(CellIndex.indexByString('D1')).value = 'Qarzi (som)';

//     // Customer data
//     for (int i = 0; i < farm.customers.length; i++) {
//       final customer = farm.customers[i];
//       final row = i + 2;
//       sheet.cell(CellIndex.indexByString('A$row')).value = customer.name;
//       sheet.cell(CellIndex.indexByString('B$row')).value = customer.phone;
//       sheet.cell(CellIndex.indexByString('C$row')).value = customer.address;
//       sheet.cell(CellIndex.indexByString('D$row')).value = customer.totalDebt;
//     }
//   }

//   // Create sales sheet for Excel
//   static Future<void> _createSalesSheet(Excel excel, Farm farm) async {
//     final sheet = excel['Sotuvlar'];

//     // Header
//     sheet.cell(CellIndex.indexByString('A1')).value = 'Bugungi daromad';
//     sheet.cell(CellIndex.indexByString('B1')).value =
//         farm.todayActivity['dailyRevenue'] ?? 0;

//     sheet.cell(CellIndex.indexByString('A3')).value = 'Joriy zaxira';
//     sheet.cell(CellIndex.indexByString('B3')).value =
//         farm.farmStats['currentStock'] ?? 0;
//   }

//   // Create PDF summary page
//   static Future<pw.Page> _createPdfSummaryPage(Farm farm) async {
//     return pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       build: (pw.Context context) {
//         return pw.Container(
//           padding: const pw.EdgeInsets.all(40),
//           child: pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 'FERMA HISOBOTI',
//                 style: pw.TextStyle(
//                   fontSize: 24,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text('Ferma nomi: ${farm.name}'),
//               pw.Text('Hisobot sanasi: ${_dateFormat.format(DateTime.now())}'),
//               pw.SizedBox(height: 30),
//               pw.Text(
//                 'UMUMIY STATISTIKA',
//                 style: pw.TextStyle(
//                   fontSize: 18,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.SizedBox(height: 10),
//               ...farm.farmStats.entries.map(
//                 (entry) => pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(vertical: 2),
//                   child: pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text(entry.key),
//                       pw.Text(entry.value.toString()),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Create PDF chickens page
//   static Future<pw.Page> _createPdfChickensPage(Farm farm) async {
//     return pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       build: (pw.Context context) {
//         return pw.Container(
//           padding: const pw.EdgeInsets.all(40),
//           child: pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 'TOVUQLAR HISOBOTI',
//                 style: pw.TextStyle(
//                   fontSize: 20,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text('Jami tovuqlar: ${farm.farmStats['totalChickens'] ?? 0}'),
//               pw.Text(
//                 'Bugun oʻlgan tovuqlar: ${farm.todayActivity['chickenDeaths'] ?? 0}',
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Create PDF eggs page
//   static Future<pw.Page> _createPdfEggsPage(Farm farm) async {
//     return pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       build: (pw.Context context) {
//         final todayActivity = farm.todayActivity;
//         return pw.Container(
//           padding: const pw.EdgeInsets.all(40),
//           child: pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 'TUXUMLAR HISOBOTI',
//                 style: pw.TextStyle(
//                   fontSize: 20,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text(
//                 'Bugun yigʻilgan: ${todayActivity['eggsCollected'] ?? 0}',
//               ),
//               pw.Text('Bugun sotilgan: ${todayActivity['eggsSold'] ?? 0}'),
//               pw.Text('Siniq tuxumlar: ${todayActivity['brokenEggs'] ?? 0}'),
//               pw.Text('Katta tuxumlar: ${todayActivity['largeEggs'] ?? 0}'),
//               pw.Text('Joriy zaxira: ${farm.farmStats['currentStock'] ?? 0}'),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Create PDF customers page
//   static Future<pw.Page> _createPdfCustomersPage(Farm farm) async {
//     return pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       build: (pw.Context context) {
//         return pw.Container(
//           padding: const pw.EdgeInsets.all(40),
//           child: pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 'MIJOZLAR HISOBOTI',
//                 style: pw.TextStyle(
//                   fontSize: 20,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Table(
//                 border: pw.TableBorder.all(),
//                 children: [
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(
//                           'Ism',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(
//                           'Telefon',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(
//                           'Qarzi',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                   ...farm.customers.map(
//                     (customer) => pw.TableRow(
//                       children: [
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(customer.name),
//                         ),
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(customer.phone),
//                         ),
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(
//                             '${customer.totalDebt.toStringAsFixed(0)} som',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
