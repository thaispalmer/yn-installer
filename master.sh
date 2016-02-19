#!/bin/bash

YN_USER="yournode"
YN_GROUP="yournode"
YN_BASEPATH="/var/yournode"
YN_MONGOPORT="35642"
YN_DEFAULTS_REPOSITORY="git@bitbucket.org:yournode/yn-defaultpages.git"
YN_AUTOMATION_REPOSITORY="git@bitbucket.org:yournode/yn-automation.git"

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

echo "Creating MongoDB service file for YourNode (yn-mongod)..."
printf "[Unit]\n" > /etc/systemd/system/yn-mongod.service
printf "Description=High-performance, schema-free document-oriented database\n" >> /etc/systemd/system/yn-mongod.service
printf "After=network.target\n\n" >> /etc/systemd/system/yn-mongod.service
printf "[Service]\n" >> /etc/systemd/system/yn-mongod.service
printf "User=mongodb\n" >> /etc/systemd/system/yn-mongod.service
printf "ExecStart=/usr/bin/mongod --quiet --config \"$YN_BASEPATH/mongodb.conf\"\n\n" >> /etc/systemd/system/yn-mongod.service
printf "[Install]\n" >> /etc/systemd/system/yn-mongod.service
printf "WantedBy=multi-user.target\n" >> /etc/systemd/system/yn-mongod.service

echo "Reloading system services..."
systemctl daemon-reload
echo "Enabling yn-mongod on system start..."
systemctl enable yn-mongod
echo "Starting yn-mongod..."
systemctl start yn-mongod

echo "Cloning YourNode Default Pages..."
git clone "$YN_DEFAULTS_REPOSITORY" "$YN_BASEPATH/lib/defaultpages"

echo "Enabling default pages on SELinux to be served..."
chcon -Rt httpd_sys_content_t "$YN_BASEPATH/lib/defaultpages"

echo "Configuring nginx..."
sed -c -i "s/.*\(http {\).*/\http {\n    # YourNode\n    include $YN_BASEPATH\/proxy\/apps-enabled\/\*.conf\n/" /etc/nginx/nginx.conf
echo "Enabling nginx on system start"
systemctl enable nginx
echo "Starting nginx..."
systemctl start nginx

echo "Cloning YourNode Automation Scripts..."
git clone "$YN_AUTOMATION_REPOSITORY" "$YN_BASEPATH/lib/automation"

echo "Installing YourNode Master Automation..."
ln -s "$YN_BASEPATH/lib/automation/master/yn-master.js" "$YN_BASEPATH/bin/yn-master"
ln -s "$YN_BASEPATH/lib/automation/master/yournode-master.conf" "$YN_BASEPATH/bin/yournode-master.conf"
export PATH=$PATH:$YN_BASEPATH/bin

echo "Creating SSH Keys for the Master Server..."
ssh-keygen -t rsa -C "YourNode Master Server Key" -N "" -f "$YN_BASEPATH/master.key"

echo "Changing folder and files owners..."
chown -R "$YN_USER:$YN_GROUP" "$YN_BASEPATH"

echo "YourNode Master - Installation sucessful."
echo "The Master Server public SSH Key is located at $YN_BASEPATH/master.key.pub"
