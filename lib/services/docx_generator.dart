import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Générateur DOCX minimaliste (OpenXML valide, lisible par Word /
/// LibreOffice) sans dépendance externe. Les entrées ZIP sont stockées sans
/// compression (méthode 0).
class DocxGenerator {
  /// Génère un DOCX et retourne le chemin du fichier écrit.
  static Future<File> generate({
    required String title,
    required String internshipName,
    required String field,
    required String dateRange,
    required List<Map<String, String>> chapters, // {title, content}
    required DateTime generatedAt,
  }) async {
    final entries = <_ZipEntry>[];

    entries.add(_ZipEntry(
        '[Content_Types].xml', _utf8(_contentTypesXml())));
    entries.add(_ZipEntry('_rels/.rels', _utf8(_relsXml())));
    entries.add(_ZipEntry('word/document.xml',
        _utf8(_documentXml(title, internshipName, field, dateRange, chapters, generatedAt))));
    entries.add(_ZipEntry('word/_rels/document.xml.rels', _utf8('')));
    entries.add(_ZipEntry('docProps/core.xml', _utf8(_coreXml(title, generatedAt))));

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(
        dir.path, 'rapport_${DateTime.now().millisecondsSinceEpoch}.docx'));
    await file.writeAsBytes(_buildZip(entries));
    return file;
  }

  // -----------------------------------------------------------------------
  // XML parties
  // -----------------------------------------------------------------------

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static String _contentTypesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
  }

  static String _relsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
  }

  static String _coreXml(String title, DateTime generatedAt) {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                   xmlns:dc="http://purl.org/dc/elements/1.1/"
                   xmlns:dcterms="http://purl.org/dc/terms/">
  <dc:title>${_escape(title)}</dc:title>
  <dcterms:created xsi:type="dcterms:W3CDTF" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">${_escape(_isoDate(generatedAt))}</dcterms:created>
</cp:coreProperties>''';
  }

  static String _documentXml(
      String title,
      String internshipName,
      String field,
      String dateRange,
      List<Map<String, String>> chapters,
      DateTime generatedAt) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    buffer.writeln('  <w:body>');
    buffer.writeln('    <w:p><w:pPr><w:pStyle w:val="Title"/></w:pPr><w:r><w:t xml:space="preserve">RAPPORT DE STAGE</w:t></w:r></w:p>');
    buffer.writeln('    <w:p><w:r><w:t xml:space="preserve">${_escape(title)}</w:t></w:r></w:p>');
    buffer.writeln('    <w:p><w:r><w:t xml:space="preserve">Stage : ${_escape(internshipName)}</w:t></w:r></w:p>');
    buffer.writeln('    <w:p><w:r><w:t xml:space="preserve">Domaine : ${_escape(field)}</w:t></w:r></w:p>');
    buffer.writeln('    <w:p><w:r><w:t xml:space="preserve">Période : ${_escape(dateRange)}</w:t></w:r></w:p>');
    buffer.writeln('    <w:p><w:r><w:t xml:space="preserve">Généré le : ${_frDate(generatedAt)}</w:t></w:r></w:p>');
    buffer.writeln('    <w:p><w:r><w:br/></w:r></w:p>');
    for (final chapter in chapters) {
      buffer.writeln('    <w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t xml:space="preserve">${_escape(chapter['title'] ?? '')}</w:t></w:r></w:p>');
      final content = chapter['content'] ?? '';
      for (final line in content.split('\n')) {
        buffer.writeln('    <w:p><w:r><w:t xml:space="preserve">${_escape(line)}</w:t></w:r></w:p>');
      }
    }
    buffer.writeln('    <w:p><w:r><w:br/></w:r></w:p>');
    buffer.writeln('    <w:p><w:r><w:t xml:space="preserve">Ce document a été généré par Rapport+ (hors-ligne). Les contenus proviennent exclusivement du journal de bord.</w:t></w:r></w:p>');
    buffer.writeln('  </w:body>');
    buffer.writeln('</w:document>');
    return buffer.toString();
  }

  static String _isoDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}Z';
  }

  static String _frDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // -----------------------------------------------------------------------
  // ZIP (stockage sans compression, méthode 0)
  // -----------------------------------------------------------------------

  static List<int> _buildZip(List<_ZipEntry> entries) {
    final all = <int>[];
    final central = <int>[];
    int offset = 0;

    final now = DateTime.now();
    final dosTime = ((now.hour << 11) | (now.minute << 5) | (now.second ~/ 2)) & 0xFFFF;
    final dosDate = (((now.year - 1980) << 9) | (now.month << 5) | now.day) & 0xFFFF;

    for (final entry in entries) {
      final name = _utf8(entry.name);
      final data = entry.data;
      final crc = _crc32(data);
      final localHeader = _localHeader(crc, data.length, name.length, dosTime, dosDate);
      all.addAll(localHeader);
      all.addAll(name);
      all.addAll(data);

      final cen = _centralHeader(crc, data.length, name.length, offset, dosTime, dosDate);
      central.addAll(cen);
      central.addAll(name);
      offset += localHeader.length + name.length + data.length;
    }

    final eocd = <int>[]..length = 22;
    eocd[0] = 0x50; eocd[1] = 0x4B; eocd[2] = 0x05; eocd[3] = 0x06;
    _u16(eocd, 4, 0);      // disk number
    _u16(eocd, 6, 0);      // disk with central directory
    _u16(eocd, 8, entries.length);
    _u16(eocd, 10, entries.length);
    _u32(eocd, 12, central.length);
    _u32(eocd, 16, offset);
    _u16(eocd, 20, 0);     // comment length

    return [...all, ...central, ...eocd];
  }

  static List<int> _localHeader(int crc, int size, int nameLen, int time, int date) {
    final h = <int>[]..length = 30;
    h[0] = 0x50; h[1] = 0x4B; h[2] = 0x03; h[3] = 0x04;   // signature
    _u16(h, 4, 20);                                        // version needed
    _u16(h, 6, 0);                                         // flags
    _u16(h, 8, 0);                                         // method 0 = stored
    _u16(h, 10, time);
    _u16(h, 12, date);
    _u32(h, 14, crc);
    _u32(h, 18, size);
    _u32(h, 22, size);
    _u16(h, 26, nameLen);
    _u16(h, 28, 0);                                        // extra length
    return h;
  }

  static List<int> _centralHeader(int crc, int size, int nameLen, int offset,
      int time, int date) {
    final h = <int>[]..length = 46;
    h[0] = 0x50; h[1] = 0x4B; h[2] = 0x01; h[3] = 0x02;   // signature
    _u16(h, 4, 20);                                        // version made by
    _u16(h, 6, 20);                                        // version needed
    _u16(h, 8, 0);
    _u16(h, 10, 0);                                        // method 0
    _u16(h, 12, time);
    _u16(h, 14, date);
    _u32(h, 16, crc);
    _u32(h, 20, size);
    _u32(h, 24, size);
    _u16(h, 28, nameLen);
    _u16(h, 30, 0);
    _u16(h, 32, 0);
    _u16(h, 34, 0);
    _u16(h, 36, 0);
    _u32(h, 38, 0);                                        // internal attrs
    _u32(h, 42, 0);                                        // external attrs
    _u32(h, 46, offset);                                   // local header offset
    return h;
  }

  static void _u16(List<int> v, int pos, int value) {
    v[pos] = value & 0xFF;
    v[pos + 1] = (value >> 8) & 0xFF;
  }

  static void _u32(List<int> v, int pos, int value) {
    v[pos] = value & 0xFF;
    v[pos + 1] = (value >> 8) & 0xFF;
    v[pos + 2] = (value >> 16) & 0xFF;
    v[pos + 3] = (value >> 24) & 0xFF;
  }

  static int _crc32(List<int> data) {
    var v = 0xFFFFFFFF;
    for (final b in data) {
      v ^= b & 0xFF;
      for (var i = 0; i < 8; i++) {
        v = (v & 1) == 1 ? (0xEDB88320 ^ (v >> 1)) : (v >> 1);
      }
    }
    return v ^ 0xFFFFFFFF;
  }
}

class _ZipEntry {
  final String name;
  final List<int> data;
  _ZipEntry(this.name, this.data);
}

List<int> _utf8(String s) {
  // utf-8 encoder sans import de dart:convert (self-contained)
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    final code = s.codeUnitAt(i);
    if (code < 0x80) {
      out.add(code);
    } else if (code < 0x800) {
      out.add(0xC0 | (code >> 6));
      out.add(0x80 | (code & 0x3F));
    } else {
      out.add(0xE0 | (code >> 12));
      out.add(0x80 | ((code >> 6) & 0x3F));
      out.add(0x80 | (code & 0x3F));
    }
  }
  return out;
}
