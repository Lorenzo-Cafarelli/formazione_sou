#!/bin/bash

# --- CONFIGURAZIONE ---
POS_LUPO=0
POS_CAPRA=0
POS_CAVOLO=0
POS_CONTADINO=0

# Funzioni di supporto
spawn() {
    ROLE=$1
    SIDE=$2
    
    # Esegue lo script. Nota: Usiamo bash esplicitamente
    docker compose exec -d riva-$SIDE bash /game/actor.sh $ROLE > /dev/null 2>&1
    
    # ATTESA ATTIVA
    count=0
    # Aumentiamo un po' il timeout (30 iterazioni)
    while ! docker compose exec riva-$SIDE ps | grep -q "bash /game/actor.sh $ROLE"; do
        sleep 0.2 # Controllo più rapido
        count=$((count+1))
        if [ $count -gt 30 ]; then return 1; fi 
    done
    return 0
}

kill_actor() {
    ROLE=$1
    SIDE=$2
    # Pkill -f matcha la command line completa
    docker compose exec riva-$SIDE pkill -f "bash /game/actor.sh $ROLE" > /dev/null 2>&1
    
    count=0
    while docker compose exec riva-$SIDE ps | grep -q "bash /game/actor.sh $ROLE"; do
        sleep 0.2
        count=$((count+1))
        if [ $count -gt 30 ]; then break; fi
    done
}

check_life() {
    ROLE=$1
    POS=$2
    if [ $POS -eq 0 ]; then SIDE="sx"; else SIDE="dx"; fi
    
    if ! docker compose exec riva-$SIDE ps | grep -q "bash /game/actor.sh $ROLE"; then
        return 1 # MORTO
    fi
    return 0 # VIVO
}

draw_ui() {
    clear
    echo "=========================================="
    echo "   🛶 IL GIOCO DEL FIUME (Fixed Edition)   "
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
echo "🧹 Pulizia e installazione pacchetti..."
docker compose down --volumes > /dev/null 2>&1
# Qui assicuriamo che le immagini vengano buildate o avviate correttamente
docker compose up -d

# Attendiamo che Alpine installi i pacchetti (comando nel docker-compose)
echo "⏳ Attendo installazione netcat..."
sleep 5 

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

    # Validazione mossa
    if [ "$ACTOR" != "nessuno" ] && [ $ACTOR_POS -ne $POS_CONTADINO ]; then
        echo -e "\n🚫 Errore: Il contadino deve essere sulla stessa riva!"
        sleep 1
        continue
    fi

    if [ $POS_CONTADINO -eq 0 ]; then FROM="sx"; TO="dx"; NEW_POS=1; else FROM="dx"; TO="sx"; NEW_POS=0; fi

  echo -e "\n🛶 Sposto..."
    
    # 1. RIMUOVI (Kill sincrono)
    if [ "$ACTOR" != "nessuno" ]; then 
        kill_actor $ACTOR $FROM
        sleep 2
        # --------------------
    fi
    kill_actor contadino $FROM
    
    # Simulazione viaggio
    sleep 1
    
    # 2. CREA (Spawn sincrono)
    spawn contadino $TO
    if [ "$ACTOR" != "nessuno" ]; then
        if spawn $ACTOR $TO; then
             eval "$VAR_REF=$NEW_POS"
        else
             echo "❌ ERRORE TECNICO: Impossibile avviare $ACTOR su $TO"
             echo "Assicurati di aver aggiornato docker-compose e actor.sh"
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
        
        LOG_MSG=$(docker compose logs --tail 1 arbitro 2>&1)
        
        if [[ "$LOG_MSG" == *"GAME OVER"* ]]; then
             echo "Causa: $LOG_MSG"
        else
             echo "⚠️ Morte silenziosa (possibile mossa illegale mentre il contadino viaggiava)."
        fi
        
        echo "Premi un tasto per uscire..."
        read -n 1 -s
        exit 1
    fi

    # --- CONTROLLO VITTORIA ---
    # Se tutti sono sulla riva destra (valore 1)
    if [ $POS_LUPO -eq 1 ] && [ $POS_CAPRA -eq 1 ] && [ $POS_CAVOLO -eq 1 ] && [ $POS_CONTADINO -eq 1 ]; then
        draw_ui
        echo -e "\n\n🏆  COMPLIMENTI! HAI VINTO!  🏆"
        echo "Tutti sono stati traghettati sani e salvi!"
        
        # Pulizia finale automatica
        echo "Premi un tasto per festeggiare e uscire..."
        read -n 1 -s
        docker compose down --volumes > /dev/null 2>&1
        exit 0
    fi

done