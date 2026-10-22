import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Générateur de rapport PDF (chapitres personnalisables, police Helvetica,
/// accents latins pris en charge ; l'arabe nécessite une police embarquée).
class PdfGenerator {
  /// Génère un PDF et retourne le chemin du fichier écrit.
  static Future<File> generate({
    required String title,
    required String internshipName,
    required String field,
    required String dateRange,
    required List<Map<String, String>> chapters, // {title, content}
    required DateTime generatedAt,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(2.54 * PdfPageFormat.cm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RAPPORT DE STAGE',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Stage : $internshipName',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Domaine : $field',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Période : $dateRange',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Généré le : ${_frDate(generatedAt)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Divider(),
              pw.SizedBox(height: 12),
              ...chapters.expand((chapter) => [
                    pw.Text(
                      chapter['title'] ?? '',
                      style: const pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(chapter['content'] ?? ''),
                    pw.SizedBox(height: 10),
                  ]),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Ce document a été généré par Rapport+ (hors-ligne). '
                'Les contenus proviennent exclusivement du journal de bord.',
                style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final file = File(await _outputPath());
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<String> _outputPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'rapport_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static String _frDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}