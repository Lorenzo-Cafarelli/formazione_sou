#!/bin/bash

# Usciamo se c'è un errore (ma gestiremo la pulizia in modo che non dia errore)
set -e 

echo "🧹 Pulizia preventiva..."
# 1. PRIMA cancelliamo i container (altrimenti le reti non si cancellano)
docker rm -f lupo capra cavolo contadino lupo_debug 2>/dev/null || true

# 2. POI cancelliamo le reti (ora che sono vuote si possono cancellare)
docker network rm riva_sx riva_dx 2>/dev/null || true

echo "🏗️  Costruzione immagine Docker..."
cd ../app && docker build -t gioco-cc-img . > /dev/null
cd ../scripts

echo "🌊 Creazione delle Rive (Reti)..."
docker network create riva_sx > /dev/null
docker network create riva_dx > /dev/null

echo "🎭 Posizionamento personaggi sulla RIVA SINISTRA..."

# ORDINE DI AVVIO IMPORTANTE (Per evitare Game Over istantaneo)

# 1. IL CONTADINO (Il garante della sicurezza parte per primo)
docker run -d --rm --name contadino --network riva_sx \
  -e NAME=Contadino -e PREY=nulla -e GUARDIAN=nulla \
  gioco-cc-img > /dev/null

# 2. IL CAVOLO (Innocuo)
docker run -d --rm --name cavolo --network riva_sx \
  -e NAME=Cavolo -e PREY=nulla -e GUARDIAN=contadino \
  gioco-cc-img > /dev/null

# 3. LA CAPRA (Vede il Contadino -> Sta buona)
docker run -d --rm --name capra --network riva_sx \
  -e NAME=Capra -e PREY=cavolo -e GUARDIAN=contadino \
  gioco-cc-img > /dev/null

# 4. IL LUPO (Vede il Contadino -> Sta buono)
docker run -d --rm --name lupo --network riva_sx \
  -e NAME=Lupo -e PREY=capra -e GUARDIAN=contadino \
  gioco-cc-img > /dev/null

echo "✅ Gioco pronto! Esegui './play.sh' per iniziare."