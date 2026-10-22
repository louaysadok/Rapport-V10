import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../theme.dart';
import '../widgets/help_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    if (profile != null) {
      _nameCtrl.text = profile.fullName;
      _emailCtrl.text = profile.email;
      _phoneCtrl.text = profile.phone;
      _schoolCtrl.text = profile.school;
      _degreeCtrl.text = profile.degree;
      _addressCtrl.text = profile.address;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _schoolCtrl.dispose();
    _degreeCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = UserProfile(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      school: _schoolCtrl.text,
      degree: _degreeCtrl.text,
      address: _addressCtrl.text,
      updatedAt: DateTime.now(),
    );
    setState(() => _saving = true);
    await ref.read(profileProvider.notifier).save(profile);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistré.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
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
          Text('Votre profil de stagiaire',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom et prénom'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Téléphone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _schoolCtrl,
            decoration: const InputDecoration(labelText: 'Établissement de formation'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _degreeCtrl,
            decoration: const InputDecoration(labelText: 'Diplôme visé'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Adresse'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enregistrer le profil'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée n’est pré-remplie. Vous êtes le seul propriétaire de ces informations (stockage local uniquement).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
