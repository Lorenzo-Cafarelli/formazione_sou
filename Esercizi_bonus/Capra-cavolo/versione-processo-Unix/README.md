# Il Gioco del Fiume - Implementazione Shell e Docker

Implementazione distribuita del classico indovinello logico "Lupo, Capra e Cavolo" utilizzando script Bash e container Docker.

Questo progetto dimostra l'uso di processi indipendenti, socket TCP/UDP e gestione dei segnali in un ambiente containerizzato per simulare le interazioni tra gli attori del gioco.

## Architettura del Sistema

Il sistema si basa su tre componenti principali definiti in `docker-compose.yml`:

1.  **Ambiente (riva-sx, riva-dx)**: Due container Alpine Linux che rappresentano le due sponde del fiume. Condividono lo stesso volume di lavoro ma sono isolati a livello di rete.
2.  **Attori (actor.sh)**: Ogni entità (Lupo, Capra, Cavolo, Contadino) è un processo indipendente in esecuzione in background.
    -   Ogni attore ascolta su una porta TCP specifica (es. 8001, 8002...) per segnalare la sua presenza.
    -   Gli attori controllano periodicamente la presenza di predatori o prede sulla stessa riva (localhost) utilizzando `netcat`.
3.  **Arbitro**: Un container separato che ascolta su porta UDP 9999. Riceve i segnali di "Game Over" inviati dagli attori in caso di violazione delle regole (es. il Lupo mangia la Capra).
4.  **Controller (controller.sh)**: Lo script principale che funge da interfaccia utente e orchestratore. Gestisce l'input dell'utente, sposta i processi tra i container (kill/spawn) e verifica le condizioni di vittoria.

## Prerequisiti

* Docker Desktop (o Docker Engine + Docker Compose)
* Ambiente Unix-like (Linux, macOS o WSL su Windows)
* Utility `netcat-openbsd` (installata automaticamente nei container all'avvio)

## Installazione

1.  Clonare il repository o copiare i file nella stessa directory:
    * `actor.sh`
    * `controller.sh`
    * `docker-compose.yml`

2.  Rendere eseguibili gli script bash:

    chmod +x actor.sh controller.sh

## Utilizzo

Avviare il gioco eseguendo lo script controller:

./controller.sh

Lo script eseguirà automaticamente le seguenti operazioni:
1.  Pulizia di eventuali container o volumi precedenti.
2.  Avvio dell'infrastruttura Docker.
3.  Installazione delle dipendenze necessarie nei container.
4.  Avvio dell'interfaccia di gioco.

### Comandi di Gioco

Durante l'esecuzione, utilizzare i seguenti tasti per interagire:

* `l`: Seleziona/Sposta il Lupo
* `c`: Seleziona/Sposta la Capra
* `v`: Seleziona/Sposta il Cavolo
* `n`: Sposta solo il Contadino
* `q`: Esci dal gioco

## Logica Tecnica e Sincronizzazione

Il progetto affronta diverse sfide di concorrenza e gestione processi:

* **Persistenza Porte**: Viene utilizzata una gestione esplicita dei segnali (`trap`) negli script attori per assicurare che le porte TCP vengano liberate immediatamente alla terminazione del processo.
* **Race Conditions**: Lo spostamento del Contadino include un ritardo intenzionale (`sleep`) per garantire che i processi sulla riva di partenza siano terminati completamente prima di lasciare la zona, prevenendo falsi positivi di Game Over.
* **Networking**: La comunicazione avviene internamente alla rete Docker `bridge` denominata "fiume".

## Risoluzione Problemi

Se il gioco non si avvia correttamente o si verificano errori di conflitto sui container:

1.  Interrompere l'esecuzione con `CTRL+C`.
2.  Eseguire una pulizia manuale:

    docker compose down --volumes

3.  Riavviare `./controller.sh`.