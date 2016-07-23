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
drupal_profile="elespectador_profile"
# Ruta predeterminada de instalación de Drupal
public_directory=/var/www/elespectador
# Nombre del usuario de base de datos
mysql_username="root"
# Password del usuario de base de datos
mysql_password="123456"
# Nombre de usuario del administrador de Drupal
drupal_account_name="admin"
# Contraseña del usuario administrador de Drupal
drupal_account_pass="admin"
# Nombre de la base de datos
mysql_db_name="elespectador"
# Tipo de instalacion por defecto
default_install_type="local";
# Ruta del directorio raiz del módulo de configuration
profile_configurations_path=$public_directory'/profiles/'$drupal_profile'/config'

echo -e "${BOLD}1 de 5 ==> Vaciando carpeta de instalación...${NONE}"
sudo chmod 777 -R /var/www/elespectador/; sudo rm -rf /var/www/elespectador/*; sudo rm -rf /var/www/elespectador/.*; cd /var/www/elespectador

# Ruta de instalación de drupal
cd $public_directory

echo -e "${BOLD}2 de 5 ==> Clonando el repositorio del profile...${NONE}"
git clone git@bitbucket.org:icckmodules/elespectador-profile.git -b master ./

# Drush make del profile

echo "${BOLD}3 de 5 ==> Ejecutando drush make al profile '$drupal_profile'...${NONE}"
drush make elespectador_profile_stub.make --working-copy --y --verbose

echo

echo -e "${BOLD}4 de 5 ==> Copiando settings file...${NONE}"
cp /var/www/dumps/elespectador/settings.php sites/default/settings.php

# Instalacion del sitio
echo -e "${BOLD}5 de 5 ==> Instalando el sitio${NONE}"
cd $public_directory
drush si $drupal_profile --db-url=mysql://$mysql_username:$mysql_password@localhost/$mysql_db_name --account-name=$drupal_account_name --account-pass=$drupal_account_pass -y --locale=en --verbose

# Se agregan permisos a la carpeta files
sudo chmod -R 775 $public_directory/sites/default/files;

echo
echo "Drupal se ha instalado correctamente con el profile '$drupal_profile'."
toc=$(date +"%s")
diff=$(($toc-$tic))
echo -e "${YELLOW}==>Tiempo de ejecución: $(($diff / 60)) minutos $(($diff % 60)) segundos. ${NONE}"
exit 0
