#!/bin/bash

sudo apt-get -y install apache2 ssl-cert
sudo systemctl enable --now httpd
echo " myweb ! " > /var/www/html/index.html
