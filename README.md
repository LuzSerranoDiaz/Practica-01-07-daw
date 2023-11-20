# Practica-01-07-daw
# Creacion de instancia en AWS

![aws](https://github.com/LuzSerranoDiaz/Practica-01-05-daw/assets/125549381/5efad519-0b5d-49fb-84b0-920bee02954a)

Se crea una instancia de Ubuntu 23.04 con sabor t2.micro (la gratuita) para que no haya errores con la memoria ram.

Se utiliza el par de claves generadas en por aws.

# Documento tecnico practica 1 despliegue de aplicaciones web DAW

En este documento se presentará los elementos para instalar LAMP, junto otras herramientas y modificaciones.

## Install_lamp.sh
```bash
#!/bin/bash
 
#Para mostrar los comandos que se van ejecutando
set -ex

#Actualizamos la lista de repositorios
apt update
#Actualizamos los paquetes del sistema
#apt upgrade -y

#Instalamos el servidor APACHE
sudo apt install apache2 -y

#Instalamos MYSQL SERVER
apt install mysql-server -y

#Instalar php 
sudo apt install php libapache2-mod-php php-mysql -y

#Copiamos archivo de configuracion de apache
cp ../conf/000-default.conf /etc/apache2/sites-available

#Reiniciamos servicio apache
systemctl restart apache2

#Copiamos el archivo de prueba de PHP
cp ../php/index.php /var/www/html

#Cambiamos usuario y propietario de var/www/html
chown -R www-data:www-data /var/www/html
```
En este script se realiza la instalación de LAMP en la última version de **ubuntu server** junto con la modificación del archivo 000-default.conf, para que las peticiones que lleguen al puerto 80 sean redirigidas al index encontrado en /var/www/html
### Como ejecutar Install_lamp.sh
1. Abre un terminal
2. Concede permisos de ejecución
 ```bash
 chmod +x install_lamp.sh
 ```
 o
 ```bash
 chmod 755 install_lamp.sh
 ```
 3. Ejecuta el archivo
 ```bash
 sudo ./install_lamp.sh
 ```
## .nev
```bash
# Variables de configuración
#-----------------------------------------------------------------------
CERTIFICATE_EMAIL=demo@demo.es
CERTIFICATE_DOMAIN=practica-15.ddns.net
#-----------------------------------------------------------------------
```
## setup_letsencrypt_certificate.sh
```bash
#!/bin/bash
 
# Para mostrar los comandos que se van ejecutando (x) y parar en error(e)
set -ex

# Actualizamos la lista de repositorios
 apt update
# ACtualizamos los paquetes del sistema
# apt upgrade -y
source .env
```
Se realizan los pasos premeditarios:
1. Actualizar repositorios
2. Se importa .env
```bash
#instalacion actualizacion snapd
sudo snap install core; sudo snap refresh core

#Eliminar instalaciones previas
sudo apt remove certbot

#Instalamos certbot con snpad
sudo snap install --classic certbot

#Un alias para el comando certbot
sudo ln -fs /snap/bin/certbot /usr/bin/certbot
```
1. Realizamos la instalación y actualización de snapd
2. Borramos versiones anteriores para que no de error si se tiene que ejecutar más de una vez
3. Utilizamos snapd para instalar el cliente de certbot
4. Y le damos un alias o link utilizando el comando `ln`
```bash
#certificado y configuramos el servidor web apache

sudo certbot \
    --apache \
    -m $CERTIFICATE_EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $CERTIFICATE_DOMAIN \
    --non-interactive
```
Con el comando `certbot --apache` realizamos el certificado y con estos siguientes parametros automatizamos el proceso:
* `-m $CERTIFICATE_EMAIL` : indicamos la direccion de correo que en este caso es `demo@demo`
* `--agree-tos` : indica que aceptamos los terminos de uso
* `--no-eff-email` : indica que no queremos compartir nuestro email con la 'Electronic Frontier Foundation' 
* `-d $CERTIFICATE_DOMAIN` : indica el dominio, que en nuestro caso es 'practica-15.ddns.net', el dominio conseguido con el servicio de 'no-ip'
* `--non-interactive` : indica que no solicite ningún tipo de dato de teclado.

## deploy_wordpress_root_directory.sh
```bash
#!/bin/bash
 
# Para mostrar los comandos que se van ejecutando (x) y parar en error(e)
set -ex

source .env

# Actualizamos la lista de repositorios
 apt update
# ACtualizamos los paquetes del sistema
# apt upgrade -y

#instalamos zip
sudo apt install zip -y

#instalamos tar
sudo apt install tar

#borrar versiones anteriores en tmp wordpress
rm -rf /tmp/latest.tar
rm -rf /tmp/wordpress
rm -rf /var/www/html/wp-admin
rm -rf /var/www/html/wp-content
rm -rf /var/www/html/wp-includes
```
Realizamos los pasos previos para que el proceso funcione
1. Importamos .env
2. Actualizamos los repositorios
3. Instalamos zip
4. Instalamos tar
5. Borramos las versiones anteriores a wordpress que causarían problemas en instalaciones repetidas
```bash
#poner wordpress en tmp
wget http://wordpress.org/latest.tar.gz -P /tmp

#descomprimimos el archivo gz
gunzip /tmp/latest.tar.gz

#descomprimimos el archivo tar
tar -xvf /tmp/latest.tar -C /tmp

#Movemos wordpress 
mv -f /tmp/wordpress/* /var/www/html
```
1. Descargamos el paquete de wordpress
2. Descomprimimos el archivo `.gz`
3. Descomprimos el archivo `.tar`
4. Movemos los archivos de wordpress a `/var/www/html`
```bash
#creamos la base de datos
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@'$IP_CLIENTE_MYSQL'"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@'$IP_CLIENTE_MYSQL' IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@'$IP_CLIENTE_MYSQL'"
```
Creamos la base de datos con estos comandos, inyectando las sentencias directamente con `<<<`
1. Destruye la BD(WORDPRESS_DB) si existe
2. Crea la DB(WORDPRESS_DB)
3. Destruye el usuario(WORDPRESS_USER) si existe
4. Crea el usuario(WORDPRESS_USER) con su contraseña(root)
5. Le da al usuario todos los permisos de la BD(WORDPRESS_DB) al usuario(WORDPRESS_USER) 
```

#Creamos un archivo de configuracion 
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

#Configuramos el archivo wp-config.php
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wp-config.php
```
Creamos una archivo de configuracion a partir de uno de prueba en wordpress y lo configuramos con el comando `sed`, poniendo el nombre de la BD, el usuario, la contraseña y el host.

```bash
