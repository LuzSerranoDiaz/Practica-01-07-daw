#!/bin/bash
 
# Para mostrar los comandos que se van ejecutando (x) y parar en error(e)
set -ex

# Actualizamos la lista de repositorios
 apt update
# ACtualizamos los paquetes del sistema
# apt upgrade -y

source .env


echo $CERTIFICATE_EMAIL
echo $CERTIFICATE_DOMAIN

#instalacion actualizacion snapd
sudo snap install core; sudo snap refresh core

#Eliminar instalaciones previas
sudo apt remove certbot

#Instalamos certbot con snpad
sudo snap install --classic certbot

#Un alias para el comando certbot
sudo ln -fs /snap/bin/certbot /usr/bin/certbot

#certificado y configuramos el servidor web apache

sudo certbot \
    --apache \
    -m $CERTIFICATE_EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $CERTIFICATE_DOMAIN \
    --non-interactive
