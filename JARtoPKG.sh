#!/bin/bash

##################################################
# JARtoPKG
# Utilité: permets de transformer un .jar en .pkg sur MacOS
# Auteur: Dylan BRICAR <contact@site-concept.eu>
# Mise à jour le: 29/12/2020
##################################################

# Définition des couleurs pour les messages
GREEN='\033[0;32m' # Couleur verte
NC='\033[0m' # Pas de couleur

# Début de la configuration pour l'application

APP_NAME="Frozenia"
APP_MAIN_NAME="fr.fye.bootstrap.FrozBootstrap"
LINK_JAR="http://cdn.frozenia.fr/launcher/Frozenia.jar"
LINK_PNG="https://frozenia.fr/ressources/images/Frozenia.png"
JAVA_HOME=`/usr/libexec/java_home -v 1.8`

# Fin de la configuration pour l'application

mkdir ~/Desktop/$APP_NAME
cd ~/Desktop/$APP_NAME
echo "$GREEN[OK] Création du dossier contenant toutes les manipulations.$NC"

curl $LINK_JAR -o "$APP_NAME.jar"
curl --remote-name $LINK_PNG
sips -z 100 100 -p 150 150 "$APP_NAME.png" --out "$APP_NAME-background.png"
mkdir $APP_NAME.iconset
sips -z 128 128 "$APP_NAME.png" --out "$APP_NAME.iconset/icon_128x128.png"
iconutil --convert icns "$APP_NAME.iconset"
mkdir -p package/macosx
cp -v *.png *.icns package/macosx
echo "$GREEN[OK] Récupère le .jar en ligne ainsi que l'icône et le convertis en .icns.$NC"

${JAVA_HOME}/bin/javapackager \
  -deploy -Bruntime="" \
  -native pkg \
  -Bicon=package/macosx/Frozenia.icns \
  -srcdir . \
  -srcfiles $APP_NAME.jar \
  -outdir out \
  -outfile Frozenia \
  -appclass $APP_MAIN_NAME \
  -name $APP_NAME \
  -title $APP_NAME \
  -v
echo "$GREEN[OK] Crée le fichier .pkg en fonction du .jar et des icônes générés.$NC"

cp out/bundles/$APP_NAME-*.pkg $APP_NAME-installer.pkg
echo "$GREEN[OK] Copie le résultat à l'emplacement : $PWD/$APP_NAME-installer.pkg.$NC"