#!/bin/bash
set -euo pipefail

#Configurazione del container e dell'immagine Docker
CONTAINER="echo-pingpong"
IMAGE="ealen/echo-server"
DELAY=60         # secondi per ogni turno
NODE1="node1"    # nome Vagrant
NODE2="node2"

# Funzione: esegue un comando sulla VM usando vagrant ssh
run_on() {
  local node=$1
  local cmd=$2
  echo "[$(date +'%F %T')] $node -> $cmd"
  vagrant ssh "$node" -c "$cmd"
}

# Avvia il container sul primo nodo ed attende 60 secondi
while true; do
  echo "=== Avvio su $NODE1 ==="
  run_on "$NODE1" "docker run -d --name ${CONTAINER} -p 8080:80 ${IMAGE} >/dev/null 2>&1 || true"
  echo "Attendo ${DELAY}s..."
  sleep "${DELAY}"

# Ferna il container sul primo nodo
  echo "=== Stop su $NODE1 ==="
  run_on "$NODE1" "docker rm -f ${CONTAINER} >/dev/null 2>&1 || true"

# Avvia il container sul secondo nodo ed attende 60 secondi
  echo "=== Avvio su $NODE2 ==="
  run_on "$NODE2" "docker run -d --name ${CONTAINER} -p 8080:80 ${IMAGE} >/dev/null 2>&1 || true"
  echo "Attendo ${DELAY}s..."
  sleep "${DELAY}"

# Ferma il container sul secondo nodo e ricomincia il ciclo
  echo "=== Stop su $NODE2 ==="
  run_on "$NODE2" "docker rm -f ${CONTAINER} >/dev/null 2>&1 || true"
done

