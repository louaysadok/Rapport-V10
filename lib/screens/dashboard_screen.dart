import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/internship.dart';
import '../models/journal_entry.dart';
import '../models/report.dart';
import '../providers/app_providers.dart';
import '../screens/journal_screen.dart';
import '../screens/report_screen.dart';
import '../screens/jury_screen.dart';
import '../theme.dart';
import '../widgets/help_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internships = ref.watch(internshipsProvider);
    final entries = ref.watch(entriesProvider);
    final settings = ref.watch(settingsProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayEntries = entries.where((e) => e.date == today).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ref.read(notificationServiceProvider).scheduleDailyReminder(
                    hour: settings.notificationHour,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Rappel quotidien programmé à 18:00')),
              );
            },
            tooltip: 'Rappel 18:00',
          ),
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
          Text(
            DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(DateTime.now()),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          _Card(
            title: 'Aujourd’hui',
            subtitle: todayEntries.isEmpty
                ? 'Aucune entrée de journal pour aujourd’hui.'
                : '${todayEntries.length} entrée(s) consignée(s).',
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Rédiger'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const JournalScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Stages', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (internships.isEmpty)
            const Text('Aucun stage enregistré. Ajoutez-en un dans Profil.')
          else
            ...internships.map((i) => ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: Text(i.name),
                  subtitle: Text(i.field),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(entriesProvider.notifier).load(internshipId: i.id);
                  },
                )),
          const SizedBox(height: 24),
          Text('Dernières entrées', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('Aucune entrée pour le moment.')
          else
            ...entries.take(5).map((e) => ListTile(
                  leading: const Icon(Icons.note),
                  title: Text(e.title.isNotEmpty ? e.title : e.date),
                  subtitle: Text('${e.date} · ${e.hours.toStringAsFixed(1)} h'),
                  trailing: Text('${e.mood}/5'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JournalScreen(entryId: e.id),
                      ),
                    );
                  },
                )),
          const SizedBox(height: 32),
          _Card(
            title: 'Rapports & Soutenance',
            subtitle: 'Générez votre rapport de stage et préparez le jury.',
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.description),
                    label: const Text('Nouveau rapport'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReportScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.assignment),
                    label: const Text('Soutenance'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const JuryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const JournalScreen()),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Card({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
