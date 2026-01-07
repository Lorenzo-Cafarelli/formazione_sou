#!/bin/bash
# Usa bash invece di sh per gestire meglio i segnali se possibile, altrimenti sh va bene con le modifiche sotto.

ROLE=$1

# --- CONFIGURAZIONE PORTE ---
PORT_LUPO=8001
PORT_CAPRA=8002
PORT_CAVOLO=8003
PORT_CONTADINO=8004

case $ROLE in
  "lupo")      MY_PORT=$PORT_LUPO ;;
  "capra")     MY_PORT=$PORT_CAPRA ;;
  "cavolo")    MY_PORT=$PORT_CAVOLO ;;
  "contadino") MY_PORT=$PORT_CONTADINO ;;
  *) echo "Ruolo non valido"; exit 1 ;;
esac

echo "[$ROLE] Avviato. Provo porta $MY_PORT..."

# --- GESTIONE CHIUSURA (FIX CRITICO) ---
# 'kill 0' invia il segnale a tutti i processi nel gruppo corrente (script + figli background)
cleanup() {
  trap - EXIT # Evita loop ricorsivi
  kill 0 2>/dev/null
  exit
}
trap cleanup EXIT SIGTERM SIGINT

# 1. Listener in background (Resiliente)
# Se nc fallisce (porta occupata), aspetta 1 sec invece di loopare all'infinito
(while true; do 
    nc -l -p $MY_PORT -k 2>/dev/null || sleep 1
done) &

# 2. Loop di controllo
while true; do
  sleep 2

  # Se c'è il contadino, tutto ok
  if nc -z 127.0.0.1 $PORT_CONTADINO 2>/dev/null; then
    continue
  fi

  # LOGICA PREDA/PREDATORE
  if [ "$ROLE" = "lupo" ]; then
    if nc -z 127.0.0.1 $PORT_CAPRA 2>/dev/null; then
       MSG="GAME OVER: Il Lupo ha mangiato la Capra!"
       echo $MSG | nc -u -w 1 arbitro 9999 # -w 1 timeout per non bloccarsi
       exit 1
    fi
  elif [ "$ROLE" = "capra" ]; then
    if nc -z 127.0.0.1 $PORT_CAVOLO 2>/dev/null; then
       MSG="GAME OVER: La Capra ha mangiato il Cavolo!"
       echo $MSG | nc -u -w 1 arbitro 9999
       exit 1
    fi
  fi
done