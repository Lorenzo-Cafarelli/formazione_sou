#!/bin/bash

# --- CONFIGURAZIONE ---
POS_LUPO=0
POS_CAPRA=0
POS_CAVOLO=0
POS_CONTADINO=0

# Funzioni di supporto
spawn() {
    # Tenta di avviare il processo
    docker compose exec -d riva-$2 sh /game/actor.sh $1 > /dev/null 2>&1
    
    # ATTESA ATTIVA: Aspetta finché il processo non appare davvero nella lista ps
    # Timeout di 5 secondi per evitare loop infiniti
    count=0
    while ! docker compose exec riva-$2 ps | grep -q "sh /game/actor.sh $1"; do
        sleep 1
        count=$((count+1))
        if [ $count -gt 25 ]; then return 1; fi # Fallito avvio
    done
    return 0
}

kill_actor() {
    docker compose exec riva-$2 pkill -f "sh /game/actor.sh $1" > /dev/null 2>&1
    
    # ATTESA ATTIVA: Aspetta finché il processo non sparisce davvero
    count=0
    while docker compose exec riva-$2 ps | grep -q "sh /game/actor.sh $1"; do
        sleep 1
        count=$((count+1))
        if [ $count -gt 25 ]; then break; fi # Forziamo uscita
    done
}

check_life() {
    ROLE=$1
    POS=$2
    if [ $POS -eq 0 ]; then SIDE="sx"; else SIDE="dx"; fi
    
    # Verifica esistenza processo
    if ! docker compose exec riva-$SIDE ps | grep -q "sh /game/actor.sh $ROLE"; then
        return 1 # MORTO (o crashato)
    fi
    return 0 # VIVO
}

draw_ui() {
    clear
    echo "=========================================="
    echo "   🛶 IL GIOCO DEL FIUME (Sync Edition)    "
    echo "=========================================="
    echo ""
    echo -n "RIVA SX: "
    [ $POS_LUPO -eq 0 ] && echo -n "🐺 "
    [ $POS_CAPRA -eq 0 ] && echo -n "🐐 "
    [ $POS_CAVOLO -eq 0 ] && echo -n "🥬 "
    [ $POS_CONTADINO -eq 0 ] && echo -n "👨‍🌾 "
    echo ""
    echo "------------------------------------------"
    echo "                ~~~~~~ 🌊 ~~~~~~          "
    echo "------------------------------------------"
    echo -n "RIVA DX: "
    [ $POS_LUPO -eq 1 ] && echo -n "🐺 "
    [ $POS_CAPRA -eq 1 ] && echo -n "🐐 "
    [ $POS_CAVOLO -eq 1 ] && echo -n "🥬 "
    [ $POS_CONTADINO -eq 1 ] && echo -n "👨‍🌾 "
    echo -e "\n\n=========================================="
    echo "[l]=Lupo [c]=Capra [v]=Cavolo [n]=Solo Contadino [q]=Esci"
}

# --- RESET INIZIALE ---
echo "🧹 Pulizia profonda (Rimozione volumi e log)..."
# --volumes cancella anche i log persistenti!
docker compose down --volumes > /dev/null 2>&1
docker compose up -d > /dev/null 2>&1

echo "🔄 Avvio processi..."
spawn lupo sx
spawn capra sx
spawn cavolo sx
spawn contadino sx
sleep 1

while true; do
    draw_ui
    read -n 1 -s key

    case $key in
        l) ACTOR="lupo"; ACTOR_POS=$POS_LUPO; VAR_REF="POS_LUPO" ;;
        c) ACTOR="capra"; ACTOR_POS=$POS_CAPRA; VAR_REF="POS_CAPRA" ;;
        v) ACTOR="cavolo"; ACTOR_POS=$POS_CAVOLO; VAR_REF="POS_CAVOLO" ;;
        n) ACTOR="nessuno"; ACTOR_POS=$POS_CONTADINO ;;
        q) echo -e "\n👋 Bye!"; exit 0 ;;
        *) continue ;;
    esac

    if [ "$ACTOR" != "nessuno" ] && [ $ACTOR_POS -ne $POS_CONTADINO ]; then
        echo -e "\n🚫 Errore: Il contadino non è lì!"
        sleep 1
        continue
    fi

    if [ $POS_CONTADINO -eq 0 ]; then FROM="sx"; TO="dx"; NEW_POS=1; else FROM="dx"; TO="sx"; NEW_POS=0; fi

    echo -e "\n🛶 Sposto..."
    
    # 1. RIMUOVI (Kill sincrono)
    if [ "$ACTOR" != "nessuno" ]; then kill_actor $ACTOR $FROM; fi
    kill_actor contadino $FROM
    
    # Simulazione viaggio
    sleep 1
    
    # 2. CREA (Spawn sincrono)
    spawn contadino $TO
    if [ "$ACTOR" != "nessuno" ]; then
        if spawn $ACTOR $TO; then
             eval "$VAR_REF=$NEW_POS"
        else
             echo "❌ ERRORE TECNICO: Impossibile avviare $ACTOR su $TO (Porta occupata?)"
             echo "Il gioco termina per errore di sistema Docker."
             exit 1
        fi
    fi
    POS_CONTADINO=$NEW_POS
    
    echo "👀 Controllo sopravvissuti..."
    sleep 2

    GAME_OVER=0
    check_life "lupo" $POS_LUPO || GAME_OVER=1
    check_life "capra" $POS_CAPRA || GAME_OVER=1
    check_life "cavolo" $POS_CAVOLO || GAME_OVER=1

    if [ $GAME_OVER -eq 1 ]; then
        draw_ui
        echo -e "\n\n💀 GAME OVER! QUALCUNO È MORTO! 💀"
        
        # Recupera l'ultimo log
        LOG_MSG=$(docker compose logs --tail 1 arbitro 2>&1)
        
        # Se il log è vuoto o contiene solo info di avvio, non è stato un omicidio
        if [[ "$LOG_MSG" == *"GAME OVER"* ]]; then
             echo "Causa: $LOG_MSG"
        else
             echo "⚠️ ATTENZIONE: Nessun messaggio dall'arbitro."
             echo "È probabile che un processo sia crashato silenziosamente (Errore Tecnico)."
        fi
        
        echo "Premi un tasto per uscire..."
        read -n 1 -s
        exit 1
    fi
done