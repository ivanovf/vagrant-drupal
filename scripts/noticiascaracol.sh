#!/bin/bash
BOLD='\033[1;32m'
YELLOW='\033[1;33m'
NONE='\033[00m'
tic=$(date +"%s")
NOW=$(date +"%Y_%m")

#
# Valores Predeterminados
#

# Nombre del profile
drupal_profile="icck_noticias_profile"
# Ruta predeterminada de instalación de Drupal
public_directory=/var/www/noticiascaracol
# Nombre del usuario de base de datos
mysql_username="root"
# Password del usuario de base de datos
mysql_password="123456"
# Nombre de usuario del administrador de Drupal
drupal_account_name="admin"
# Contraseña del usuario administrador de Drupal
drupal_account_pass="admin"
# Nombre de la base de datos
mysql_db_name="noticiascaracol"
# Tipo de instalacion por defecto
default_install_type="local";
# Ruta del directorio raiz del módulo de configuration
profile_configurations_path=$public_directory'/profiles/'$drupal_profile'/config'

echo -e "${BOLD}1 de 6 ==> Vaciando carpeta de instalación...${NONE}"
sudo chmod 777 -R /var/www/noticiascaracol/; sudo rm -rf /var/www/noticiascaracol/*; rm -rf /var/www/noticias/.git;

# Ruta de instalación de drupal
cd $public_directory

echo -e "${BOLD}2 de 6 ==> Clonando el repositorio del profile...${NONE}"
git clone git@bitbucket.org:icckmodules/profield-noticias.git -b master ./

# Drush make del profile
while true; do
  echo "${BOLD}3 de 6 ==> Ejecutando drush make al profile '$drupal_profile'...${NONE}"
  drush make icck_noticias_profile_stub.make --working-copy --y
  [[ "$?" == 0 ]] && break && echo
  sleep 3
done
echo

echo -e "${BOLD}4 de 6 ==> Copiando settings file...${NONE}"
cp /var/www/dumps/noticiascaracol/settings.php sites/default/settings.php

# Instalacion del sitio
echo -e "${BOLD}5 de 6 ==> Instalando el sitio${NONE}"
cd $public_directory
drush si $drupal_profile --db-url=mysql://$mysql_username:$mysql_password@localhost/$mysql_db_name --account-name=$drupal_account_name --account-pass=$drupal_account_pass -y --locale=en --verbose

# Se agregan permisos a la carpeta files
sudo chmod -R 775 $public_directory/sites/default/files;

echo -e "${BOLD}6 de 6 ==> Sincronización de la configuración del sitio por medio del módulo configuration...${NONE}"
#
# Sincronización de la configuración del sitio por medio del módulo configuration
#
# Configuración de la ruta de los archivos del módulo configuration
drush vset -y configuration_config_path 'profiles/'$drupal_profile'/config'
# Se crea el dirctorio de configuraciones si este no existe
if [[ ! -d "$DIRECTORY" ]]; then
  mkdir $profile_configurations_path
fi
cd $profile_configurations_path
# @TODO: Limitar el número de iteraciones del while para evitar bucles infinitos
# Drush make del profile
while true; do
  git clone git@bitbucket.org:icckmodules/configuration-caracol.git $profile_configurations_path
  [[ "$?" == 0 ]] && break && echo
  sleep 3
done
echo
drush config-sync --source=./
#Se limpia la cache del sitio
drush cc all

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
