import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sauvegarde optionnelle vers Google Drive. Jamais forcée : l'utilisateur
/// peut ignorer (bouton "Passer") à tout moment.
class BackupService {
  BackupService();

  static const _scopes = <String>[drive.DriveApi.driveFileScope];

  /// Crée un client HTTP authentifié si un clientId est configuré.
  /// Retourne null si la sauvegarde Drive n'est pas configurée.
  ///
  /// L'URL de consentement est affichée par l'interface ; l'utilisateur
  /// termine la procédure et le client est réutilisé tant qu'il est valide.
  Future<http.Client?> _client(String clientId) async {
    if (clientId.isEmpty) return null;
    final credentials = await clientViaUserConsent(
      ClientId(clientId, ''),
      _scopes,
      (url) async {
        // L'application ouvre cette URL dans un navigateur web-view.
        return url;
      },
      prompt: 'select_account',
    );
    return credentials.client;
  }

  /// Exporte la base de données SQLite vers un fichier zip dans les documents
  /// de l'application (sauvegarde locale, sans Drive).
  Future<File> exportLocalBackup(String dbPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final backup = File(p.join(dir.path, 'rapport_plus_backup_${DateTime.now().millisecondsSinceEpoch}.zip'));
    // Minimaliste : on archive le fichier sqlite tel quel (extension .zip pour
    // cohérence avec l'import ultérieur).
    final bytes = File(dbPath).readAsBytesSync();
    backup.writeAsBytesSync(bytes);
    return backup;
  }

  /// Importe une sauvegarde locale vers [dbPath].
  Future<void> importLocalBackup(File backup, String dbPath) async {
    await File(dbPath).writeAsBytes(backup.readAsBytesSync());
  }

  /// Nom de fichier distant sur Drive.
  static String remoteFileName(String dbPath) =>
      'rapport_plus_${p.basenameWithoutExtension(dbPath)}.sqlite';
}


