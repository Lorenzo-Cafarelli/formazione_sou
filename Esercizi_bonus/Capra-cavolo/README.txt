# 🐺🐐🥬 Capra e Cavoli - Versione Docker

Questo progetto è una simulazione del famoso indovinello logico, realizzata interamente con **Docker**.

L'obiettivo è portare Lupo, Capra e Cavoli dalla riva sinistra alla riva destra del fiume, senza che nessuno venga mangiato.

## 💡 Cosa è stato fatto

Invece di scrivere un normale programma, ho usato i **Container** per creare i personaggi:

1.  **I Personaggi sono Container**: Lupo, Capra, Cavolo e Contadino sono 4 container separati.
2.  **Il Fiume sono le Reti**: Ho creato due reti Docker (`riva_sx` e `riva_dx`). Se due personaggi sono sulla stessa rete, possono "vedersi".
3.  **La Logica è "Viva"**:
    * Se il **Lupo** vede la **Capra** e non c'è il **Contadino**, il container del Lupo si spegne (simula che ha mangiato e la partita finisce).
    * Lo stesso vale per **Capra** e **Cavolo**.
    * Il **Contadino** è l'unico che può tenere tutti calmi.

## 📂 I File del Progetto

* `app/`: Contiene il codice dei personaggi.
* `scripts/`: Contiene i comandi per giocare.
    * `start_game.sh`: Prepara il gioco e mette tutti a sinistra.
    * `play.sh`: Ti permette di spostare i personaggi (la barca).
    * `stop_game.sh`: Cancella tutto alla fine.

---

## 🎮 Come Giocare

### 1. Prepara il gioco
Apri il terminale, entra nella cartella `scripts` e lancia lo script di avvio. Questo crea i personaggi e li mette sulla riva di partenza.

```bash
cd scripts
chmod +x *.sh      # (Solo la prima volta)
./start_game.sh
2. Inizia la partita
Lancia lo script per muovere la barca: