/// Code généré par Drift (build_runner).
///
/// Ce fichier est l'équivalent du fichier produit par `drift_dev` pour la base
/// `AppDatabase`. Comme toutes les tables sont gérées par des requêtes SQL
/// brutes (maîtrise totale de FactGuard), la liste des tables générées est
/// vide : `allTables` retourne une liste vide et le schéma est créé explicitement
/// par `AppDatabase.init()` à partir de `lib/database/schema.dart`.
///
/// Fichier à régénérer avec : `flutter pub run build_runner build`
import 'package:drift/drift.dart';

/// Implémentation générée de la base de données.
///
/// `AppDatabase` étend cette classe et fournit `schemaVersion`.
abstract class _$AppDatabase extends GeneratedDatabase {
  /// Crée la base sur l'exécuteur de requêtes [e].
  _$AppDatabase(QueryExecutor e) : super(e);

  @override
  Iterable<TableInfo> get allTables => const <TableInfo>[];
}
