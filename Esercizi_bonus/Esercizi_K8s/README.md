# LABORATORIO STORAGE KUBERNETES: NFS (Inline vs PV/PVC)

## DESCRIZIONE DEL PROGETTO
------------------------
Questo laboratorio dimostra come configurare e utilizzare uno storage 
condiviso NFS (Network File System) all'interno di un cluster 
Kubernetes (Minikube).

L'obiettivo è testare due diverse modalità di montaggio dei volumi:

1. Volume Inline: Definizione diretta del server NFS all'interno 
   del manifesto del Pod (stretto accoppiamento).

2. PV & PVC: Astrazione tramite PersistentVolume e 
   PersistentVolumeClaim (best practice per il disaccoppiamento).

Inoltre, il laboratorio include la configurazione di un Server NFS 
temporaneo direttamente all'interno del cluster per simulare 
un'infrastruttura di storage reale.

----------------------------------------------------------------

## PREREQUISITI
------------
* Minikube (o un cluster K8s funzionante)
* kubectl configurato e puntato al contesto corretto

----------------------------------------------------------------

## ARCHITETTURA
------------
Il sistema è composto da 3 componenti principali:

1. NFS Server (Pod): Un container Alpine Linux configurato come 
   server NFSv4. Espone una directory condivisa ed è raggiungibile 
   tramite un Service ClusterIP.
   
2. Writer Pod (Inline): Un pod che monta il volume specificando 
   direttamente l'IP del server. Scrive un timestamp su un file 
   condiviso ogni 5 secondi.
   
3. Reader Pod (PV/PVC): Un pod che richiede storage tramite PVC. 
   Legge in tempo reale il file scritto dal primo pod.
---

## STEP 1: DEPLOY DEL SERVER NFS

---

Creiamo un server NFS "finto" che gira come Pod nel cluster.

***File:*** 00-nfs-server.yaml

Nota Tecnica: Utilizziamo un volume 'emptyDir' montato su '/share' 
per garantire che la cartella esista prima dell'avvio del demone 
NFS, prevenendo crash all'avvio.

***Comando:***
```bash
kubectl apply -f 00-nfs-server.yaml
```

RECUPERO DELL'IP DEL SERVER

Una volta avviato, recuperare l'indirizzo IP interno del servizio:

***Comando:***
kubectl get svc nfs-service

(Annotare il CLUSTER-IP, es. 10.110.46.106)

---
## STEP 2: CONFIGURAZIONE CLIENT 1 - VOLUME INLINE
---

Approccio "diretto". Utile per test rapidi, sconsigliato in 
produzione perché l'IP è hardcoded.

***File:*** 01-pod-inline.yaml

FIX IMPORTANTE (NFSv4 Root Mapping):
Il server NFSv4 è configurato con fsid=0. Questo trasforma la 
cartella fisica '/share' nella root virtuale.
- Errato: path: /share (Il client cerca /share nella root virtuale)
- Corretto: path: / (Il client monta la root, mappata su /share)

***Comando:***
```bash
kubectl apply -f 01-pod-inline.yaml
```

***Verifica:***
```bash

kubectl exec nfs-inline-lab -- cat /mnt/nfs/test-inline.txt
```
(Output atteso: una lista di date che si aggiorna)

---

## STEP 3: CONFIGURAZIONE CLIENT 2 - PV e PVC

---

Approccio "Enterprise". Disaccoppia la definizione dallo storage.

***File:*** 02-pv-pvc-pod.yaml

Fasi:
1. PersistentVolume (PV): Definizione risorsa fisica (IP + Path /).
2. PersistentVolumeClaim (PVC): Richiesta di spazio (ReadWriteMany).
3. Pod: Usa la PVC come volume.

***Comando:***
(Modificare il PV inserendo il CLUSTER-IP corretto)
```bash
kubectl apply -f 02-pv-pvc-pod.yaml
```

***VERIFICA FINALE***
Controlliamo che il secondo Pod legga i dati del primo.

***Comando:***
kubectl logs -f nfs-pvc-pod

***Output atteso:***
Wed Dec  3 14:35:00 UTC 2025
Wed Dec  3 14:35:05 UTC 2025
...

---
## PULIZIA (CLEANUP)
---

***Rimuovere tutte le risorse:***

kubectl delete -f 02-pv-pvc-pod.yaml\
kubectl delete -f 01-pod-inline.yaml\
kubectl delete -f 00-nfs-server.yaml