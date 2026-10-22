import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../app_state.dart';
import '../models/internship.dart';
import '../models/journal_entry.dart';
import '../models/report.dart';
import '../providers/app_providers.dart';
import '../services/ai_service.dart';
import '../services/docx_generator.dart';
import '../services/fact_guard.dart';
import '../services/pdf_generator.dart';
import '../theme.dart';
import '../widgets/help_dialog.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  Internship? _internship;
  String _from = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
  String _to = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _title = 'Rapport de stage';
  final List<ChapterEditor> _chapters = [];
  bool _generating = false;

  static const List<String> defaultChapterTitles = <String>[
    'Présentation du stage',
    'Contexte et objectifs',
    'Activités réalisées',
    'Compétences mobilisées',
    'Évaluation et perspectives',
    'Annexes',
  ];

  @override
  void initState() {
    super.initState();
    _resetChapters();
  }

  void _resetChapters() {
    _chapters
      ..clear()
      ..addAll(defaultChapterTitles.map((t) => ChapterEditor(title: t, content: '')));
  }

  Future<List<JournalEntry>> _facts() async {
    return await appDatabase.getEntries(
      internshipId: _internship?.id,
      from: _from,
      to: _to,
    );
  }

  Future<void> _generateWithAI() async {
    final entries = await _facts();
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune entrée de journal sur la période.')),
      );
      return;
    }
    final facts = <String>[];
    for (final e in entries) {
      facts.add('${e.date} - ${e.title} : ${e.content}');
      e.answers().forEach((k, v) => facts.add('$k : $v'));
    }
    setState(() => _generating = true);
    try {
      final text = await ref.read(aiServiceProvider).generateReportFrench(
            internshipName: _internship?.name ?? 'Stage',
            field: _internship?.field ?? '',
            facts: facts,
          );
      final guarded = FactGuard(facts: facts).annotate(text);
      // Répartit les paragraphes sur les chapitres.
      final paragraphs = guarded.split(RegExp(r'\n\s*\n')).where((s) => s.trim().isNotEmpty).toList();
      for (var i = 0; i < _chapters.length; i++) {
        if (i < paragraphs.length) {
          _chapters[i] = _chapters[i].copyWith(content: paragraphs[i].trim());
        }
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de génération : $e')),
      );
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _export(String format) async {
    final chapters = _chapters.where((c) => c.included).map((c) => <String, String>{
      'title': c.title,
      'content': c.content,
    }).toList();
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un chapitre.')),
      );
      return;
    }
    final dateRange = '$_from → $_to';
    final dir = await _docsDir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    File file;
    if (format == 'pdf') {
      file = await PdfGenerator.generate(
        title: _title,
        internshipName: _internship?.name ?? '',
        field: _internship?.field ?? '',
        dateRange: dateRange,
        chapters: chapters,
        generatedAt: DateTime.now(),
      );
    } else if (format == 'docx') {
      file = await DocxGenerator.generate(
        title: _title,
        internshipName: _internship?.name ?? '',
        field: _internship?.field ?? '',
        dateRange: dateRange,
        chapters: chapters,
        generatedAt: DateTime.now(),
      );
    } else {
      // XML
      final xml = _buildXml(chapters, dateRange);
      file = File('$dir/rapport_$ts.xml')..writeAsStringSync(xml);
    }
    await ref.read(reportsProvider.notifier).add(Report(
      title: _title,
      internshipId: _internship?.id,
      dateRange: dateRange,
      generatedAt: DateTime.now(),
      format: format,
      path: file.path,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exporté : ${file.path}')),
      );
    }
  }

  Future<String> _docsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  String _buildXml(List<Map<String, String>> chapters, String dateRange) {
    final b = StringBuffer();
    b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    b.writeln('<rapport>');
    b.writeln('  <titre>${_escape(_title)}</titre>');
    b.writeln('  <periode>${_escape(dateRange)}</periode>');
    b.writeln('  <date>${DateFormat('yyyy-MM-dd').format(DateTime.now())}</date>');
    b.writeln('  <chapitres>');
    for (final c in chapters) {
      b.writeln('    <chapitre>');
      b.writeln('      <titre>${_escape(c['title'] ?? '')}</titre>');
      b.writeln('      <contenu><![CDATA[${c['content'] ?? ''}]]></contenu>');
      b.writeln('    </chapitre>');
    }
    b.writeln('  </chapitres>');
    b.writeln('</rapport>');
    return b.toString();
  }

  String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport de stage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const HelpDialog(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<Internship>(
            value: _internship,
            hint: const Text('Stage (optionnel)'),
            items: ref.watch(internshipsProvider)
                .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text('${i.name} (${i.field})'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _internship = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _from,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Du'),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.tryParse(_from) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (d != null) setState(() => _from = DateFormat('yyyy-MM-dd').format(d));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _to,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Au'),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.tryParse(_to) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (d != null) setState(() => _to = DateFormat('yyyy-MM-dd').format(d));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _title,
            decoration: const InputDecoration(labelText: 'Titre du rapport'),
            onChanged: (v) => _title = v,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chapitres', style: Theme.of(context).textTheme.titleMedium),
              if (!_generating)
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Générer avec l\'IA'),
                  onPressed: _generateWithAI,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._chapters.map((c) => Card(
                child: CheckboxListTile(
                  title: TextFormField(
                    initialValue: c.title,
                    onChanged: (v) {
                      final idx = _chapters.indexOf(c);
                      _chapters[idx] = c.copyWith(title: v ?? '');
                    },
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  ),
                  subtitle: c.content.isEmpty ? const Text('(vide)') : null,
                  value: c.included,
                  onChanged: (v) {
                    final idx = _chapters.indexOf(c);
                    _chapters[idx] = c.copyWith(included: v ?? false);
                  },
                  secondary: InkWell(
                    onTap: () => _editChapter(c),
                    child: const Icon(Icons.edit),
                  ),
                ),
              )),
          const SizedBox(height: 16),
          if (_generating)
            const Center(child: CircularProgressIndicator()),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  onPressed: _generating ? null : () => _export('pdf'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.description),
                  label: const Text('DOCX'),
                  onPressed: _generating ? null : () => _export('docx'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.code),
                  label: const Text('XML'),
                  onPressed: _generating ? null : () => _export('xml'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Rapports générés', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...ref.watch(reportsProvider).map((r) => ListTile(
                leading: Icon(r.format == 'pdf' ? Icons.picture_as_pdf : Icons.description),
                title: Text(r.title),
                subtitle: Text('${r.format.toUpperCase()} · ${r.dateRange ?? ''}'),
                trailing: Text(_frDate(r.generatedAt)),
              )),
        ],
      ),
    );
  }

  void _editChapter(ChapterEditor c) {
    final ctrl = TextEditingController(text: c.content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Éditer : ${c.title}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: TextFormField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final idx = _chapters.indexOf(c);
              _chapters[idx] = c.copyWith(content: ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String _frDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class ChapterEditor {
  final String title;
  String content;
  final bool included;
  ChapterEditor({required this.title, required this.content, this.included = true});
  ChapterEditor copyWith({String? title, String? content, bool? included}) =>
      ChapterEditor(title: title ?? this.title, content: content ?? this.content, included: included ?? this.included);
}

