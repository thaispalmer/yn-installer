#!/bin/bash

YN_USER="yournode"
YN_GROUP="yournode"
YN_BASEPATH="/var/yournode"
YN_MONGOPORT="35642"
YN_REPOSITORY="git@bitbucket.org:yournode/yn-automation.git"

echo "__     __              _   _           _"
echo "\ \   / /             | \ | |         | |"
echo " \ \_/ /__  _   _ _ __|  \| | ___   __| | ___"
echo "  \   / _ \| | | | '__| . \` |/ _ \ / _\` |/ _ \\"
echo "   | | (_) | |_| | |  | |\  | (_) | (_| |  __/"
echo "   |_|\___/ \__,_|_|  |_| \_|\___(_)__,_|\___|"
echo ""
echo "          Master Server Installation"
echo ""

echo "Installing dependencies..."
echo "Installing Extra Packages for Enterprise Linux (EPEL) repositories."
yum --y install epel-release
echo "Installing Node.js and NPM..."
yum --y install nodejs npm
echo "Installing Git..."
yum --y install git
echo "Installing MongoDB..."
yum --y install mongodb-org mongodb-org-server

echo "Creating folder structure..."
mkdir -p "$YN_BASEPATH"
mkdir -p "$YN_BASEPATH/db"
mkdir -p "$YN_BASEPATH/logs"
mkdir -p "$YN_BASEPATH/proxy/apps-available"
mkdir -p "$YN_BASEPATH/proxy/apps-enabled"
mkdir -p "$YN_BASEPATH/keys"
mkdir -p "$YN_BASEPATH/lib"
mkdir -p "$YN_BASEPATH/bin"

echo "Creating MongoDB configuration file..."
printf "port = $YN_MONGOPORT\n" > "$YN_BASEPATH/mongodb.conf"
printf "auth = true\n" >> "$YN_BASEPATH/mongodb.conf"
printf "dbpath = \"$YN_BASEPATH/db\"\n" >> "$YN_BASEPATH/mongodb.conf"
printf "logpath = \"$YN_BASEPATH/logs/mongodb.log\"\n" >> "$YN_BASEPATH/mongodb.conf"

echo "Enabling mongod on system start"
systemctl start mongod
echo "Starting mongod..."
service mongod start

echo "Configuring nginx..."
sed -c -i "s/.*\(http {\).*/\http {\n    # YourNode\n    include $YN_BASEPATH\/proxy\/apps-enabled\/\*.conf\n/" /etc/nginx/nginx.conf
echo "Enabling nginx on system start"
systemctl start nginx
echo "Starting nginx..."
service nginx start

echo "Clone YourNode Automation Scripts..."
git clone "$YN_REPOSITORY" "$YN_BASEPATH/lib"

echo "Installing YourNode Master Automation..."
ln -s "$YN_BASEPATH/lib/master/yn-master.js" "$YN_BASEPATH/bin/yn-master"
ln -s "$YN_BASEPATH/lib/master/yournode-master.conf" "$YN_BASEPATH/bin/yournode-master.conf"
export PATH=$PATH:$YN_BASEPATH/bin

echo "Changing folder and files owners..."
chown -R "$YN_USER:$YN_GROUP" "$YN_BASEPATH"

echo "YourNode Master - Installation sucessful."
