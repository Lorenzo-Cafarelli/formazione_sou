#!/bin/sh

# Configurazione
echo "--- SONO IL $NAME ---"
echo "Preda: $PREY | Guardiano: $GUARDIAN"

while true; do
    # Verifica presenza Preda (Ping con timeout 1s)
    if ping -c 1 -W 1 "$PREY" > /dev/null 2>&1; then
        PREY_HERE=true
    else
        PREY_HERE=false
    fi

    # Verifica presenza Guardiano
    if ping -c 1 -W 1 "$GUARDIAN" > /dev/null 2>&1; then
        GUARDIAN_HERE=true
    else
        GUARDIAN_HERE=false
    fi

    # LOGICA DI SOPRAVVIVENZA
    if [ "$PREY_HERE" = "true" ]; then
        if [ "$GUARDIAN_HERE" = "false" ]; then
            echo "❌ GAME OVER: Il $NAME ha mangiato la $PREY!"
            # Usciamo con errore (il container muore)
            exit 1 
        else
            echo "👀 $NAME vede la $PREY, ma c'è il $GUARDIAN. Tutto ok."
        fi
    else
        echo "💤 $NAME tranquillo..."
    fi

    # Attesa prima del prossimo controllo
    sleep 2
done