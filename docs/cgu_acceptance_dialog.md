Résumé de `cgu_acceptance_dialog.dart`

But: Widget modal qui affiche le contenu des CGU et force la lecture avant acceptation.

Points clés

- Scroll-based gating
  - Le `ScrollController` calcule le pourcentage de lecture.
  - `_hasReadCGU` devient vrai à 90% de scroll et active la checkbox.

- UX
  - Barre de progression visuelle en bas du bloc de texte.
  - Checkbox désactivée tant que le seuil de lecture n'est pas atteint.
  - `Accepter` appelle `widget.onAccepted()` après `Navigator.pop(true)`.

- Edge cases
  - Si le texte tient entièrement sans scroll (`maxScroll == 0`) la lecture
    est considérée complète.
  - Le dialog renvoie `true`/`false`; l'appelant doit gérer `then((accepted){...})`.

Conseils

- Réduire la sensibilité si le document est court (par ex 70% au lieu de 90%).
- Si vous voulez une sécurité juridique plus forte, considérer un mécanisme
  serveur qui enregistre l'adresse IP / user-agent au moment de l'acceptation.
