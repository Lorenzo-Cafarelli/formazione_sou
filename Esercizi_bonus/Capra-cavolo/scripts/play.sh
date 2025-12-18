#!/bin/bash

# --- CONTROLLO RIGOROSO ---
# Verifichiamo che TUTTI i personaggi siano vivi e vegeti
if ! docker ps | grep -q "lupo" || \
   ! docker ps | grep -q "capra" || \
   ! docker ps | grep -q "cavolo" || \
   ! docker ps | grep -q "contadino"; then
    
    echo "⛔ PARTITA TERMINATA O NON VALIDA!"
    echo "Sembra che qualcuno sia stato mangiato (o il gioco non è partito)."
    echo "Mancano dei container fondamentali."
    echo ""
    echo "👉 DEVI RESETTARE IL GIOCO."
    echo "Esegui: ./start_game.sh"
    exit 1
fi
# --------------------------

# Funzione per controllare dove si trova un container
get_location() {
    local container=$1
    # Controlla se è connesso a riva_sx
    if docker network inspect riva_sx | grep -q "\"Name\": \"$container\""; then
        echo "SX"
    else
        echo "DX"
    fi
}

# Funzione per spostare un container
move_container() {
    local container=$1
    local from_net=$2
    local to_net=$3
    
    docker network disconnect "$from_net" "$container"
    docker network connect "$to_net" "$container"
}

check_game_status() {
    # Controlliamo se i container sono ancora vivi
    if ! docker ps | grep -q "lupo"; then
        echo "💀 GAMEOVER! Il Lupo è morto o ha mangiato qualcosa ed è esploso!"
        exit 1
    fi
    if ! docker ps | grep -q "capra"; then
        echo "💀 GAMEOVER! La Capra ha mangiato il cavolo o è stata mangiata!"
        exit 1
    fi
    
    # Condizione di vittoria: Tutti a destra
    lupo_loc=$(get_location lupo)
    capra_loc=$(get_location capra)
    cavolo_loc=$(get_location cavolo)
    contadino_loc=$(get_location contadino)
    
    if [ "$lupo_loc" == "DX" ] && [ "$capra_loc" == "DX" ] && [ "$cavolo_loc" == "DX" ] && [ "$contadino_loc" == "DX" ]; then
        echo "🏆 VITTORIA! Tutti sono salvi sulla riva destra!"
        exit 0
    fi
}

# --- INIZIO GIOCO ---
echo "🎮 Benvenuto a Capra e Cavoli - Docker Edition"

while true; do
    clear
    echo "=========================================="
    echo "🌊 STATO DEL FIUME"
    echo "=========================================="
    
    # Visualizziamo chi è dove
    echo "RIVA SINISTRA (Partenza):"
    docker network inspect riva_sx -f '{{range .Containers}}{{.Name}} {{end}}'
    echo "------------------------------------------"
    echo "RIVA DESTRA (Arrivo):"
    docker network inspect riva_dx -f '{{range .Containers}}{{.Name}} {{end}}'
    echo "=========================================="
    
    # 1. Capire dov'è il contadino (e quindi la barca)
    BARCA_LOC=$(get_location contadino)
    
    if [ "$BARCA_LOC" == "SX" ]; then
        CURRENT_NET="riva_sx"
        DEST_NET="riva_dx"
        echo "🚣 La barca è a SINISTRA. Chi porti a destra?"
    else
        CURRENT_NET="riva_dx"
        DEST_NET="riva_sx"
        echo "🚣 La barca è a DESTRA. Chi porti a sinistra?"
    fi
    
    echo " Opzioni: [l]upo, [c]apra, [v]cavolo, [n]essuno (solo contadino), [q]uit"
    read -p "Scelta > " scelta
    
    PASSEGGERO=""
    case $scelta in
        l) PASSEGGERO="lupo" ;;
        c) PASSEGGERO="capra" ;;
        v) PASSEGGERO="cavolo" ;;
        n) PASSEGGERO="" ;;
        q) exit 0 ;;
        *) echo "Scelta non valida"; sleep 1; continue ;;
    esac
    
    # 2. Validazione mossa
    if [ ! -z "$PASSEGGERO" ]; then
        # Controlla se il passeggero è sulla stessa riva del contadino
        PASS_LOC=$(get_location $PASSEGGERO)
        if [ "$PASS_LOC" != "$BARCA_LOC" ]; then
            echo "⚠️  Errore: $PASSEGGERO non è su questa riva!"
            sleep 2
            continue
        fi
    fi
    
    # 3. Esecuzione mossa
    echo "🔄 Spostamento in corso..."
    
    # Sposta SEMPRE il contadino
    move_container "contadino" "$CURRENT_NET" "$DEST_NET"
    
    # Sposta il passeggero se c'è
    if [ ! -z "$PASSEGGERO" ]; then
        move_container "$PASSEGGERO" "$CURRENT_NET" "$DEST_NET"
    fi
    
    # 4. Attesa che la logica dei container giri
    echo "⏳ Vediamo se succede qualcosa..."
    sleep 3 # Diamo tempo ai container di pingarsi e reagire
    
    # 5. Controllo stato
    check_game_status
    
done