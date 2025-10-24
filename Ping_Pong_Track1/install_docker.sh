#!/bin/bash
set -euo pipefail

# Aggiorna pacchetti e installa Docker (versione base tramite docker.io disponibile su apt)
sudo apt-get update -y
sudo apt-get install -y docker.io

# Abilita e avvia il servizio Docker
sudo systemctl enable docker
sudo systemctl start docker

# Aggiunge l'utente vagrant al gruppo docker (per poter usare docker senza sudo)
sudo usermod -aG docker vagrant

# Info
echo "Docker installed. User 'vagrant' added to group 'docker'."

