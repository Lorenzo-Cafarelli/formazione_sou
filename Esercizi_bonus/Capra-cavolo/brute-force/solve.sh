#!/bin/bash

# --- TRAPPOLA PER CTRL+C ---
cleanup() {
    echo ""
    echo "🛑 Interruzione rilevata! Spengo tutto..."
    # Chiama lo script di stop nella cartella vicina
    pushd ../scripts > /dev/null
    ./stop_game.sh
    popd > /dev/null
    exit
}
# Quando arriva il segnale SIGINT (CTRL+C), esegui la funzione cleanup
trap cleanup SIGINT
# ---------------------------

# ==========================================
# 🤖 SOLUTORE AUTOMATICO (BRUTE FORCE)
# ==========================================

# Funzione per trovare la posizione (SX o DX)
get_location() {
    local container=$1
    # Se il container è nella rete riva_sx, è a sinistra. Altrimenti è a destra.
    if docker network inspect riva_sx | grep -q "\"Name\": \"$container\""; then
        echo "SX"
    else
        echo "DX"
    fi
}

# Funzione per spostare i container
move_container() {
    local name=$1
    local from=$2
    local to=$3
    docker network disconnect "$from" "$name" > /dev/null 2>&1
    docker network connect "$to" "$name" > /dev/null 2>&1
}

# --- LOOP DEI TENTATIVI (Partite intere) ---
ATTEMPT=1
while true; do
    echo "=================================================="
    echo "🔄 TENTATIVO #$ATTEMPT: Reset del tavolo da gioco..."
    
    # 1. Resetta il gioco chiamando lo script nella cartella vicina
    # Usiamo pushd/popd per entrare, eseguire e tornare indietro senza romperci
    pushd ../scripts > /dev/null
    ./start_game.sh > /dev/null 2>&1
    popd > /dev/null
    
    # Aspettiamo che i container siano stabili
    sleep 2
    
    MOVES=0
    GAME_ACTIVE=true

    # --- LOOP DELLA SINGOLA PARTITA ---
    while $GAME_ACTIVE; do
        
        # A. CONTROLLO VITI/MORTI
        # Se manca un container, significa che logic.sh ha fatto exit 1 -> SCONFITTA
        if ! docker ps | grep -q "lupo" || \
           ! docker ps | grep -q "capra" || \
           ! docker ps | grep -q "cavolo"; then
            echo "💀 Mossa $MOVES: GAMEOVER! Qualcuno è stato mangiato."
            GAME_ACTIVE=false
            break # Esce dal loop della partita, prova un nuovo tentativo
        fi

        # B. CONTROLLO VITTORIA
        l_loc=$(get_location lupo)
        c_loc=$(get_location capra)
        v_loc=$(get_location cavolo)
        f_loc=$(get_location contadino)

        if [ "$l_loc" == "DX" ] && [ "$c_loc" == "DX" ] && [ "$v_loc" == "DX" ] && [ "$f_loc" == "DX" ]; then
            echo ""
            echo "🎉🎉🎉 VITTORIA TROVATA AL TENTATIVO #$ATTEMPT! 🎉🎉🎉"
            echo "Il computer ha risolto il puzzle in $MOVES mosse."
            echo "I container sono salvi sulla riva destra."
            exit 0
        fi

        # C. CALCOLO MOSSE POSSIBILI
        CURRENT_NET=""
        DEST_NET=""
        OPTIONS=() # Array per contenere i passeggeri possibili
        
        # Aggiungiamo sempre l'opzione "nessuno" (il contadino viaggia solo)
        OPTIONS+=("nessuno")

        if [ "$f_loc" == "SX" ]; then
            CURRENT_NET="riva_sx"
            DEST_NET="riva_dx"
            # Chi è con me a sinistra?
            [ "$l_loc" == "SX" ] && OPTIONS+=("lupo")
            [ "$c_loc" == "SX" ] && OPTIONS+=("capra")
            [ "$v_loc" == "SX" ] && OPTIONS+=("cavolo")
        else
            CURRENT_NET="riva_dx"
            DEST_NET="riva_sx"
            # Chi è con me a destra?
            [ "$l_loc" == "DX" ] && OPTIONS+=("lupo")
            [ "$c_loc" == "DX" ] && OPTIONS+=("capra")
            [ "$v_loc" == "DX" ] && OPTIONS+=("cavolo")
        fi

        # D. SCELTA CASUALE (Il cuore del Brute Force)
        # Prende un indice a caso dall'array OPTIONS
        RAND_IDX=$((RANDOM % ${#OPTIONS[@]}))
        PASSENGER=${OPTIONS[$RAND_IDX]}
        
        ((MOVES++))
        echo "➡️  Mossa $MOVES: Contadino sposta [$PASSENGER] da $f_loc a..."

        # E. ESECUZIONE MOSSA
        # 1. Sposta Contadino
        move_container "contadino" "$CURRENT_NET" "$DEST_NET"
        # 2. Sposta Passeggero (se diverso da nessuno)
        if [ "$PASSENGER" != "nessuno" ]; then
            move_container "$PASSENGER" "$CURRENT_NET" "$DEST_NET"
        fi

        # F. ATTESA CRITICA
        # Dobbiamo dare tempo ai container di pingarsi e (eventualmente) morire
        sleep 3
    done
    
    # Se siamo qui, il loop interno è finito (sconfitta). Incrementiamo tentativo.
    ((ATTEMPT++))
    
    # Sicurezza: Fermiamo se ci mette troppo
    if [ $ATTEMPT -gt 50 ]; then
        echo "❌ Troppi tentativi. Il computer si arrende."
        exit 1
    fi
done