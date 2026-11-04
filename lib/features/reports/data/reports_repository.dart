import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class ReportsRepository {
  final AppDatabase _db;

  ReportsRepository(this._db);

  /// Generate CSV report for transactions within period
  Future<String> exportTransactionsCsv({
    required DateTime startDate,
    required DateTime endDate,
    String? accountId,
    String? categoryId,
  }) async {
    final query = _db.select(_db.transactions)
      ..where((tbl) =>
          tbl.status.equals('completed') &
          tbl.transactionDate.isBiggerOrEqualValue(startDate) &
          tbl.transactionDate.isSmallerOrEqualValue(endDate));

    if (accountId != null) {
      query.where((tbl) => tbl.sourceAccountId.equals(accountId) | tbl.destinationAccountId.equals(accountId));
    }
    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId) | tbl.subcategoryId.equals(categoryId));
    }

    query.orderBy([(tbl) => OrderingTerm.asc(tbl.transactionDate)]);
    final txList = await query.get();

    final allAccounts = await _db.select(_db.accounts).get();
    final allCats = await _db.select(_db.categories).get();
    final accMap = {for (final a in allAccounts) a.id: a.name};
    final catMap = {for (final c in allCats) c.id: c.name};

    final List<List<dynamic>> rows = [
      ['Date', 'Type', 'Description', 'Amount (LKR)', 'Category', 'Account', 'Notes'],
    ];

    for (final tx in txList) {
      final accName = tx.sourceAccountId != null
          ? accMap[tx.sourceAccountId] ?? ''
          : (tx.destinationAccountId != null ? accMap[tx.destinationAccountId] ?? '' : '');
      final catName = tx.categoryId != null ? catMap[tx.categoryId] ?? '' : '';

      rows.add([
        DateFormatter.formatFullDate(tx.transactionDate),
        tx.type.toUpperCase(),
        tx.description,
        (tx.amount / AppConstants.centsFactor).toStringAsFixed(2),
        catName,
        accName,
        tx.notes ?? '',
      ]);
    }

    final csvData = csv.encode(rows);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'MyFinance_Report_${DateFormat('yyyyMMdd').format(startDate)}_to_${DateFormat('yyyyMMdd').format(endDate)}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvData);

    return file.path;
  }

  /// Generate PDF financial statement/summary report
  Future<String> exportFinancialReportPdf({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final txList = await (_db.select(_db.transactions)
          ..where((tbl) =>
              tbl.status.equals('completed') &
              tbl.transactionDate.isBiggerOrEqualValue(startDate) &
              tbl.transactionDate.isSmallerOrEqualValue(endDate))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.transactionDate)]))
        .get();

    int totalIncome = 0;
    int totalExpense = 0;
    for (final tx in txList) {
      if (tx.type == TransactionType.income.name) totalIncome += tx.amount;
      if (tx.type == TransactionType.expense.name) totalExpense += tx.amount;
    }
    final net = totalIncome - totalExpense;

    final accounts = await (_db.select(_db.accounts)..where((tbl) => tbl.isArchived.equals(false))).get();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MyFinance Statement',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                      ),
                      pw.Text(
                        'Period: ${DateFormatter.formatFullDate(startDate)} to ${DateFormatter.formatFullDate(endDate)}',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Generated: ${DateFormatter.formatFullDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount (LKR)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Income')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(CurrencyFormatter.formatCents(totalIncome), textAlign: pw.TextAlign.right)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Expenses')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(CurrencyFormatter.formatCents(totalExpense), textAlign: pw.TextAlign.right)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Net Cash Flow')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(CurrencyFormatter.formatCents(net), textAlign: pw.TextAlign.right)),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Account Balances', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Account', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Institution', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Current Balance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
                for (final acc in accounts)
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(acc.name)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(acc.institutionName)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.formatCents(acc.currentBalance), textAlign: pw.TextAlign.right)),
                  ]),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Text('Transaction Log (${txList.length} records)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
                for (final tx in txList.take(50))
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormatter.formatDate(tx.transactionDate), style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx.description, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx.type.toUpperCase(), style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.formatCents(tx.amount), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                  ]),
              ],
            ),
          ];
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'MyFinance_Statement_${DateFormat('yyyyMMdd').format(startDate)}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Share file via system share sheet
  Future<void> shareReport(String filePath, String subject) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: subject,
      ),
    );
  }
}
