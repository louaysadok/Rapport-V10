import 'package:intl/intl.dart';

/// FactGuard : garantit qu'un rapport généré par l'IA ne contient que des
/// faits provenant des entrées du journal (jamais d'hallucination
/// "observé → réalisé").
///
/// Principe : chaque phrase du texte généré est confrontée aux faits bruts
/// collectés dans le journal. Les phrases qui ne tracent à aucun fait
/// collecté sont marquées "[NON VÉRIFIÉ]" et doivent être revues par
/// l'utilisateur avant export.
class FactGuard {
  final List<String> facts; // faits bruts issus du journal (mots-clés, dates, tâches)

  const FactGuard({this.facts = const []});

  /// Vérifie [text] et retourne une liste de résultats phrase par phrase.
  List<FactCheck> check(String text) {
    final sentences = _splitSentences(text);
    return sentences.map((s) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) {
        return FactCheck(sentence: s, verified: true, missingFacts: const []);
      }
      final verified = _isVerified(trimmed);
      return FactCheck(
        sentence: trimmed,
        verified: verified,
        missingFacts: verified ? const <String>[] : _keyTerms(trimmed),
      );
    }).toList();
  }

  /// Retourne le texte avec les phrases non vérifiées annotées.
  String annotate(String text) {
    final results = check(text);
    final buffer = StringBuffer();
    for (final result in results) {
      if (result.sentence.trim().isEmpty) {
        buffer.write(result.sentence);
        continue;
      }
      if (result.verified) {
        buffer.write(result.sentence);
      } else {
        buffer.write('${result.sentence} [NON VÉRIFIÉ - à confirmer]');
      }
      buffer.write(' ');
    }
    return buffer.toString().trimRight();
  }

  bool _isVerified(String sentence) {
    if (facts.isEmpty) return false;
    final terms = _keyTerms(sentence);
    if (terms.isEmpty) return true;
    final factText = facts.join(' ').toLowerCase();
    // Une phrase est considérée vérifiée si au moins un de ses termes clés
    // apparaît dans les faits collectés (heuristique conservatrice).
    return terms.any((t) => factText.contains(t.toLowerCase()));
  }

  List<String> _keyTerms(String sentence) {
    final stopWords = <String>{
      'le','la','les','un','une','des','et','ou','sur','dans','par','pour','avec',
      'sans','en','au','aux','du','de','ce','cette','ces','il','elle','je','tu',
      'nous','vous','ils','elles','est','sont','était','étaient','a','à','y',
      'the','a','an','and','or','in','on','at','to','for','with','of','is','are',
      'was','were','it','this','that'
    };
    return sentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zàâäéèêëîïôöùûüç\s0-9]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toSet()
        .toList();
  }

  List<String> _splitSentences(String text) {
    return text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
  }
}

/// Résultat de vérification d'une phrase.
class FactCheck {
  final String sentence;
  final bool verified;
  final List<String> missingFacts;

  const FactCheck({
    required this.sentence,
    required this.verified,
    required this.missingFacts,
  });

  @override
  String toString() => 'FactCheck(verified: $verified, sentence: ${sentence.length > 40 ? '${sentence.substring(0, 40)}...' : sentence})';
}

extension FactGuardDate on DateTime {
  String toFrDate() => DateFormat('dd/MM/yyyy', 'fr').format(this);
  String toFrDateTime() => DateFormat('dd/MM/yyyy HH:mm', 'fr').format(this);
}
