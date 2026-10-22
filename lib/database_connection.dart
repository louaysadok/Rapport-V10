import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'database/app_database.dart';

/// Ouvre (ou crée) la base de données locale Drift/SQLite.
Future<AppDatabase> openAppDatabase() async {
  // sqlite3_flutter_libs charge les bibliothèques natives SQLite (Android)
  // dès son importation.
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'rapport_plus.db'));
  return AppDatabase(NativeDatabase(file, logStatements: false));
}
