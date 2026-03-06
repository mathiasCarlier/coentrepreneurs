#!/bin/bash
set -e

echo "Build Flutter web..."
flutter build web --release

echo "Déploiement sur le VPS..."
rsync -avz --delete build/web/ math@46.225.133.77:~/app/web/

echo "Déploiement terminé."
