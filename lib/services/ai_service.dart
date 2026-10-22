import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gestionnaire de modèles locaux IA (llama.cpp, GGUF).
///
/// Modèle par défaut : Qwen2.5-3B-Instruct quantifié Q4_K_M (~1,9 Go).
/// Le téléchargement n'est jamais forcé. Si le modèle est absent ou trop
/// volumineux, on peut basculer sur un modèle plus petit
/// (ex: Qwen2.5-0.5B-Instruct Q4_K_M).
class ModelManager {
  const ModelManager();

  /// Répertoire où sont stockés les modèles GGUF (documents de l'app).
  static Future<String> get modelsDir async {
    final dir = await getApplicationDocumentsDirectory();
    final models = Directory(p.join(dir.path, 'models'));
    if (!await models.exists()) await models.create(recursive: true);
    return models.path;
  }

  /// Chemin par défaut du modèle Qwen2.5-3B-Instruct Q4_K_M.
  static Future<String> get defaultModelPath async =>
      p.join(await modelsDir, 'qwen2.5-3b-instruct-q4_k_m.gguf');

  /// Modèle de secours plus petit.
  static Future<String> get fallbackModelPath async =>
      p.join(await modelsDir, 'qwen2.5-0.5b-instruct-q4_k_m.gguf');

  /// Liste les modèles GGUF disponibles avec leur taille.
  static Future<List<ModelInfo>> listModels() async {
    final dir = Directory(await modelsDir);
    if (!await dir.exists()) return const [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.gguf'))
        .map((f) => ModelInfo(
            name: f.path.split(Platform.pathSeparator).last,
            path: f.path,
            sizeBytes: await f.length()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

/// Information sur un modèle GGUF local.
class ModelInfo {
  final String name;
  final String path;
  final int sizeBytes;

  const ModelInfo({required this.name, required this.path, required this.sizeBytes});

  String get sizeDisplay {
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} Ko';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} Mo';
    return '${(mb / 1024).toStringAsFixed(2)} Go';
  }
}

/// Statut des modèles locaux (interface Réglages > Modèles locaux).
class ModelStatus {
  final bool defaultModelPresent;
  final bool fallbackModelPresent;
  final List<ModelInfo> models;
  final int defaultSizeBytes;

  const ModelStatus({
    required this.defaultModelPresent,
    required this.fallbackModelPresent,
    required this.models,
    required this.defaultSizeBytes,
  });
}

/// Taille estimée du modèle Qwen2.5-3B-Instruct Q4_K_M (environ 1,9 Go).
const int kDefaultModelSizeBytes = 1_900_000_000;

/// Service d'IA locale via llama.cpp (GGUF Qwen2.5-3B-Instruct Q4_K_M).
///
/// Le binaire `llama-cli` compilé pour Android doit être placé par
/// l'utilisateur dans le répertoire des modèles. En l'absence du binaire,
/// le service retourne une réponse de secours construite exclusivement à
/// partir des faits fournis (jamais d'invention "observé → réalisé").
class AiService {
  AiService();

  /// Chemin configuré du binaire llama-cli (vide = mode de secours).
  String llamaCliPath = '';

  /// Génère une complétion à partir de [prompt] avec le modèle [modelPath].
  /// Retourne null si aucune exécution locale n'est possible.
  Future<String?> generate({
    required String prompt,
    required String modelPath,
    int nCtx = 4096,
    int nPredict = 512,
    double temperature = 0.3,
    int seed = -1,
  }) async {
    final binary = llamaCliPath.isNotEmpty ? llamaCliPath : await _defaultLlamaCli();
    if (binary.isEmpty || !await File(binary).exists()) return null;
    if (!await File(modelPath).exists()) return null;

    final args = <String>[
      '-m', modelPath,
      '-c', nCtx.toString(),
      '-n', nPredict.toString(),
      '--temp', temperature.toString(),
      '-p', prompt,
    ];
    if (seed >= 0) {
      args.addAll(<String>['--seed', seed.toString()]);
    }

    try {
      final result = await Process.run(
        binary,
        args,
        workingDirectory: await ModelManager.modelsDir,
      );
      if (result.exitCode != 0) return null;
      return result.stdout;
    } catch (_) {
      return null;
    }
  }

  Future<String> _defaultLlamaCli() async {
    final dir = await ModelManager.modelsDir;
    for (final name in <String>['llama-cli', 'llama-cli-android']) {
      final c = p.join(dir, name);
      if (await File(c).exists()) return c;
    }
    return '';
  }

  /// Génère le corps d'un rapport de stage en français à partir des faits
  /// collectés dans le journal de bord. Aucune phrase n'est inventée :
  /// seules les activités consignées sont rapportées. Le résultat doit être
  /// passé au FactGuard avant export.
  Future<String> generateReportFrench({
    required String internshipName,
    required String field,
    required List<String> facts,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Rapport de stage - $internshipName');
    buffer.writeln('Domaine professionnel : $field');
    buffer.writeln('Date de génération : ${_frDate(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('Contexte : stage effectué dans le domaine $field.');
    buffer.writeln();
    if (facts.isEmpty) {
      buffer.writeln('Aucune activité n\'a encore été consignée dans le journal de bord.');
      buffer.writeln();
      buffer.writeln('Ce rapport ne contient que des faits issus du journal de bord.');
      return buffer.toString();
    }
    buffer.writeln('Activités observées et réalisées au cours du stage :');
    for (final fact in facts) {
      buffer.writeln('• $fact');
    }
    buffer.writeln();
    buffer.writeln('Ces éléments sont issus exclusivement des entrées du journal de bord.');
    buffer.writeln('Toute affirmation ne figurant pas dans le journal doit être vérifiée.');
    return buffer.toString();
  }

  /// Forme une réponse de conversation concise à partir des faits fournis.
  Future<String> chatFrench({
    required String question,
    required List<String> facts,
  }) async {
    final buffer = StringBuffer();
    if (facts.isEmpty) {
      buffer.writeln(
          'Je n\'ai aucune information enregistrée pour répondre à cette question.');
      return buffer.toString();
    }
    buffer.writeln('D’après les éléments de votre journal de bord :');
    for (final fact in facts) {
      buffer.writeln('• $fact');
    }
    return buffer.toString();
  }
}

String _frDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
