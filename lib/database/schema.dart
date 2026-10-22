/// Schéma SQL de la base locale (Drift, géré via requêtes brutes).
class Schema {
  static const int version = 1;

  static const List<String> createStatements = <String>[
    // Stages / missions (tous domaines professionnels)
    '''
    CREATE TABLE IF NOT EXISTS internships (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      field TEXT NOT NULL DEFAULT '',
      supervisor TEXT NOT NULL DEFAULT '',
      location TEXT NOT NULL DEFAULT '',
      description TEXT NOT NULL DEFAULT '',
      start_date INTEGER,
      end_date INTEGER,
      created_at INTEGER NOT NULL
    );
    ''',
    // Entrées du journal de bord (une par jour et par stage)
    '''
    CREATE TABLE IF NOT EXISTS journal_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      internship_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      title TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      mood INTEGER NOT NULL DEFAULT 3,
      hours REAL NOT NULL DEFAULT 0,
      meta TEXT NOT NULL DEFAULT '{}',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (internship_id) REFERENCES internships(id)
    );
    ''',
    // Médias attachés aux entrées (photo / vidéo / audio)
    '''
    CREATE TABLE IF NOT EXISTS journal_media (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entry_id INTEGER NOT NULL,
      path TEXT NOT NULL,
      type TEXT NOT NULL,
      mime_type TEXT NOT NULL DEFAULT '',
      size INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (entry_id) REFERENCES journal_entries(id)
    );
    ''',
    // Fiches de révision pour le jury (soutenance)
    '''
    CREATE TABLE IF NOT EXISTS flashcards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      internship_id INTEGER,
      question TEXT NOT NULL,
      answer TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT '',
      ease REAL NOT NULL DEFAULT 2.5,
      interval INTEGER NOT NULL DEFAULT 0,
      repetitions INTEGER NOT NULL DEFAULT 0,
      due_date INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    );
    ''',
    // Rapports générés et exportés
    '''
    CREATE TABLE IF NOT EXISTS reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      internship_id INTEGER,
      date_range TEXT,
      generated_at INTEGER NOT NULL,
      format TEXT NOT NULL,
      path TEXT NOT NULL
    );
    ''',
    // Préférences / état de l'application (clé/valeur)
    '''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
    ''',
  ];

  static String settingKey(String key) => key;
}
