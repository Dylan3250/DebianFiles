#!/bin/bash

### BEGIN INIT INFO
# Provides:          firewall
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Démarre les règles iptables
# Description:       Charge la configuration du pare-feu iptables
### END INIT INFO

##########################################
# Firewall
# Utilité: permet de mettre en place un par-feu efficaces
# Usage: script -start -restart -stop
# Auteur: Dylan BRICAR < contact@site-concept.eu>
# Mise à jour le: 11/09/2019
##########################################

# Définition des couleurs pour les messages
RED='\033[1;31m' # Couleur rouge : $1
GREEN='\033[0;32m' # Couleur verte : $2
NC='\033[0m' # Pas de couleur : $3
BLUE='\033[1;34m' # Couleur bleu : $4
ORANGE='\033[0;33m' # Couleur orange : $5

function start {
    ##########################################
    # Fonction de démarrage des règles
    ##########################################

    # [SSH, HTTP, HTTPS, SMTP, SMTP, POP, IMAP, POPS]
    BASICS_PORTS="22,80,443,25,587,110,143,995"
    # Adresse IP desquelles le serveur ne doit pas se méfier
    OFFICIELS_IP="[IP],[IP],[IP]"
    # Ports des serveurs à bloquer qui ne doivent pas être accessible
    BUNGEE_PORTS="[PORT],[PORT]"

    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    echo -e "$4[OK] Refuse toutes les connexions sauf la sortie.$3"
    
    # Début de la gestion du serveur Minecraft
    
    iptables -t filter -N bungee
    iptables -t filter -A bungee -s $OFFICIELS_IP -j ACCEPT
    iptables -t filter -A bungee -j DROP
    iptables -t filter -A INPUT -p tcp -m multiport --dports $BUNGEE_PORTS -j bungee
    echo -e "$4[OK] Refuse de se connecter au(x) port(s) ${BUNGEE_PORTS} des serveurs avec les IP ${OFFICIELS_IP}.$3"
    
    # Fin de la gestion du serveur Minecraft

    iptables -t filter -A INPUT -i lo -j ACCEPT
    echo -e "$4[OK] Connexion à localhost.$3"

    iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    echo -e "$4[OK] Ne coupe pas les connexions établies.$3"

    iptables -t filter -A INPUT -p tcp -m multiport --dports $BASICS_PORTS -j ACCEPT
    echo -e "$4[OK] Ouvre les ports ${BASICS_PORTS}.$3"
    
    iptables -t filter -A INPUT -p tcp -s ${OFFICIELS_IP} --dport 3306 -j ACCEPT
    iptables -t filter -A INPUT -p tcp --dport 3306 -j DROP
    echo -e "$4[OK] Autorise l'accès à MySQL que via les IP ${OFFICIELS_IP}.$3"

    iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
    echo -e "$4[OK] Refuse les packets invalides.$3"

    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags ACK,URG URG -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags PSH,ACK PSH -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,PSH,URG -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,ACK,URG -j DROP
    iptables -t mangle -A PREROUTING -s 224.0.0.0/8 -j DROP
    iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP
    iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP
    iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP
    iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP
    iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP
    iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP
    iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP
    iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP
    echo -e "$4[OK] Refuse les packets avec des combinaisons étranges.$3"

    iptables -t mangle -A PREROUTING -p icmp -j DROP
    echo -e "$4[OK] Empêche le ping de l'IP.$3"

    iptables -t mangle -A PREROUTING -f -j DROP
    echo -e "$4[OK] Bloque la fragmentation TCP.$3"

    iptables -t raw -A PREROUTING -i eth0 -p tcp -m tcp --syn -m multiport --dports $BASICS_PORTS -m hashlimit --hashlimit-above 200/sec --hashlimit-burst 1000 --hashlimit-mode srcip --hashlimit-name syn --hashlimit-htable-size 2097152 --hashlimit-srcmask 24 -j DROP
    iptables -t filter -A INPUT -p tcp -m connlimit --connlimit-above 100 -j REJECT
    echo -e "$4[OK] Limite le nombre de connexion par une même IP.$3"

    iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
    iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP
    echo -e "$4[OK] Limite le nombre de packets RST.$3"

    iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 100 -j ACCEPT
    iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP
    echo -e "$4[OK] Limite les nouvelles connexions TCP par seconde et par même IP.$3"

    iptables -t raw -A PREROUTING -i eth0 -p tcp -m multiport --dports $BASICS_PORTS -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j CT --notrack
    iptables -t filter -A INPUT -i eth0 -p tcp -m multiport --dports $BASICS_PORTS -m tcp -m state --state INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460
    iptables -t mangle -A INPUT -i eth0 -p tcp -m multiport --dports $BASICS_PORTS -m tcp -m state --state INVALID -j DROP
    echo -e "$4[OK] Limite le nombre de paquets SYN pour palier aux soucis du SynProxy.$3"

    iptables -A INPUT -m recent --rcheck --seconds 86400 --name portscan --mask 255.255.255.255 --rsource -j DROP
    iptables -A INPUT -m recent --remove --name portscan --mask 255.255.255.255 --rsource
    iptables -A INPUT -p tcp -m multiport --dports 25,445,1433,3389 -m recent --set --name portscan --mask 255.255.255.255 --rsource -j DROP
    echo -e "$4[OK] Limite le scan de ports.$3"

    echo -e "\n$2[FIN] Firewall activé !$3"
}

function stop {
    ##########################################
    # Fonction d'arrêt des règles
    ##########################################

    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    echo -e "$1[OK] Accepte toutes les connexions.$3"
	
    iptables -t nat -F
    iptables -t mangle -F
    iptables -F
    iptables -X
    iptables -Z
    echo -e "$1[OK] Supprime toutes les règles actives et les chaînes personnalisées.$3"

    echo -e "\n$2[FIN] Suppresion de toutes les règles effectué avec succès !$3"
}

##########################################
# Réagit en fonction de ce qui est demandé
##########################################

case "$1" in
    start|restart)
        stop ${RED} ${GREEN} ${NC}
        echo -e ""
        start ${RED} ${GREEN} ${NC} ${BLUE}
    ;;
    stop)
        stop ${RED} ${GREEN} ${NC}
    ;;
    *)
        echo -e "${GREEN}Utilisation : ${BLUE}$0 {${ORANGE}start${BLUE}|${ORANGE}stop${BLUE}|${ORANGE}restart${BLUE}}";
        exit 1
    ;;
esac

exit 0