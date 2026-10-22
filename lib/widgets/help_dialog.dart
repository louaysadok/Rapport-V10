import 'package:flutter/material.dart';

/// Popup d’assistance accessible depuis partout dans l’application.
/// Texte exact imposé par le cahier des charges.
class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  static const String helpText =
      'If u got stuck please contact the admin using WhatsApp : +216 28671953 Admin Name and surname : Louay Sadok # PLEASE contact in serious situations only # and thank you';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aide / Support'),
      content: SingleChildScrollView(
        child: Text(HelpDialog.helpText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
