#!/bin/bash
BOLD='\033[1;32m'
YELLOW='\033[1;33m'
NONE='\033[00m'
tic=$(date +"%s")
NOW=$(date +"%Y_%m")

#
# Valores Predeterminados
#
# @todo Unificar nombres de profiles
# Nombre del profile
case $1 in
  ("caracoltv") drupal_profile="icck_caracoltv_profile"; url_repo="caracol-profile";;
  ("cromos") drupal_profile="icck_cromos_profile"; url_repo="cromos-profile";;
  ("elespectador") drupal_profile="elespectador_profile"; url_repo="elespectador-profile";;
  ("golcaracol") drupal_profile="golcaracol_profile"; url_repo="golcaracol-profile";;
  ("noticias") drupal_profile="icck_noticias_profile"; url_repo="profield-noticias";;
  ("bluradio") drupal_profile="bluradio_profile"; url_repo="bluradio_profile";;
  (*) echo "Este sitio no existe"; exit 0;;
esac

# Ruta predeterminada de instalación de Drupal
public_directory=/var/www/$1
# Nombre del usuario de base de datos
mysql_username="root"
# Password del usuario de base de datos
mysql_password="root"
# Nombre de usuario del administrador de Drupal
drupal_account_name="admin"
# Contraseña del usuario administrador de Drupal
drupal_account_pass="admin"
# Nombre de la base de datos
mysql_db_name=$1

# Ruta del directorio raiz del módulo de configuration
profile_configurations_path=$public_directory'/profiles/'$drupal_profile'/config'
# Ruta del modulo search_api
search_api_path=$public_directory'/profiles/'$drupal_profile'/modules/contrib/search_api_solr/solr-conf/5.x'

echo -e "${BOLD}1 de 7 ==> Vaciando carpeta de instalación...${NONE}"
echo -e "Borre el contenido manualmente desde su carpeta local para agilizar este paso..."
sudo chmod 777 -R /var/www/$1/; sudo rm -rf /var/www/$1/*; sudo rm -rf /var/www/$1/.*; cd /var/www/$1; sudo chmod 777 -R /var/www/$1/

# Ruta de instalación de drupal
cd $public_directory

echo -e "${BOLD}2 de 7 ==> Clonando el repositorio del profile...${NONE}"
git clone git@bitbucket.org:icckmodules/$url_repo.git -b $2 ./

# Drush make del profile
echo "${BOLD}3 de 7 ==> Ejecutando drush make al profile '$drupal_profile'...${NONE}"
  drush make ${drupal_profile}_stub.make --working-copy --force-complete --y
echo

echo -e "${BOLD}4 de 7 ==> Copiando settings file...${NONE}"
cp /home/vagrant/files/$1/settings.php sites/default/settings.php

# Instalacion del sitio
echo -e "${BOLD}5 de 7 ==> Instalando el sitio${NONE}"
cd $public_directory
drush si $drupal_profile --db-url=mysql://$mysql_username:$mysql_password@localhost/$mysql_db_name --account-name=$drupal_account_name --account-pass=$drupal_account_pass -y --locale=en --verbose

# Se agregan permisos a la carpeta files
sudo chmod -R 775 $public_directory/sites/default/files;
sudo chown -R www-user:www-data $public_directory/sites/default/files;

echo -e "${BOLD}6 de 7 ==> Sincronización de la configuración del sitio por medio del módulo configuration...${NONE}"
#
# Sincronización de la configuración del sitio por medio del módulo configuration
#
# Configuración de la ruta de los archivos del módulo configuration
drush vset -y configuration_config_path 'profiles/'$drupal_profile'/config'
# Se crea el dirctorio de configuraciones si este no existe
if [[ ! -d "$profile_configurations_path" ]]; then
  mkdir $profile_configurations_path
fi
cd $profile_configurations_path
# @TODO: Limitar el número de iteraciones del while para evitar bucles infinitos
git clone git@bitbucket.org:icckmodules/configuration-$1.git $profile_configurations_path
echo
drush config-sync --source=./

#Se limpia la cache del sitio
drush cc all

#Se instala el buscador para el sitio
echo -e "${BOLD}7 de 7 ==> Activando buscador solr ... ${NONE}"
if [ -d "$search_api_path" ]; then
  if [ ! -d "/opt/solr/solr-5.3.2/server/solr/$1" ]; then
    sudo mkdir /opt/solr/solr-5.3.2/server/solr/$1
    sudo mkdir /opt/solr/solr-5.3.2/server/solr/$1/conf
  fi
  sudo cp $search_api_path/* /opt/solr/solr-5.3.2/server/solr/$1/conf/
  echo -e "Para iniciar el buscador ejecute el comando /vagrant/scripts/solrun [site_name]"
fi

if [[ "$?" -ne 0 ]]; then
  echo "Drupal se ha instalado con el profile '$drupal_profile' pero se han producido errores."
  exit 2
fi
echo
echo "Drupal se ha instalado correctamente con el profile '$drupal_profile'."
toc=$(date +"%s")
diff=$(($toc-$tic))
echo -e "${YELLOW}==>Tiempo de ejecución: $(($diff / 60)) minutos $(($diff % 60)) segundos. ${NONE}"
exit 0
