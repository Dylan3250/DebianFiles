#!/bin/bash

##################################################
# Backup
# Utilité: permets de faire des sauvegardes complètes de la machine facilement.
# Auteur: Dylan BRICAR <contact@site-concept.eu>
# Mise à jour le: 14/09/2019
##################################################

##################################################
# Une clé est nécessaire afin de ne pas utiliser de mot de passe lors des
# connexion SSH et SCP. En quelques lignes de commandes :
# > apt-get install openssh-server [machine de sauvegarde]
# > ssh-keygen -t rsa [machine de sauvegarde - tout laisser par défaut]
# > ssh-copy-id -i /root/.ssh/id_rsa USER@IP -p PORT [machine distante]
# > ssh -l USER@IP -p PORT [machine de sauvegarde - pour tester sans mot de passe]
##################################################

# Localisation et format de sorties des fichiers sauvegardés.
directory_date=`date +%d-%m-%Y`'_'`date +%H`'h'`date +%M`;
directory_backup="/home/sauvegardes/"
directory_saving="${directory_backup}${directory_date}"

# Utilisateur | IP | PORT de la machine distante.
info_ssh=("USER" "IP" "PORT")

# Déclaration des différents dossiers à sauvegarder.
# [Nom du .tar.gz]="|fichier_à_ignorer |fichier_à_ignorer fichier_a_prendre"
declare -A bungee=(
    ['config']="BungeeCord.jar config.yml locations.yml modules modules.yml start.sh"
    ['plugins']="plugins"
)

declare -A minecraft=(
    ['maps']="world world_the_end world_nether"
    ['config']="start.sh bukkit.yml commands.yml logs server.properties spigot.yml restart"
    ['global_plugins']="|plugins/Essentials* |plugins/Factions* plugins"
    ['importants_plugins']="plugins/Essentials* plugins/Factions.jar mstore"
)

declare -A mysql=(['mysql']="|mysql/tc.log mysql")

set_transfert {
    ##################################################
    # Fonction de création, récupération et suppression
    # du .tar.gz depuis la machine distante.
    ##################################################
    ssh -p ${info_ssh[2]} ${info_ssh[0]}@${info_ssh[1]} "tar pczf ${1} ${2}"
    scp -P ${info_ssh[2]} ${info_ssh[0]}@${info_ssh[1]}:${1} ${3}
    ssh -p ${info_ssh[2]} ${info_ssh[0]}@${info_ssh[1]} "rm -rf ${1}"
}

save {
    ##################################################
    # Traitement des différentes routes à écouter
    # pour mener à bien la sauvegarde du serveur.
    ##################################################
    declare -n array=$2
    # Crée le dossier de sauvegarde sur la machine de sauvegarde s'il n'est pas présent.
    mkdir -p $3

    # Boucle tous les dossiers à sauvegarder (bungee, minecraft, mysql, ...).
    for key in ${!array[@]}
    do
        files=$(echo ${array[$key]} | tr "" "\n")
        # Passe tous les fichiers indiqués en revue et change le chemin de récupération
        # en fonction de s'il y a ou non le symbole d'exclusion " | ".
        for one_file in $files
            do
                if echo "${one_file}" | grep -q "|"
            then
                    path_files+="--exclude='${1}/`echo \"${one_file}\" | sed \"s/|//\"`' ";

            else
                    path_files+="${1}/${one_file} ";
            fi
        done

        # Appel à la fonction de transfert et remet à zéro la variable des fichiers
        # afin de pouvoir s'attaquer à un nouveau dossier de sauvegarde.
        set_transfert /tmp/${key}-${directory_date}.tar.gz "${path_files}" ${3}
        unset path_files
    done
}

# Suppression des dossiers de sauvegarde ancien de plus de 7 jours.
find ${directory_backup} -mtime +7 -exec rm -rf {} \;

# Appel à la fonction de sauvegarde :
# Chemin des fichiers distants | Tableau défini ci-dessus | Chemin de sauvegarde.
save /home/serveurs/bungee bungee "${directory_saving}/serveur_bungee"
save /home/serveurs/minecraft minecraft "${directory_saving}/serveur_faction"
# Dans le cas où tout un dossier doit être sauvegardé, il est nécessaire de
# retourner un dossier en arrière : " /var/lib " et non " /var/lib/mysql ".
save /var/lib mysql "${directory_saving}/mysql"