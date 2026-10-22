import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/flashcard.dart';
import '../providers/app_providers.dart';
import '../theme.dart';
import '../widgets/help_dialog.dart';

/// Préparation à la soutenance : fiches de révision, QCM oral et suivi de progression.
class JuryScreen extends ConsumerStatefulWidget {
  const JuryScreen({super.key});

  @override
  ConsumerState<JuryScreen> createState() => _JuryScreenState();
}

class _JuryScreenState extends ConsumerState<JuryScreen> {
  bool _onlyDue = true;
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  String _category = 'général';
  Flashcard? _revealed;
  String? _reviewResult; // 'facile' | 'moyen' | 'difficile'

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_questionCtrl.text.trim().isEmpty || _answerCtrl.text.trim().isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.read(flashcardsProvider.notifier).add(Flashcard(
      question: _questionCtrl.text,
      answer: _answerCtrl.text,
      category: _category,
      dueDate: now,
      createdAt: DateTime.now(),
    ));
    _questionCtrl.clear();
    _answerCtrl.clear();
    setState(() {});
  }

  Future<void> _review(Flashcard card, String result) async {
    final now = DateTime.now();
    int interval;
    double ease = card.ease;
    if (result == 'facile') {
      interval = card.interval == 0 ? 1 : (card.interval * ease).round();
      ease = (ease + 0.1).clamp(1.3, 3.0);
    } else if (result == 'moyen') {
      interval = card.interval == 0 ? 1 : (card.interval * 1.5).round();
    } else {
      interval = 1;
      ease = (ease - 0.2).clamp(1.3, 3.0);
    }
    await ref.read(flashcardsProvider.notifier).update(card.copyWith(
          ease: ease,
          interval: interval,
          repetitions: card.repetitions + 1,
          dueDate: now.add(Duration(days: interval)).millisecondsSinceEpoch,
        ));
    if (mounted) setState(() => _reviewResult = result);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _reviewResult = null);
  }

  double _progress(List<Flashcard> cards) {
    if (cards.isEmpty) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final done = cards.where((c) => c.dueDate > now).length;
    return done / cards.length;
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(flashcardsProvider);
    final due = cards.where((c) => c.isDue).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soutenance — Jury'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progression
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progression de révision',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _progress(cards)),
                  const SizedBox(height: 4),
                  Text(
                      '${due.length} fiche(s) à réviser aujourd’hui sur ${cards.length}',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Ajout de fiche
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ajouter une fiche de révision',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _questionCtrl,
                    decoration: const InputDecoration(labelText: 'Question'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _answerCtrl,
                    decoration: const InputDecoration(labelText: 'Réponse'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: const [
                      DropdownMenuItem(value: 'général', child: Text('Général')),
                      DropdownMenuItem(value: 'technique', child: Text('Technique')),
                      DropdownMenuItem(value: 'reglementaire', child: Text('Réglementaire')),
                      DropdownMenuItem(value: 'communication', child: Text('Communication')),
                    ],
                    onChanged: (v) => _category = v ?? 'général',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _add, child: const Text('Ajouter la fiche')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Révision
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fiches à réviser', style: theme.textTheme.titleMedium),
              Switch(
                value: _onlyDue,
                onChanged: (v) => setState(() => _onlyDue = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (due.isEmpty)
            const Text('Aucune fiche à réviser pour le moment. Bravo !')
          else
            ...due.map((c) {
              final revealed = _revealed?.id == c.id;
              return Card(
                child: ListTile(
                  title: Text(c.question),
                  subtitle: Text('${c.category} · révision n°${c.repetitions + 1}'),
                  trailing: revealed || _reviewResult != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_reviewResult == null)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _review(c, 'difficile'),
                              ),
                            if (_reviewResult == null)
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _review(c, 'facile'),
                              ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.remove_red_eye),
                          onPressed: () => setState(() => _revealed = c),
                        ),
                  onTap: () => setState(() => _revealed = c),
                ),
              );
            }),
          const SizedBox(height: 24),
          Text('Toutes les fiches', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...cards.where((c) => !c.isDue).map((c) => ListTile(
                title: Text(c.question, style: const TextStyle(fontSize: 13)),
                trailing: Text(_frDate(DateTime.fromMillisecondsSinceEpoch(c.dueDate))),
              )),
        ],
      ),
    );
  }

  static String _frDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
