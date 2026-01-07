#!/bin/sh

ROLE=$1
ME_PID=$$

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

echo "[$ROLE] Avviato. Apro la porta $MY_PORT..."

# 1. Listener in background
while true; do nc -l -p $MY_PORT 2>/dev/null; done &
LISTENER_PID=$!

cleanup() {
  kill $LISTENER_PID 2>/dev/null
}
# MODIFICA QUI: Aggiunto EXIT per pulire anche quando si suicida
trap cleanup EXIT SIGTERM SIGINT

# 2. Loop di controllo
while true; do
  sleep 2

  if nc -z 127.0.0.1 $PORT_CONTADINO 2>/dev/null; then
    continue
  fi

  if [ "$ROLE" = "lupo" ]; then
    if nc -z 127.0.0.1 $PORT_CAPRA 2>/dev/null; then
       MSG="GAME OVER: Il Lupo ha mangiato la Capra!"
       echo $MSG | nc -u arbitro 9999
       exit 1
    fi
  elif [ "$ROLE" = "capra" ]; then
    if nc -z 127.0.0.1 $PORT_CAVOLO 2>/dev/null; then
       MSG="GAME OVER: La Capra ha mangiato il Cavolo!"
       echo $MSG | nc -u arbitro 9999
       exit 1
    fi
  fi
done
