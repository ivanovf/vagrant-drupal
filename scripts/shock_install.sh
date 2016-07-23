#!/bin/bash
BOLD='\033[1;32m'
YELLOW='\033[1;33m'
NONE='\033[00m'
tic=$(date +"%s")
NOW=$(date +"%Y_%m")

# Se crea el dirctorio de dumps si este no existe
mkdir -p /tmp/shock
cd /tmp/shock/
dir=$(pwd)
echo -e "${BOLD}1 de 10 ==> Descargando dumps desde shockdev...${NONE}"
scp -r shockdev@192.237.177.229:/home/shockdev/cron-scripts/shockdevfilesbackup/*.tar.gz .

sql_file=$(ls $dir | grep sql)

echo -e "${BOLD}2 de 10 ==> Extrayendo dump de base de datos: $sql_file ${NONE}"
tar xvf $dir/$sql_file

echo -e "${BOLD}3 de 10 ==> Extrayendo dump de Archivos...${NONE}"
tar xvf $dir/$NOW.tar.gz

sql_file_unzip=$(ls $dir | grep sql | head -1)

echo -e "${BOLD}4 de 10 ==> Instalando base de datos... ${sql_file_unzip}${NONE}"
sshpass -p '123456' mysql -uroot -p shock < $dir/$sql_file_unzip

echo -e "${BOLD}5 de 10 ==> Vaciando carpeta de instalación...${NONE}"
sudo chmod 777 -R /var/www/cromos/; sudo rm -rf /var/www/shock/*; sudo rm -rf /var/www/shock/.*; cd /var/www/shock

echo -e "${BOLD}6 de 10 ==> Clonando repo de shock... ${NONE}"
git clone git@git.assembla.com:shock-com-co.git .

echo -e "${BOLD}7 de 10 ==> Ejecutando make ...${NONE}"
drush make -y --no-core --contrib-destination=sites/default --working-copy shock-com-co.custom.make

echo -e "${BOLD}8 de 10 ==> Copiando settings file...${NONE}"
cp /var/www/dumps/shock/settings.php sites/default/settings.php

echo -e "${BOLD}9 de 10 ==> Copiando carpeta de archivos...${NONE}"
mkdir -p sites/default/files/content_files/
cp -avr $dir/$NOW sites/default/files/content_files/$NOW

echo -e "${BOLD}10 de 10 ==> Reconstruyendo el registro ...${NONE}"
drush rr

rm -rf $dir

toc=$(date +"%s")
diff=$(($toc-$tic))
echo -e "${YELLOW}==>Tiempo de ejecución: $(($diff / 60)) minutos $(($diff % 60)) segundos. ${NONE}"
#drush field-delete field_cabecera2 --bundle=infografia
#drush field-delete field_mensaje2 --bundle=infografia
#git rm -rf entity/ ds/ date/ media/ webform/ views/ ctools/ picture/ imce/
#awk '{printf $0}'
# comando > file.txt