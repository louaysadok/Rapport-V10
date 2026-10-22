import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/app_database.dart';
import '../app_state.dart';
import '../providers/app_providers.dart';
import '../services/ai_service.dart';
import '../theme.dart';
import '../widgets/help_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  /// Mode première ouverture (accueil + Google Drive connect/skip).
  const SettingsScreen.welcome({super.key}) : _welcome = true;
  const SettingsScreen({super.key}) : _welcome = false;

  final bool _welcome;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _driveClientId = '';
  final _clientIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clientIdCtrl.text = ref.read(settingsProvider).driveClientId ?? '';
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(settingsProvider.notifier).setDriveClientId(
          _clientIdCtrl.text.trim().isEmpty ? null : _clientIdCtrl.text.trim(),
        );
    await ref.read(prefsProvider).setBool('first_launch', false);
    await appDatabase.setSetting('first_launch_done', 'true');
    if (mounted) {
      // La première ouverture est terminée : direction le tableau de bord.
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget._welcome) {
      return _welcomePage();
    }
    return _settingsPage();
  }

  Widget _welcomePage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue dans Rapport+')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.school, size: 80, color: kNavy),
          const SizedBox(height: 24),
          Text(
            'Rapport+',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Journal de stage, rapport et préparation à la soutenance — 100 % hors-ligne, Android uniquement, gratuit.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),
          const Text(
            'Premier lancement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune donnée n’est pré-remplie. Votre profil et votre journal restent stockés localement sur votre appareil. '
            'La sauvegarde Google Drive est optionnelle : vous pouvez l’activer ou l’ignorer ci-dessous.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _clientIdCtrl,
            decoration: const InputDecoration(
              labelText: 'ID client Google Drive (optionnel, ignorer pour passer)',
              hintText: 'Laissez vide pour ne pas utiliser Drive',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_done),
                  label: const Text('Configurer Drive'),
                  onPressed: _finishOnboarding,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Passer sans Drive'),
                  onPressed: _finishOnboarding,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Besoin d’aide ? "If u got stuck please contact the admin using WhatsApp : +216 28671953 Admin Name and surname : Louay Sadok # PLEASE contact in serious situations only # and thank you"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _settingsPage() {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thème
          ListTile(
            title: const Text('Thème'),
            subtitle: Text(settings.themeMode == ThemeMode.dark
                ? 'Sombre'
                : settings.themeMode == ThemeMode.light ? 'Clair' : 'Système'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Système')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
              ],
              onChanged: (v) => v != null
                  ? ref.read(settingsProvider.notifier).setThemeMode(v)
                  : null,
            ),
          ),
          const Divider(),
          // Notifications
          ListTile(
            title: const Text('Rappel journal 18:00'),
            subtitle: const Text('Notification quotidienne à 18:00 heure locale'),
            trailing: Switch(
              value: settings.notificationsOn,
              onChanged: (v) => ref.read(settingsProvider.notifier).setNotifications(v),
            ),
          ),
          ListTile(
            title: const Text('Heure du rappel'),
            subtitle: Text('${settings.notificationHour}:00'),
            trailing: DropdownButton<int>(
              value: settings.notificationHour,
              items: List.generate(24, (h) => DropdownMenuItem(value: h, child: Text('$h:00'))),
              onChanged: (v) => v != null
                  ? ref.read(settingsProvider.notifier).setNotificationHour(v)
                  : null,
            ),
          ),
          const Divider(),
          // IA locale
          const Text('Intelligence artificielle locale', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Correction auto (FactGuard)'),
            subtitle: const Text('Vérifie que le rapport ne contient que des faits du journal'),
            trailing: Switch(
              value: settings.aiAutoCorrection,
              onChanged: (v) => ref.read(settingsProvider.notifier).setAutoCorrection(v),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Modèles locaux'),
            subtitle: Text('Qwen2.5-3B-Instruct Q4_K_M (~1,9 Go) — llama.cpp'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _modelManagerDialog(context),
          ),
          const Divider(),
          // Drive
          ListTile(
            title: const Text('Sauvegarde Google Drive'),
            subtitle: Text(settings.driveConnected ? 'Connecté' : 'Non configuré (optionnel)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _driveDialog(context),
          ),
          const Divider(),
          ListTile(
            title: const Text('Aide / Support'),
            subtitle: const Text('Popup d’assistance accessible depuis partout'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const HelpDialog(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Version 1.0.0 — Rapport+ — Louay Sadok — +216 28671953',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _modelManagerDialog(BuildContext context) async {
    await ref.read(aiServiceProvider); // ensure instance
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modèles locaux (llama.cpp)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modèle par défaut : Qwen2.5-3B-Instruct Q4_K_M'),
              const Text('Taille estimée : ~1,9 Go', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text('Le téléchargement du modèle n’est jamais forcé.'),
              const Text('Placez le fichier .gguf et le binaire llama-cli dans le répertoire des modèles de l’app.'),
              const SizedBox(height: 12),
              const Text('Fallback : si le modèle 3B est absent ou trop volumineux, un modèle plus petit (ex. Qwen2.5-0.5B) est utilisé.'),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Chemin du binaire llama-cli'),
                onChanged: (v) {
                  ref.read(aiServiceProvider).llamaCliPath = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _driveDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Google Drive (optionnel)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('La sauvegarde vers Google Drive n’est jamais forcée. Vous pouvez ignorer cette étape.'),
            const SizedBox(height: 12),
            TextField(
              controller: _clientIdCtrl,
              decoration: const InputDecoration(labelText: 'ID client OAuth Google (optionnel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setDriveClientId(null);
              Navigator.pop(context);
            },
            child: const Text('Ignorer'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setDriveClientId(
                    _clientIdCtrl.text.trim().isEmpty ? null : _clientIdCtrl.text.trim(),
                  );
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
