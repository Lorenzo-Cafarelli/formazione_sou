#!/bin/bash
# Obiettivo: verificare se il kernel attualmente in uso è il più recente installato sulla macchina.


#Struttura If per rilevare quale distribuzione è presente.
if [[ -f /etc/redhat-release ]]; then
    distro="rhel"
elif [[ -f /etc/lsb-release ]] || [[ -f /etc/debian_version]]; then
    distro="debian"
elif [[ -f /etc/SuSE-release ]] || [[ -f /etc/SUSE-brand ]]; then
    distro="suse"
elif [[ -f /etc/arch-release ]]; then
    distro="arch"
else
    distro="unknown"
fi


echo "Distribuzione rilevata: $distro"

#Ottenere il kernel attuale
current=$(uname -r)
echo "Kernel attualmente in uso: $current"


#Struttura case per ottenre il kernel più recente installato in base allla distro trovata tramite l'If
case $distro in
    rhel)
        latest=$(rpm -q kernel | sed 's/^kernel-//' | sort -V | tail -n 1)
        ;;
    debian)
        latest=$(dpkg --list | grep linux-image | awk '{print $2}' | sed 's/linux-image-//' | sort -V | tail -n 1)
        ;;
    suse)
        latest=$(rpm -q kernel-default | sed 's/^kernel-default-//' | sort -V | tail -n 1)
        ;;
    arch)
        latest=$(uname -r)
        ;;
    *)
        latest=$(ls /boot/vmlinuz-* 2>/dev/null | sed 's/.*vmlinuz-//' | sort -V | tail -n 1)
        ;;
esac

echo "Kernel più recente installato: $latest"


#Struttura If per confronto finale.
if [[ "$current" == "$latest" ]]; then
    echo "TRUE - Il kernel attualmente in uso è il più recente installato."
else
    echo "FALSE - È disponibile un kernel più recente installato."
fi

