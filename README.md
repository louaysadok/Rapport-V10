# Rapport+

Application Android de journal de stage, rapport de stage et préparation à la
soutenance (jury). **100 % hors-ligne, Android uniquement, gratuite, sans
compte obligatoire.**

Construite avec Flutter 3.24.5 (Dart 3.5.4), Drift 2.14.1 (SQLite local),
flutter_riverpod, go_roller et llama.cpp (Qwen2.5-3B-Instruct GGUF Q4_K_M).

## Fonctionnalités

1. **Profil / onboarding** : vierge par défaut, aucune donnée pré-remplie.
2. **Journal de bord quotidien** : questionnaire adaptatif par domaine
   professionnel, photo/vidéo/audio, gestion des médias.
3. **Notification 18:00** heure locale (flutter_local_notifications + fuseau horaire).
4. **Saisie vocale hors-ligne** : enregistrement + transcription (whisper.cpp / sherpa-onnx compatible).
5. **Rapports progressifs** : chapitres personnalisables, génération IA fact-checkée
   (FactGuard : jamais d'invention "observé → réalisé"), export PDF / DOCX / XML,
   impression, archivage.
6. **Préparation jury** : questions/réponses, flashcards, suivi de progression.
7. **Aide** : popup avec le texte de contact admin exact.
8. **Design Material 3** : navy #0A1931 / bleu / turquoise, thèmes clair #FAFAF9
   et sombre #0A0A0A, pas de violet. Barre de navigation :
   Accueil / Journal / Rapport / Soutenance / Profil.
9. **IA dans Réglages** : Modèles locaux, Correction auto, etc.
10. **Google Drive optionnel** : sauvegarde jamais forcée, bouton "Passer".

## Premier lancement

L'application s'ouvre sur **Réglages** avec un message d'accueil, la connexion
ou le saut de Google Drive, puis le tableau de bord.

## Contact admin

If u got stuck please contact the admin using WhatsApp : +216 28671953
Admin Name and surname : Louay Sadok
# PLEASE contact in serious situations only # and thank you

## Build

Le workflow GitHub Actions `.github/workflows/build-apk.yml` génère les APK
debug et release (JDK 17 Temurin, Flutter 3.24.5, upload d'artifacts 30 jours).

## Licences des modèles

Voir `docs/MODEL_LICENSES.md` (Qwen License, Qwen2.5-3B-Instruct Q4_K_M).
