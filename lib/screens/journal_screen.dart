import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../app_state.dart';
import '../models/internship.dart';
import '../models/journal_entry.dart';
import '../models/journal_media.dart';
import '../providers/app_providers.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/help_dialog.dart';

/// Questionnaire adaptatif selon le domaine professionnel.
List<String> adaptiveQuestions(String field) {
  final f = field.toLowerCase();
  final generique = <String>[
    'Qu’avez-vous observé aujourd’hui ?',
    'Qu’avez-vous réalisé vous-même aujourd’hui ?',
    'Quelles difficultés avez-vous rencontrées ?',
    'Quels sont vos objectifs pour demain ?',
  ];
  if (f.contains('info') ||
      f.contains('numéri') ||
      f.contains('dévelop') ||
      f.contains('informat')) {
    return <String>[
      'Quelles tâches techniques avez-vous réalisées aujourd’hui ?',
      'Quels outils, langages ou frameworks avez-vous utilisés ?',
      'Quels problèmes avez-vous rencontrés, et comment les avez-vous résolus ?',
      ...generique.skip(2),
    ];
  }
  if (f.contains('santé') ||
      f.contains('infirm') ||
      f.contains('médical') ||
      f.contains('paramédical') ||
      f.contains('soin')) {
    return <String>[
      'Quels soins ou accompagnements avez-vous dispensés aujourd’hui ? (anonymisé)',
      'Quels protocoles ou procédures avez-vous appliqués ?',
      'Comment s’est passée la communication avec l’équipe soignante ?',
      ...generique.skip(2),
    ];
  }
  if (f.contains('bâtiment') ||
      f.contains('btp') ||
      f.contains('génie civil') ||
      f.contains('construction')) {
    return <String>[
      'Quels chantiers ou ouvrages avez-vous suivis aujourd’hui ?',
      'Quelles normes de sécurité avez-vous appliquées ?',
      'Quels imprévus techniques sont survenus ?',
      ...generique.skip(2),
    ];
  }
  if (f.contains('commerc') || f.contains('vente') || f.contains('marketing')) {
    return <String>[
      'Quels clients ou prospects avez-vous rencontrés aujourd’hui ?',
      'Quelles actions commerciales avez-vous menées ?',
      'Quel retour terrain remontez-vous ?',
      ...generique.skip(2),
    ];
  }
  if (f.contains('éducation') || f.contains('enseign') || f.contains('school')) {
    return <String>[
      'Quelles séquences pédagogiques avez-vous animées aujourd’hui ?',
      'Comment les élèves ont-ils réagi ?',
      'Quelles adaptations avez-vous dû faire ?',
      ...generique.skip(2),
    ];
  }
  return generique;
}

class JournalScreen extends ConsumerStatefulWidget {
  final int? entryId;
  const JournalScreen({super.key, this.entryId});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _answersCtrl = <String, TextEditingController>{};

  Internship? _internship;
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  int _mood = 3;
  double _hours = 0;
  final List<JournalMedia> _media = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final internships = ref.read(internshipsProvider);
    if (widget.entryId == null) {
      if (internships.isNotEmpty) setState(() => _internship = internships.first);
      return;
    }
    final entry = await appDatabase.getEntry(widget.entryId!);
    if (entry == null) return;
    setState(() {
      _internship = internships.firstWhere((i) => i.id == entry.internshipId,
          orElse: () => internships.first);
      _date = entry.date;
      _titleCtrl.text = entry.title;
      _contentCtrl.text = entry.content;
      _mood = entry.mood;
      _hours = entry.hours;
      final answers = entry.answers();
      answers.forEach((k, v) {
        _answersCtrl[k] = TextEditingController(text: v.toString());
      });
    });
    _media.addAll(await appDatabase.getMediaForEntry(widget.entryId!));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    for (final c in _answersCtrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(MediaType type) async {
    final result = await ImagePicker().pickImage(
      source: type == MediaType.photo ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (result == null) return;
    await _addMediaFile(File(result.path), 'photo');
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    await _addMediaFile(File(result.files.single.path!), 'audio');
  }

  Future<void> _addMediaFile(File file, String type) async {
    final mime = _mimeFor(file.path);
    final entryId = widget.entryId;
    if (entryId == null) {
      // L'entrée doit exister avant d'attacher un média.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enregistrez d’abord l’entrée avant d’ajouter des médias.')),
      );
      return;
    }
    final media = JournalMedia(
      entryId: entryId,
      path: file.path,
      type: type,
      mimeType: mime,
      size: await file.length(),
      createdAt: DateTime.now(),
    );
    await appDatabase.insertMedia(media);
    setState(() => _media.addAll(await appDatabase.getMediaForEntry(entryId)));
  }

  String _mimeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.m4a') || lower.endsWith('.aac')) return 'audio/mp4';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return 'application/octet-stream';
  }

  Future<void> _removeMedia(int id) async {
    await appDatabase.deleteMedia(id);
    setState(() => _media.removeWhere((m) => m.id == id));
  }

  Future<void> _save() async {
    if (_internship == null || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un stage et saisissez le contenu.')),
      );
      return;
    }
    setState(() => _saving = true);
    final answers = <String, dynamic>{};
    _answersCtrl.forEach((k, v) => answers[k] = v.text);
    final entry = JournalEntry(
      id: widget.entryId,
      internshipId: _internship!.id!,
      date: _date,
      title: _titleCtrl.text,
      content: _contentCtrl.text,
      mood: _mood,
      hours: _hours,
    );
    entry.answers = answers;
    await ref.read(entriesProvider.notifier).save(entry);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final internships = ref.watch(internshipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId == null ? 'Nouvelle entrée' : 'Modifier l’entrée'),
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
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Internship>(
              value: _internship,
              items: internships
                  .map((i) => DropdownMenuItem(
                        value: i,
                        child: Text('${i.name}  (${i.field})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _internship = v),
              decoration: const InputDecoration(labelText: 'Stage'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: TextEditingController(text: _date),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _date = DateFormat('yyyy-MM-dd').format(picked));
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre (optionnel)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Activités de la journée (faits observés et réalisés)',
                hintText: 'Décrivez ce que vous avez vu et fait aujourd’hui.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Humeur :'),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _mood.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_mood / 5',
                    onChanged: (v) => setState(() => _mood = v.round()),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Heures :'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _hours.toStringAsFixed(1),
                    decoration: const InputDecoration(
                      labelText: 'h',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    onChanged: (v) => _hours = double.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Questionnaire adaptatif (${_internship?.field ?? 'général'})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...adaptiveQuestions(_internship?.field ?? '').map((q) {
              final ctrl = _answersCtrl.putIfAbsent(q, () => TextEditingController());
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: q,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Photo'),
                    onPressed: () => _pickMedia(MediaType.photo),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.mic),
                    label: const Text('Audio'),
                    onPressed: _pickAudio,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Médias attachés (${_media.length})',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._media.map((m) => ListTile(
                  leading: Icon(m.isPhoto
                      ? Icons.image
                      : m.isAudio
                          ? Icons.audiotrack
                          : Icons.videocam),
                  title: Text(m.path.split('/').last),
                  subtitle: Text('${m.type} · ${(m.size / 1024).toStringAsFixed(1)} Ko'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeMedia(m.id!),
                  ),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enregistrer l’entrée'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MediaType { photo, audio }


