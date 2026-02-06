Résumé de `event_card.dart`

But: Carte d'affichage d'un événement avec effet de hover (élevation animée).

Points clés

- Animation
  - `AnimationController` + Tween pour animer l'`elevation` du `Card`.
  - `MouseRegion` déclenche `forward()`/`reverse()` pour pilote le hover.

- Accessibilité/UX
  - `InkWell` pour gérer le `onTap` et l'effet visuel lors du clic.

- Mise à jour du thème
  - `didUpdateWidget` appelle `setState` si `isDark` change, forçant
    la mise à jour des couleurs calculées.

Conseils

- Sur mobile, l'effet hover n'est pas utile mais n'augmente pas le coût.
- Tester la performance si la liste contient de nombreuses cartes animées.
