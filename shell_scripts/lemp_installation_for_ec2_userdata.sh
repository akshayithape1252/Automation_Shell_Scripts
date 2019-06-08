#!/bin/bash

#The LEMP Stack(Linux,Nginx,Mysql,PHP) it is a collection of software that can be used for dynamic web pages and web 
#application. In LEMP stack, L for Linux operating system, E for Nginx web server, M for Mysql database server and 
#P for PHP lang.So we will used this script for automating the LEMP stack installation.
#
#Prerequisites :-
#1. You required the root access to execute this shell script 
#
#There are Five step in LEMP installation. We see this step one by one
#
#Step 1 :- Installing The Nginx Web Server
#Step 2 :- Installing MySQL Database Server
#Step 3 :- Installing PHP 
#Step 4 :- Configuring Nginx to Use the PHP Processor
#Step 5 :- Creating a PHP File to Test Configuration 
#
#Tested On:-
#On AWS Ubuntu 16.04
#On AWS Ubuntu 18.04
#On Docker Ubuntu

# Variables Declaration
DB_PASS='root'
DB_USER='root'

# Check Weather The Script Is Execute By Root User Or Not
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo "LEMP Stack Installation Setup by Shell Script";
echo "---------------------------------------------";

# Updating Ubuntu First
echo "Updating Ubuntu"
apt-get update

# Step 1 - Installing The Nginx Web Server
echo "-------------------------------";
echo "Checking Nginx is installed or not":

if [ $(dpkg-query -W -f='${Status}' nginx  2>/dev/null | grep -c "ok installed") -eq 0 ];
then
        echo "Installing Nginx "
        apt-get install nginx -y;
	service nginx start
else
        echo "Nginx is already installed"
fi

# Step 2 :- Installing MySQL Database Server
echo "-------------------------------";
echo "Checking Mysql-server is installed or not":

if [ $(dpkg-query -W -f='${Status}' mysql-server mysql-client  2>/dev/null | grep -c "ok installed") -eq 0 ];
then
        echo "Installing mysql "
        debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
        debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
        apt-get install mysql-server mysql-client -y;
	service mysql start
	# Set The Password Mysql User
	mysql -u $DB_USER -p"$DB_PASS" -e "ALTER USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_PASS';"
else
        echo "mysql is already installed"
fi

# Step 3 :- Installing PHP
echo "-------------------------------";
echo "Checking PHP is installed or not":

if [ $(dpkg-query -W -f='${Status}' php  2>/dev/null | grep -c "ok installed") -eq 0 ];
then
        echo "Installing PHP "
        export DEBIAN_FRONTEND=noninteractive 
        apt-get install -y tzdata
        ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
        dpkg-reconfigure --frontend noninteractive tzdata
        apt-get install php-fpm php-cli php-mysql -y;
	PHP_VERSION=$(php --version | head -n 1 | cut -d " " -f 2 | cut -c 1-3)
	service php$PHP_VERSION-fpm start
else
        echo "PHP is already installed"
fi

# Declaration The Variable For PHP_Version
PHP_VERSION=$(php --version | head -n 1 | cut -d " " -f 2 | cut -c 1-3)

# Step 4 :- Configuring Nginx to Use the PHP Processor
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default_old
# Taking the backup default configuration 

# Write The Virtual Host File For Our Website
cat > /etc/nginx/sites-available/default <<EOF
server {
        listen [::]:80;
        listen 80;
        server_name _;
        root /var/www/html;
        index index.php;
        location / {
        	try_files \$uri \$uri/ =404;
	}
        location ~ \.php$ {
        	include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
	}
}
EOF
# Test your new configuration file for syntax errors
nginx -t

# Reload PHP-FPM Service
service php$PHP_VERSION-fpm restart

# Reload Nginx Web Server 
nginx -s reload

# Step 5 :- Creating a PHP File to Test Configuration 
cat > /var/www/html/index.php <<EOF
<?php
phpinfo();
?>
EOF

echo "Open Web Brower and Type http://localhost in URL and Hit Enter"
echo "LEMP Stack Installation Is Done"
echo "-------------------------------"
