# 🐺🐐🥬 Capra e Cavoli — Versione Docker

Questo progetto è una versione containerizzata del famoso indovinello logico "Lupo, Capra e Cavolo".
I personaggi sono rappresentati da container Docker e le due rive del fiume sono due reti Docker: spostando i container tra le reti si simula il passaggio della barca.

## 🔎 Concetto

- I personaggi (Lupo, Capra, Cavolo, Contadino) sono singoli container.
- Ci sono due reti Docker che rappresentano le rive: `riva_sx` e `riva_dx`.
- Se il Lupo e la Capra si trovano sulla stessa riva senza il Contadino, la Capra viene "mangiata" (il container della Capra viene spento). Stessa logica tra Capra e Cavolo.
- Il Contadino è l'unico che può impedire i sacrifici spostando i personaggi in sicurezza.

## 📂 Struttura del progetto

* `app/` — codice dei personaggi (container entrypoints / comportamenti)
* `scripts/` — script per avviare, giocare e fermare il gioco
  * `start_game.sh` — crea le reti e i container, posiziona tutti sulla riva sinistra
  * `play.sh` — interfaccia per muovere la barca/spostare i personaggi
  * `stop_game.sh` — rimuove i container e le reti create

## ⚙️ Requisiti

- Docker installato e funzionante sul sistema.
- Permessi per eseguire comandi Docker (es. utente nel gruppo `docker` oppure usare `sudo` quando necessario).

## 🎮 Come giocare

1. Preparare l'ambiente

   Apri un terminale, vai nella cartella `scripts` e rendi eseguibili gli script (solo la prima volta):

```bash
cd scripts
chmod +x *.sh
./start_game.sh
```

2. Inizia la partita

   Usa lo script principale per muovere la barca e interagire con i personaggi:

```bash
./play.sh
```

   Lo script `play.sh` fornisce le opzioni per spostare il Contadino (e chi sale con lui) tra le rive. Segui le istruzioni mostrate nello script.

3. Terminare la partita

```bash
./stop_game.sh
```

   Questo rimuove i container e le reti create da `start_game.sh`.


## 🛠️ Note e troubleshooting

- Se Docker non è in esecuzione riceverai errori di connessione: avvia Docker Desktop o il demone Docker prima di eseguire gli script.
- Se gli script falliscono per permessi, prova a eseguirli con `sudo` o aggiungi il tuo utente al gruppo `docker` (su macOS normalmente non necessario con Docker Desktop).
- I container rappresentano lo stato del gioco: per resettare tutto usa `./stop_game.sh` e poi `./start_game.sh`.