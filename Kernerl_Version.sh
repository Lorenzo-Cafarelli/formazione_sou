#!/bin/bash
#Obiettivo: capire se il Kernel attualmente running è il più recente installato sulla macchina.

current=$(uname -r)		#Ottenere la versione del kernel in uso.

latest=$(ls /boot/vmlinuz-* 2>/dev/null | sed 's/*vmlinuz-//' | sort -V | tail -n 1)

#Serve a trovare la versione più recente del kernel installata,elenca tutti i file che iniziano con vmlinuz
#elimina gli eventuali errori, rimuove la parte vmlinuz-, ordina i risultati e prende l'ultima riga.

if [[ "$current" == "$latest" ]];	#Confornta le due variabili
then
echo "TRUE"
else
echo "FALSE"
fi

