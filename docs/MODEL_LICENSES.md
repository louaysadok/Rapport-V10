# Licences des modèles d'IA locaux

Rapport+ utilise des modèles de langage locaux au format GGUF exécutés via
llama.cpp. Aucun modèle n'est téléchargé ni imposé par l'application ;
l'utilisateur choisit d'en placer un dans le répertoire des modèles de l'app.

## Qwen2.5-3B-Instruct (modèle de référence, Q4_K_M)

- Modèle : Qwen2.5-3B-Instruct
- Quantification : Q4_K_M (4 bits)
- Taille : environ 1,9 Go
- Licence : **Qwen License** (travaux dérivés de Qwen par Alibaba Cloud)

### Qwen License (résumé)

Le modèle Qwen2.5 est distribué sous la "Qwen License" d'Alibaba Cloud.
Principales dispositions :

1. **Utilisation gratuite** : l'utilisation, la copie, la modification, la
   fusion, la publication, la distribution et la sous-licence sont autorisées,
   y compris à des fins commerciales, sous réserve des conditions ci-dessous.
2. **Restriction pour les très grands utilisateurs** : si l'entité utilisateur
   compte plus de 100 millions d'utilisateurs mensuels actifs, une licence
   commerciale doit être demandée à Alibaba Cloud avant utilisation.
3. **Interdictions** : il est interdit d'utiliser le modèle pour
   - générer des contenus illégaux, dangereux, trompeurs ou non conformes à
     la réglementation en vigueur,
   - se faire passer pour une personne physique sans son consentement,
   - entraîner d'autres modèles de langage à grande échelle (distillation
     interdite sans autorisation).
4. **Aucune garantie** : le modèle est fourni "en l'état", sans garantie.
5. **Marques** : la licence n'octroie aucun droit sur les marques "Qwen".

Texte complet : https://github.com/QwenLM/Qwen2.5/blob/main/LICENSE

## Modèle de secours (fallback)

- Qwen2.5-0.5B-Instruct Q4_K_M (même licence Qwen License).

## Remarque importante

L'application Rapport+ n'inclut aucun modèle ni binaire llama.cpp ni
whisper.cpp. Ces composants doivent être ajoutés par l'utilisateur (ou par
l'administrateur de l'établissement de stage) dans le répertoire des modèles
de l'application. En l'absence de binaire local, Rapport+ fonctionne en mode
"secours" : génération de rapports et réponses basées exclusivement sur les
faits consignés dans le journal de bord (FactGuard), sans aucune invention.

## Contact admin

If u got stuck please contact the admin using WhatsApp : +216 28671953
Admin Name and surname : Louay Sadok
# PLEASE contact in serious situations only # and thank you
