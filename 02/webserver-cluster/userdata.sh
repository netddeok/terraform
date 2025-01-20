#!/bin/bash
    yum -y install mod_ssl httpd
    echo "myWEB" > /var/www/html/index.html
    systemctl enable --now httpd.service
