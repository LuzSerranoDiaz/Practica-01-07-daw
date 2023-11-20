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
CERTIFICATE_DOMAIN=practica-15.ddns.net
WORDPRESS_TITLE=practica-01-07
WORDPRESS_DB_NAME=WORDPRESS_DB
WORDPRESS_DB_USER=WORDPRESS_USER
WORDPRESS_ADMIN_EMAIL=diaz03luz@gmail.com
WORDPRESS_ADMIN_USER=LuzSerranoDiaz
WORDPRESS_ADMIN_PASS=password123
WORDPRESS_DB_PASSWORD=root
IP_CLIENTE_MYSQL=%

#-----------------------------------------------------------------------
```
## 000-default.conf
```
ServerSignature Off
ServerTokens Prod

<VirtualHost *:80>
    #ServerName www.ejemplo.com
    <Directory "/var/www/html">
        AllowOverride All
    </Directory>
    DocumentRoot /var/www/html
    DirectoryIndex index.php index.html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

## .htacess
```
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
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

## deploy_wordpress_with_wcpli.sh
```bash
#!/bin/bash
 
# Para mostrar los comandos que se van ejecutando (x) y parar en error(e)
set -ex

source .env

# Actualizamos la lista de repositorios
 apt update
# ACtualizamos los paquetes del sistema
# apt upgrade -y

# Eliminamos descargas previas de wp-cli
rm -rf /tmp/wp-cli.phar

```
Se realizan los pasos premeditarios:
1. Actualizar repositorios.
2. Actualizar los paquetes del sistema.
3. Se importa .env.
4. Elminamos las versiones anteriores de wp-cli en el sistema. 
```bash

# Descargamos la herramienta wp-cli
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp

# Le damos permisos de ejecución
chmod +x /tmp/wp-cli.phar

# Movemos el archivo a /usr/local/bin
mv /tmp/wp-cli.phar /usr/local/bin/wp

```
1. Se descarga la herramienta de wp-cli.
2. Se le dan permisos de ejecución.
3. Se mueven al archivo `/usr/local/wp` para poder utilizarlo como comando.
```bash

# Eliminamos instalaciones previas de WordPress
rm -rf /var/www/html/*

#Descargamos el codigo fuente de wordpress
wp core download \
  --locale=es_ES \
  --path=/var/www/html \
  --allow-root

```
Se borran las versiones previas de WordPress y se instala una version nueva con estos parametros:
* `--locale=es_ES` : especifica el idioma.
* `--path=/var/www/html` : especifica el directorio de la descarga. 
* `--allow-root` : para poder ejecutar el comando como sudo.
```bash

# Creamos la base de datos y el usuario para wordpress
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

```
Creamos la base de datos con estos comandos, inyectando las sentencias directamente con `<<<`
1. Destruye la BD(WORDPRESS_DB) si existe
2. Crea la DB(WORDPRESS_DB)
3. Destruye el usuario(WORDPRESS_USER) si existe
4. Crea el usuario(WORDPRESS_USER) con su contraseña(root)
5. Le da al usuario todos los permisos de la BD(WORDPRESS_DB) al usuario(WORDPRESS_USER) 
```bash

#creacion del archivo de configuracion
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --dbhost=localhost \
  --path=/var/www/html \
  --allow-root

```
Con este comando se crea el archivo de configuración, se automatiza con estos parametros:
* `--dbname` : se le especifica el nombre de la bases de datos.
* `--dbuser` : se le especifica el nombre del usuario de la base de datos.
* `--dbpass` : se le especifica la contraseña del usuario de la base de datos.
* `--dbhost` : se le especifica host de la base de datos.
```

#Instalacion de wordpress
wp core install \
  --url=$CERTIFICATE_DOMAIN \
  --title="$WORDPRESS_TITLE" \
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASS \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=/var/www/html \
  --allow-root  

```
Con este comando se completa la instalación de wordpress y se automatiza con estos parametros:
* `--url` : se especifica el dominio del sitio de WordPress.
* `--title` : se especifica el titulo del sitio WordPress.
* `--admin-user` : se especifica el usuario administrador.
* `--admin-password` : se especifica la contraseña del usuario administrador.
* `--admin-email` : se especifica el email del usuario administrador.
```bash

# Instalamos un tema de WordPress
wp theme install joyas-shop --activate --path=/var/www/html --allow-root

# Instalamos un plugin para esconder la ruta wp-admin de wordpress
wp plugin install wps-hide-login --path=/var/www/html --allow-root

```
1. Se instala el tema `joyas-shop`, en la ruta `/var/www/html` y puede ser ejecutado por sudo.
2. Se instala el plugin `wps-hide-login` que permite esconder la ruta wp-admin de wordpress.
```
# Modificarmos los premisos de /var/www/html
chown -R www-data:www-data /var/www/html
```
Se modifica los permisos de `/var/www/html` a www-data.
