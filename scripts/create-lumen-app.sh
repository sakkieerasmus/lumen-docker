#!/usr/bin/env bash

# This script was created to quickly start your Docker App with all the needed containers.

echo "Initialize the Docker terminal. In-case you are using toolbox."
eval "$(docker-machine env lumen-app)"

# This lists all the containers that you might be running so that you can make informative decisions.
echo "docker ps"
docker ps


echo "Please see the containers (IF ANY) that will be deleted if you go ahead with this installation. To install a fresh instance of Docker lumen-app please select y? (y/n)"
read q2

if [ "$q2" == "y" ]; then

docker ps -aq --no-trunc | xargs docker rm -f
echo "Remove dangling images"

docker build -t lumen-app .
echo "Docker image is build"

else
    exit 1;

fi


# Creating your .htaccess file in the public/ directory
echo "

    <IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews
    </IfModule>

    # Redirect root domain to marketing site (but not client domains)
    RewriteEngine On

    # Redirect Trailing Slashes...
    #RewriteBase demo/
    RewriteRule ^(.*)/$ /$1 [L,R=301]

    # Handle Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
" > public/.htaccess;

echo ""
echo "Added/updated(if exists) .htaccess file to public/ directory."

echo "";
echo "Removing app container: 'lumen_app_app' (if exists)";
docker rm -f -v lumen_app_app
echo "";

echo "Removing mysql app container: 'lumen_app_mysql' (if exists)";
docker rm -f -v lumen_app_mysql
echo "";

echo "Rebuilding and start mysql app container: 'lumen_app_mysql'";
docker run --name lumen_app_mysql -e MYSQL_ROOT_PASSWORD=root -p 3306:3306 -d mysql:5.7

echo "";
echo "Rebuilding and start app container: 'lumen_app_app'";
docker run -d -p 80:80 -p 443:443 --link lumen_app_mysql:db -e "DB_HOST=db" --name lumen_app_app -v ${PWD}:/var/www/web-app lumen-app;

echo "
APP_ENV=local
APP_DEBUG=true
APP_KEY=jIjKweUoinHBjdnkjnHuewkjnwkjn

DB_CONNECTION=mysql
DB_HOST=db
DB_DATABASE=lumen_app
DB_USERNAME=lumen_app
DB_PASSWORD=lumen_app

CACHE_DRIVER=file
QUEUE_DRIVER=sync
" > .env;

echo "";
echo "Showing active docker containers:"
docker ps

# We wait a bit before attempting to connect.
echo "";
echo "Waiting for the app container to establish link to the database container...";
sleep 10;

echo "We are listing your docker IP's below, please review before you continue:"
docker-machine ip


echo "Can we connect to your default docker IP '192.168.99.100'? If (y)es please type 'y' else type in your full IP i.e. 192.168.99.101"
read q3

if [ "$q3" == "y" ] || [ "$q3" == "Y" ] || [ "$q3" == "yes" ] || [ "$q3" == "Yes" ]; then

docker exec -it lumen_app_mysql mysql -h 192.168.99.100 -uroot -proot -e \
  "CREATE DATABASE lumen_app;" -e \
  "CREATE USER lumen_app@'%' IDENTIFIED BY 'lumen_app';" -e \
  "GRANT FILE ON *.* TO lumen_app@'%';" -e \
  "GRANT ALL PRIVILEGES ON *.* TO lumen_app@'%';"

echo "Create new database and user for lumen_app";
echo "Created table and granted user permissions to lumen_app";


else

docker exec -it lumen_app_mysql mysql -h "$q3" -uroot -proot -e \
  "CREATE DATABASE lumen_app;" -e \
  "CREATE USER lumen_app@'%' IDENTIFIED BY 'lumen_app';" -e \
  "GRANT FILE ON *.* TO lumen_app@'%';" -e \
  "GRANT ALL PRIVILEGES ON *.* TO lumen_app@'%';"

echo "Create new database and user for lumen_app";
echo "Created table and granted user permissions to lumen_app";

fi

echo "";

echo "Bashing to app container to run any migrations"
echo "============================================================";
echo "
Opening the interactive terminal for app container:

Now, to run all migration and seeder:
    php artisan migrate
"
echo "";

docker exec -it lumen_app_app bash