import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../database/app_database.dart';
import '../database_connection.dart';
import '../models/flashcard.dart';
import '../models/internship.dart';
import '../models/journal_entry.dart';
import '../models/report.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/speech_service.dart';

// ---------------------------------------------------------------------------
// Préferences partagées (overridden in main)
// ---------------------------------------------------------------------------
final prefsProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError('Override prefsProvider in main.dart');
});

/// Première ouverture : message d'accueil dans les Réglages, puis tableau de bord.
final firstLaunchProvider = Provider<bool>((ref) {
  final prefs = ref.read(prefsProvider);
  return prefs.getBool('first_launch') ?? true;
});

// ---------------------------------------------------------------------------
// Réglages
// ---------------------------------------------------------------------------
class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsOn;
  final int notificationHour;
  final bool aiAutoCorrection;
  final String localModelPath;
  final int modelSizeBytes;
  final bool driveConnected;
  final String? driveClientId;
  final String whatsappNumber;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsOn = true,
    this.notificationHour = 18,
    this.aiAutoCorrection = false,
    this.localModelPath = '',
    this.modelSizeBytes = 0,
    this.driveConnected = false,
    this.driveClientId,
    this.whatsappNumber = '+216 28671953',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsOn,
    int? notificationHour,
    bool? aiAutoCorrection,
    String? localModelPath,
    int? modelSizeBytes,
    bool? driveConnected,
    String? driveClientId,
    String? whatsappNumber,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsOn: notificationsOn ?? this.notificationsOn,
      notificationHour: notificationHour ?? this.notificationHour,
      aiAutoCorrection: aiAutoCorrection ?? this.aiAutoCorrection,
      localModelPath: localModelPath ?? this.localPath,
      modelSizeBytes: modelSizeBytes ?? this.modelSizeBytes,
      driveConnected: driveConnected ?? this.driveConnected,
      driveClientId: driveClientId ?? this.driveClientId,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
    );
  }

  // Compatibilité interne (évite une faute de frappe dans copyWith)
  String get localPath => localModelPath;
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this.prefs, this.db) : super(const SettingsState()) {
    _load();
  }

  final SharedPreferences prefs;
  final AppDatabase db;

  Future<void> _load() async {
    final theme = prefs.getString('theme_mode');
    final mode = theme == 'dark'
        ? ThemeMode.dark
        : theme == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
    final modelPath = prefs.getString('local_model_path') ?? '';
    final size = prefs.getInt('local_model_size') ?? 0;
    final clientId = prefs.getString('drive_client_id');
    state = state.copyWith(
      themeMode: mode,
      localModelPath: modelPath,
      modelSizeBytes: size,
      driveClientId: clientId,
      driveConnected: clientId != null && clientId.isNotEmpty,
    );
  }

  // Compatibilité avec l'ancien nom de champ utilisé par l'interface.
  String get localPath => localModelPath;

  Future<void> setThemeMode(ThemeMode mode) async {
    await prefs.setString('theme_mode', mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light ? 'light' : 'system');
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setNotifications(bool on) async {
    await prefs.setBool('notifications_on', on);
    state = state.copyWith(notificationsOn: on);
  }

  Future<void> setNotificationHour(int hour) async {
    await prefs.setInt('notification_hour', hour);
    state = state.copyWith(notificationHour: hour);
  }

  Future<void> setAutoCorrection(bool on) async {
    await prefs.setBool('ai_auto_correction', on);
    state = state.copyWith(aiAutoCorrection: on);
  }

  Future<void> setModelPath(String path, int size) async {
    await prefs.setString('local_model_path', path);
    await prefs.setInt('local_model_size', size);
    state = state.copyWith(localModelPath: path, modelSizeBytes: size);
  }

  Future<void> setDriveClientId(String? clientId) async {
    if (clientId == null) {
      await prefs.remove('drive_client_id');
    } else {
      await prefs.setString('drive_client_id', clientId);
    }
    state = state.copyWith(
      driveClientId: clientId,
      driveConnected: clientId != null && clientId.isNotEmpty,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.read(prefsProvider), appDatabase);
});

// ---------------------------------------------------------------------------
// Stages
// ---------------------------------------------------------------------------
class InternshipsNotifier extends StateNotifier<List<Internship>> {
  InternshipsNotifier(this.db) : super(const []) {
    load();
  }

  final AppDatabase db;

  Future<void> load() async {
    state = await db.getInternships();
  }

  Future<int> add(Internship internship) async {
    final id = await db.insertInternship(internship);
    await load();
    return id;
  }

  Future<void> update(Internship internship) async {
    await db.updateInternship(internship);
    await load();
  }

  Future<void> remove(int id) async {
    await db.deleteInternship(id);
    await load();
  }
}

final internshipsProvider =
    StateNotifierProvider<InternshipsNotifier, List<Internship>>((ref) {
  return InternshipsNotifier(appDatabase);
});

// ---------------------------------------------------------------------------
// Journal
// ---------------------------------------------------------------------------
class EntriesNotifier extends StateNotifier<List<JournalEntry>> {
  EntriesNotifier(this.db) : super(const []) {
    load();
  }

  final AppDatabase db;

  Future<void> load({int? internshipId, String? from, String? to}) async {
    state = await db.getEntries(
      internshipId: internshipId,
      from: from,
      to: to,
    );
  }

  Future<int> save(JournalEntry entry) async {
    final id = await db.saveEntry(entry);
    await load();
    return id;
  }

  Future<void> remove(int id) async {
    await db.deleteEntry(id);
    await load();
  }
}

final entriesProvider = StateNotifierProvider<EntriesNotifier, List<JournalEntry>>((ref) {
  return EntriesNotifier(appDatabase);
});

// ---------------------------------------------------------------------------
// Rapports
// ---------------------------------------------------------------------------
class ReportsNotifier extends StateNotifier<List<Report>> {
  ReportsNotifier(this.db) : super(const []) {
    load();
  }

  final AppDatabase db;

  Future<void> load() async {
    state = await db.getReports();
  }

  Future<int> add(Report report) async {
    final id = await db.insertReport(report);
    await load();
    return id;
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, List<Report>>((ref) {
  return ReportsNotifier(appDatabase);
});

// ---------------------------------------------------------------------------
// Fiches de révision (soutenance)
// ---------------------------------------------------------------------------
class FlashcardsNotifier extends StateNotifier<List<Flashcard>> {
  FlashcardsNotifier(this.db) : super(const []) {
    load();
  }

  final AppDatabase db;

  Future<void> load({int? internshipId, bool onlyDue = false}) async {
    state = await db.getFlashcards(internshipId: internshipId, onlyDue: onlyDue);
  }

  Future<int> add(Flashcard card) async {
    final id = await db.insertFlashcard(card);
    await load();
    return id;
  }

  Future<void> update(Flashcard card) async {
    await db.updateFlashcard(card);
    await load();
  }

  Future<void> remove(int id) async {
    await db.deleteFlashcard(id);
    await load();
  }
}

final flashcardsProvider =
    StateNotifierProvider<FlashcardsNotifier, List<Flashcard>>((ref) {
  return FlashcardsNotifier(appDatabase);
});

// ---------------------------------------------------------------------------
// Profil
// ---------------------------------------------------------------------------
class ProfileNotifier extends StateNotifier<UserProfile?> {
  ProfileNotifier(this.db) : super(null) {
    load();
  }

  final AppDatabase db;

  Future<void> load() async {
    state = await db.getProfile();
  }

  Future<void> save(UserProfile profile) async {
    await db.saveProfile(profile);
    state = profile;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>((ref) {
  return ProfileNotifier(appDatabase);
});

// ---------------------------------------------------------------------------
// Services partagés
// ---------------------------------------------------------------------------
final aiServiceProvider = Provider<AiService>((ref) => AiService());
final speechServiceProvider = Provider<SpeechService>((ref) => SpeechService());
final backupServiceProvider = Provider<BackupService>((ref) => BackupService());
final notificationServiceProvider = Provider<NotificationService>((ref) => notificationService);
