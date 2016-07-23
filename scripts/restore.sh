#!/bin/bash
BOLD='\033[1;32m'
YELLOW='\033[1;33m'
NONE='\033[00m'
tic=$(date +"%s")
NOW=$(date +"%Y_%m")

site=$1
url=$2

if [[ ! -d "/var/www/$1" ]]; then
  echo 'El sitio que intenta restaurar no esta instalado. En /var/www/'$1
  exit
fi
cd /var/www/$1
if [ -z "$2" ]
  then
    echo "No existe la url de descarga"
    exit
fi
if [ ${url: -7} == ".tar.gz" ]
	then
		ext="tar.gz"
	else
		ext="gz"
fi

echo -e "${BOLD}Descargando archivo en backup.sql.${ext}...${NONE}"
wget_output=$(wget -O backup.sql.${ext} "$2")
if [ $? -ne 0 ]; then
	echo "No se pudo descargar $2"
	exit
fi
echo -e "${BOLD}Descomprimiendo archivo...${NONE}"
mkdir backup
if [ "$ext" == "tar.gz" ]
	then 
		echo "Tar.gz: "
		tar -xzvf backup.sql.tar.gz --totals -C backup/
		file="$(ls backup/*sql | xargs -n 1 basename)"
		rm backup.sql.tar.gz
	else 
		echo "Tar: "
		gzip -d backup.sql.gz
		mv backup.sql backup/
		file=backup.sql
fi
echo -e "${BOLD}restaurando base de datos desde backup/${file}...${NONE}"
pv backup/$file | mysql -uroot -proot $1
drush sql-query  "UPDATE users SET name='admin' WHERE uid=1"
drush upwd --password="admin" "admin"

echo -e "${BOLD}Eliminando archivos de descarga...${NONE}"
rm -rf backup