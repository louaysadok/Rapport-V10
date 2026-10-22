# Plan de test — Rapport+

## 1. Scope
Application Android uniquement (Flutter 3.24.5 / Dart 3.5.4), offline-first.
Stockage local SQLite (Drift). Aucune création de compte obligatoire.
Sauvegarde Google Drive optionnelle (jamais forcée).

## 2. Environnement de test
- Android physique ou émulateur, API 21 min, API 34 cible.
- JDK 17, Android SDK (build-tools 34.0.0, platform android-34).
- Pas de connexion réseau requise pour les fonctionnalités cœur (sauf Drive en option).

## 3. Cas de test fonctionnels

| ID | Cas | Résultat attendu |
|----|-----|------------------|
| T1 | Premier lancement | S'ouvre sur Réglages avec message d'accueil ; boutons "Configurer Drive" / "Passer sans Drive" ; après choix → tableau de bord ; `first_launch` passé à false. |
| T2 | Création de profil | Écran Profil, champs vierges par défaut ; saisie + enregistrement ; lecture en retour. |
| T3 | Ajout de stage | Dashboard → stage ajouté apparaît dans la liste, tous domaines acceptés. |
| T4 | Entrée de journal (jour) | Formulaire : date, titre, contenu, humeur, heures, questionnaire adaptatif selon domaine ; enregistrement ; ré-ouverture affiche les données. |
| T5 | Médias | Photo depuis galerie/appareil, enregistrement audio, attachement à l'entrée, lecture audio, suppression. |
| T6 | Questionnaire adaptatif | Selon le domaine (informatique, santé, BTP, commerce, éducation, autre), les questions diffèrent. |
| T7 | Rappel 18:00 | Notification locale programmée à 18:00 heure locale (fuseau détecté), fonctionne hors-ligne. |
| T8 | Génération rapport | Sélection période + chapitres ; génération IA basée uniquement sur les faits du journal ; phrases non étayées annotées "[NON VÉRIFIÉ]" (FactGuard). |
| T9 | Export PDF | Fichier PDF lisible, titre, infos stage, chapitres, mentions hors-ligne. |
| T10 | Export DOCX | Fichier .docx ouvrable dans Word/LibreOffice. |
| T11 | Export XML | Fichier XML bien formé avec chapitres en CDATA. |
| T12 | Archivage rapport | Le rapport apparaît dans la liste des rapports générés avec chemin de fichier. |
| T13 | Soutenance / fiches | Ajout de fiche Q/A, révision (révélé / facile / moyen / difficile), prochaine révision déplacée, progression affichée. |
| T14 | Mode sombre/clair | Changement de thème appliqué à l'application (navy #0A1931, bleu, turquoise ; pas de violet). |
| T15 | Barre de navigation | 5 onglets : Accueil / Journal / Rapport / Soutenance / Profil. |
| T16 | Aide | Popup depuis n'importe quel écran avec le texte exact imposé. |
| T17 | Google Drive optionnel | Saisie ID client OAuth ; connexion possible ; "Ignorer" n'empêche rien ; aucune fonctionnalité bloquée sans Drive. |
| T18 | Modèles locaux | Liste des .gguf, taille affichée, fallback vers modèle plus petit si le 3B absent ; llama-cli configurable. |
| T19 | FactGuard | Rapport généré ne contient que des faits issus du journal (pas d'invention "observé → réalisé"). |
| T20 | Multilingue saisie | Saisie en arabe, derja tunisien, français, anglais ; sortie du rapport en français professionnel. |

## 4. Tests non fonctionnels
- Hors-ligne : activer le mode avion, toutes les fonctions cœur (T2-T16) restent opérationnelles.
- Performance : ouverture de l'application < 3 s sur entrée de gamme.
- Stockage : base SQLite dans les documents de l'application ; sauvegarde manuelle possible (export du fichier .sqlite).
- Analyse statique : `flutter analyze` → 0 erreur.

## 5. Livrables de test
- APK debug + release (GitHub Actions artifact, rétention 30 jours).
- Rapport d'exécution du workflow `build-apk.yml`.
