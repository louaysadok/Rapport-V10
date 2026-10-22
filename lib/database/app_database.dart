import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/flashcard.dart';
import '../models/internship.dart';
import '../models/journal_entry.dart';
import '../models/journal_media.dart';
import '../models/report.dart';
import '../models/user_profile.dart';
import 'app_database.g.dart';
import 'schema.dart';

/// Base de données locale hors-ligne (SQLite via Drift).
///
/// Toutes les données sont manipulées avec du SQL brut afin de garantir
/// que jamais aucun contenu "observé" ne soit transformé en contenu "réalisé"
/// par l'IA (FactGuard). Drift sert de couche de connexion et de typage.
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => Schema.version;

  /// Crée toutes les tables si nécessaire. À appeler une fois au démarrage.
  Future<void> init() async {
    for (final statement in Schema.createStatements) {
      await customUpdate(statement);
    }
  }

  // -------------------------------------------------------------------------
  // Stages
  // -------------------------------------------------------------------------

  Future<List<Internship>> getInternships() async {
    final rows = await customSelect(
      'SELECT * FROM internships ORDER BY name COLLATE NOCASE',
    ).get();
    return rows
        .map((r) => Internship(
              id: r.readNullable<int>('id'),
              name: r.read<String>('name'),
              field: r.read<String>('field'),
              supervisor: r.read<String>('supervisor'),
              location: r.read<String>('location'),
              description: r.read<String>('description'),
              startDate: r.readNullable<int>('start_date') != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      r.readNullable<int>('start_date')!)
                  : null,
              endDate: r.readNullable<int>('end_date') != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      r.readNullable<int>('end_date')!)
                  : null,
              createdAt: r.readNullable<int>('created_at') != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      r.readNullable<int>('created_at')!)
                  : DateTime.now(),
            ))
        .toList();
  }

  Future<Internship?> getInternship(int id) async {
    final rows = await customSelect(
      'SELECT * FROM internships WHERE id = ?',
      arguments: [Variable(id)],
    ).get();
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Internship(
      id: r.readNullable<int>('id'),
      name: r.read<String>('name'),
      field: r.read<String>('field'),
      supervisor: r.read<String>('supervisor'),
      location: r.read<String>('location'),
      description: r.read<String>('description'),
      startDate: r.readNullable<int>('start_date') != null
          ? DateTime.fromMillisecondsSinceEpoch(
              r.readNullable<int>('start_date')!)
          : null,
      endDate: r.readNullable<int>('end_date') != null
          ? DateTime.fromMillisecondsSinceEpoch(
              r.readNullable<int>('end_date')!)
          : null,
      createdAt: r.readNullable<int>('created_at') != null
          ? DateTime.fromMillisecondsSinceEpoch(
              r.readNullable<int>('created_at')!)
          : DateTime.now(),
    );
  }

  Future<int> insertInternship(Internship internship) async {
    return await customInsert(
      '''
      INSERT INTO internships (name, field, supervisor, location, description, start_date, end_date, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      arguments: <Variable>[
        Variable(internship.name),
        Variable(internship.field),
        Variable(internship.supervisor),
        Variable(internship.location),
        Variable(internship.description),
        Variable(internship.startDate?.millisecondsSinceEpoch ?? 0),
        Variable(internship.endDate?.millisecondsSinceEpoch ?? 0),
        Variable(internship.createdAt.millisecondsSinceEpoch),
      ],
    );
  }

  Future<int> updateInternship(Internship internship) async {
    return await customUpdate(
      '''
      UPDATE internships SET name = ?, field = ?, supervisor = ?, location = ?,
        description = ?, start_date = ?, end_date = ?
      WHERE id = ?
      ''',
      arguments: <Variable>[
        Variable(internship.name),
        Variable(internship.field),
        Variable(internship.supervisor),
        Variable(internship.location),
        Variable(internship.description),
        Variable(internship.startDate?.millisecondsSinceEpoch ?? 0),
        Variable(internship.endDate?.millisecondsSinceEpoch ?? 0),
        Variable(internship.id!),
      ],
    );
  }

  Future<int> deleteInternship(int id) async {
    return await customUpdate('DELETE FROM internships WHERE id = ?', [Variable(id)]);
  }

  // -------------------------------------------------------------------------
  // Entrées de journal
  // -------------------------------------------------------------------------

  Future<List<JournalEntry>> getEntries({
    int? internshipId,
    String? from,
    String? to,
  }) async {
    final buffer = StringBuffer(
      'SELECT * FROM journal_entries WHERE 1 = 1',
    );
    final args = <Variable>[];
    if (internshipId != null) {
      buffer.write(' AND internship_id = ?');
      args.add(Variable(internshipId));
    }
    if (from != null) {
      buffer.write(' AND date >= ?');
      args.add(Variable(from));
    }
    if (to != null) {
      buffer.write(' AND date <= ?');
      args.add(Variable(to));
    }
    buffer.write(' ORDER BY date DESC, id DESC');
    final rows = await customSelect(buffer.toString(), arguments: args).get();
    return rows.map((r) => _entryFromRow(r)).toList();
  }

  Future<JournalEntry?> getEntry(int id) async {
    final rows = await customSelect(
      'SELECT * FROM journal_entries WHERE id = ?',
      arguments: [Variable(id)],
    ).get();
    if (rows.isEmpty) return null;
    return _entryFromRow(rows.first);
  }

  JournalEntry _entryFromRow(QueryRow r) {
    return JournalEntry(
      id: r.readNullable<int>('id'),
      internshipId: r.read<int>('internship_id'),
      date: r.read<String>('date'),
      title: r.read<String>('title'),
      content: r.read<String>('content'),
      mood: r.read<int>('mood'),
      hours: r.read<double>('hours'),
      meta: r.read<String>('meta'),
      createdAt: r.readNullable<int>('created_at') != null
          ? DateTime.fromMillisecondsSinceEpoch(
              r.readNullable<int>('created_at')!)
          : DateTime.now(),
      updatedAt: r.readNullable<int>('updated_at') != null
          ? DateTime.fromMillisecondsSinceEpoch(
              r.readNullable<int>('updated_at')!)
          : DateTime.now(),
    );
  }

  /// Insère une entrée et retourne son id.
  /// Une entrée existante pour le même (stage, date) est mise à jour.
  Future<int> saveEntry(JournalEntry entry) async {
    final existing = await customSelect(
      'SELECT id FROM journal_entries WHERE internship_id = ? AND date = ?',
      arguments: [Variable(entry.internshipId), Variable(entry.date)],
    ).get();
    if (existing.isNotEmpty) {
      final existingId = existing.first.read<int>('id');
      await customUpdate(
        '''
        UPDATE journal_entries SET title = ?, content = ?, mood = ?, hours = ?,
          meta = ?, updated_at = ?
        WHERE id = ?
        ''',
        arguments: <Variable>[
          Variable(entry.title),
          Variable(entry.content),
          Variable(entry.mood),
          Variable(entry.hours),
          Variable(entry.meta),
          Variable(DateTime.now().millisecondsSinceEpoch),
          Variable(existingId),
        ],
      );
      return existingId;
    }
    return await customInsert(
      '''
      INSERT INTO journal_entries (internship_id, date, title, content, mood, hours, meta, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      arguments: <Variable>[
        Variable(entry.internshipId),
        Variable(entry.date),
        Variable(entry.title),
        Variable(entry.content),
        Variable(entry.mood),
        Variable(entry.hours),
        Variable(entry.meta),
        Variable(entry.createdAt.millisecondsSinceEpoch),
        Variable(entry.updatedAt.millisecondsSinceEpoch),
      ],
    );
  }

  Future<int> deleteEntry(int id) async {
    await customUpdate('DELETE FROM journal_media WHERE entry_id = ?', [Variable(id)]);
    return await customUpdate('DELETE FROM journal_entries WHERE id = ?', [Variable(id)]);
  }

  // -------------------------------------------------------------------------
  // Médias
  // -------------------------------------------------------------------------

  Future<List<JournalMedia>> getMediaForEntry(int entryId) async {
    final rows = await customSelect(
      'SELECT * FROM journal_media WHERE entry_id = ? ORDER BY created_at',
      arguments: [Variable(entryId)],
    ).get();
    return rows
        .map((r) => JournalMedia(
              id: r.readNullable<int>('id'),
              entryId: r.read<int>('entry_id'),
              path: r.read<String>('path'),
              type: r.read<String>('type'),
              mimeType: r.read<String>('mime_type'),
              size: r.read<int>('size'),
              createdAt: r.readNullable<int>('created_at') != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      r.readNullable<int>('created_at')!)
                  : DateTime.now(),
            ))
        .toList();
  }

  Future<int> insertMedia(JournalMedia media) async {
    return await customInsert(
      '''
      INSERT INTO journal_media (entry_id, path, type, mime_type, size, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      arguments: <Variable>[
        Variable(media.entryId),
        Variable(media.path),
        Variable(media.type),
        Variable(media.mimeType),
        Variable(media.size),
        Variable(media.createdAt.millisecondsSinceEpoch),
      ],
    );
  }

  Future<int> deleteMedia(int id) async {
    return await customUpdate('DELETE FROM journal_media WHERE id = ?', [Variable(id)]);
  }

  // -------------------------------------------------------------------------
  // Fiches de révision (soutenance / jury)
  // -------------------------------------------------------------------------

  Future<List<Flashcard>> getFlashcards({int? internshipId, bool onlyDue = false}) async {
    final buffer = StringBuffer('SELECT * FROM flashcards WHERE 1 = 1');
    final args = <Variable>[];
    if (internshipId != null) {
      buffer.write(' AND internship_id = ?');
      args.add(Variable(internshipId));
    }
    if (onlyDue) {
      buffer.write(' AND due_date <= ?');
      args.add(Variable(DateTime.now().millisecondsSinceEpoch));
    }
    buffer.write(' ORDER BY due_date ASC, id ASC');
    final rows = await customSelect(buffer.toString(), arguments: args).get();
    return rows.map((r) => _cardFromRow(r)).toList();
  }

  Flashcard _cardFromRow(QueryRow r) {
    return Flashcard(
      id: r.readNullable<int>('id'),
      internshipId: r.readNullable<int>('internship_id'),
      question: r.read<String>('question'),
      answer: r.read<String>('answer'),
      category: r.read<String>('category'),
      ease: r.read<double>('ease'),
      interval: r.read<int>('interval'),
      repetitions: r.read<int>('repetitions'),
      dueDate: r.read<int>('due_date'),
      createdAt: r.readNullable<int>('created_at') != null
          ? DateTime.fromMillisecondsSinceEpoch(
              r.readNullable<int>('created_at')!)
          : DateTime.now(),
    );
  }

  Future<int> insertFlashcard(Flashcard card) async {
    return await customInsert(
      '''
      INSERT INTO flashcards (internship_id, question, answer, category, ease, interval, repetitions, due_date, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      arguments: <Variable>[
        Variable(card.internshipId ?? 0),
        Variable(card.question),
        Variable(card.answer),
        Variable(card.category),
        Variable(card.ease),
        Variable(card.interval),
        Variable(card.repetitions),
        Variable(card.dueDate),
        Variable(card.createdAt.millisecondsSinceEpoch),
      ],
    );
  }

  Future<int> updateFlashcard(Flashcard card) async {
    return await customUpdate(
      '''
      UPDATE flashcards SET question = ?, answer = ?, category = ?, ease = ?,
        interval = ?, repetitions = ?, due_date = ?
      WHERE id = ?
      ''',
      arguments: <Variable>[
        Variable(card.question),
        Variable(card.answer),
        Variable(card.category),
        Variable(card.ease),
        Variable(card.interval),
        Variable(card.repetitions),
        Variable(card.dueDate),
        Variable(card.id!),
      ],
    );
  }

  Future<int> deleteFlashcard(int id) async {
    return await customUpdate('DELETE FROM flashcards WHERE id = ?', [Variable(id)]);
  }

  // -------------------------------------------------------------------------
  // Rapports générés
  // -------------------------------------------------------------------------

  Future<List<Report>> getReports() async {
    final rows = await customSelect(
      'SELECT * FROM reports ORDER BY generated_at DESC',
    ).get();
    return rows
        .map((r) => Report(
              id: r.readNullable<int>('id'),
              title: r.read<String>('title'),
              internshipId: r.readNullable<int>('internship_id'),
              dateRange: r.readNullable<String>('date_range'),
              generatedAt: r.readNullable<int>('generated_at') != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      r.readNullable<int>('generated_at')!)
                  : DateTime.now(),
              format: r.read<String>('format'),
              path: r.read<String>('path'),
            ))
        .toList();
  }

  Future<int> insertReport(Report report) async {
    return await customInsert(
      '''
      INSERT INTO reports (title, internship_id, date_range, generated_at, format, path)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      arguments: <Variable>[
        Variable(report.title),
        Variable(report.internshipId ?? 0),
        Variable(report.dateRange ?? ''),
        Variable(report.generatedAt.millisecondsSinceEpoch),
        Variable(report.format),
        Variable(report.path),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Profil utilisateur (une seule ligne, clé 'profile')
  // -------------------------------------------------------------------------

  Future<UserProfile?> getProfile() async {
    final rows = await customSelect(
      "SELECT value FROM app_settings WHERE key = 'profile'",
    ).get();
    if (rows.isEmpty) return null;
    final value = rows.first.readNullable<String>('value');
    if (value == null) return null;
    return UserProfile.fromMap(jsonDecode(value) as Map<String, dynamic>)
        .copyWith(id: 'profile');
  }

  Future<int> saveProfile(UserProfile profile) async {
    final value = jsonEncode(profile.toMap()..remove('id'));
    return await customUpdate(
      '''
      INSERT INTO app_settings (key, value) VALUES ('profile', ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      arguments: [Variable(value)],
    );
  }

  // -------------------------------------------------------------------------
  // Paramètres généraux (clé/valeur texte)
  // -------------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    final rows = await customSelect(
      'SELECT value FROM app_settings WHERE key = ?',
      arguments: [Variable(key)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.readNullable<String>('value');
  }

  Future<int> setSetting(String key, String value) async {
    return await customUpdate(
      '''
      INSERT INTO app_settings (key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      arguments: [Variable(key), Variable(value)],
    );
  }
}
