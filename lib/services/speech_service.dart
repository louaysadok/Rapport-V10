import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

/// Service d'enregistrement et de transcription vocale hors-ligne.
///
/// Compatible avec whisper.cpp / sherpa-onnx : le binaire de transcription
/// (ex. `whisper-cli` avec un modèle GGUF) peut être configuré via
/// [whisperCliPath]. En l'absence de binaire, [transcribe] retourne un
/// libellé de remplacement (le fichier audio reste disponible localement).
class SpeechService {
  SpeechService();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  /// Chemin du binaire whisper.cpp (vide = mode de secours).
  String whisperCliPath = '';
  /// Chemin du modèle whisper GGUF (vide = mode de secours).
  String whisperModelPath = '';

  /// Un enregistrement est-il en cours ?
  Future<bool> get isRecording async => _recorder.isRecording();

  /// Démarre l'enregistrement vers [path].
  Future<bool> startRecording(String path) async {
    try {
      await _recorder.start(const RecordConfig(), path: path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier audio.
  Future<String?> stopRecording() async {
    try {
      return await _recorder.stop();
    } catch (_) {
      return null;
    }
  }

  /// Lit le fichier audio [path].
  Future<void> play(String path) async {
    try {
      await _player.setFilePath(path);
      await _player.play();
    } catch (_) {}
  }

  /// Arrête la lecture.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Transcrit un fichier audio local avec whisper.cpp si disponible.
  /// Retourne null si aucun moteur de transcription n'est configuré.
  Future<String?> transcribe(String audioPath) async {
    final cli = whisperCliPath;
    final model = whisperModelPath;
    if (cli.isEmpty || !await File(cli).exists()) return null;
    if (model.isEmpty || !await File(model).exists()) return null;
    if (!await File(audioPath).exists()) return null;

    try {
      final result = await Process.run(
        cli,
        <String>['-m', model, '-f', audioPath, '-otxt'],
        workingDirectory: (await getApplicationDocumentsDirectory()).path,
      );
      if (result.exitCode != 0) return null;
      final text = result.stdout as String?;
      return text?.isNotEmpty == true ? text!.trim() : null;
    } catch (_) {
      return null;
    }
  }

  /// Chemin par défaut pour un nouvel enregistrement (documents de l'app).
  static Future<String> defaultRecordPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final recordings = Directory(p.join(dir.path, 'recordings'));
    if (!await recordings.exists()) await recordings.create(recursive: true);
    return p.join(recordings.path, 'record_${DateTime.now().millisecondsSinceEpoch}.m4a');
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
