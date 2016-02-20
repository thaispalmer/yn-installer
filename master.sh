#!/bin/bash

YN_USER="yournode"
YN_GROUP="yournode"
YN_BASEPATH="/var/yournode"
YN_MONGO_DEFAULT_PORT="35642"
YN_MONGO_DEFAULT_ADMIN_PASS="Cj6U5CfSwyMFZ8"
YN_MONGO_DEFAULT_USER="yournode"
YN_MONGO_DEFAULT_PASS="Q#FH5ur4Y@2MBn"
YN_DEFAULTS_REPOSITORY="git@bitbucket.org:yournode/yn-defaultpages.git"
YN_AUTOMATION_REPOSITORY="git@bitbucket.org:yournode/yn-automation.git"
YN_DEFAULT_BRANCH="master"

echo "__     __              _   _           _"
echo "\ \   / /             | \ | |         | |"
echo " \ \_/ /__  _   _ _ __|  \| | ___   __| | ___"
echo "  \   / _ \| | | | '__| . \` |/ _ \ / _\` |/ _ \\"
echo "   | | (_) | |_| | |  | |\  | (_) | (_| |  __/"
echo "   |_|\___/ \__,_|_|  |_| \_|\___(_)__,_|\___|"
echo ""
echo "          Master Server Installation"
echo ""

read -r -p "Do you want to install YourNode Master on this server? [y/N] " RESPONSE
if [[ $RESPONSE =~ ^([yY])$ ]]
then
    echo ""
else
    exit
fi

read -r -p "Do you want to use the same branch on all repositories? [Y/n] " RESPONSE
if [[ $RESPONSE =~ ^([nN])$ ]]
then
    read -p "Select branch for Default Pages [$YN_DEFAULT_BRANCH]: " YN_DEFAULTS_BRANCH
    YN_DEFAULTS_BRANCH=${YN_DEFAULTS_BRANCH:-$YN_DEFAULT_BRANCH}
    read -p "Select branch for Automation Scripts [$YN_DEFAULT_BRANCH]: " YN_AUTOMATION_BRANCH
    YN_AUTOMATION_BRANCH=${YN_AUTOMATION_BRANCH:-$YN_DEFAULT_BRANCH}
else
    read -p "From which branch you want to be fetched? [$YN_DEFAULT_BRANCH]: " YN_BRANCH
    YN_DEFAULTS_BRANCH=${YN_BRANCH:-$YN_DEFAULT_BRANCH}
    YN_AUTOMATION_BRANCH=${YN_BRANCH:-$YN_DEFAULT_BRANCH}
fi

read -p "Enter MongoDB port [$YN_MONGO_DEFAULT_PORT]: " YN_MONGO_PORT
YN_MONGO_PORT=${YN_MONGO_PORT:-$YN_MONGO_DEFAULT_PORT}
read -p "Enter MongoDB admin \"ynmdbAdmin\" password [$YN_MONGO_DEFAULT_ADMIN_PASS]: " YN_MONGO_ADMIN_PASS
YN_MONGO_ADMIN_PASS=${YN_MONGO_ADMIN_PASS:-$YN_MONGO_DEFAULT_ADMIN_PASS}
read -p "Enter MongoDB user [$YN_MONGO_DEFAULT_USER]: " YN_MONGO_USER
YN_MONGO_USER=${YN_MONGO_USER:-$YN_MONGO_DEFAULT_USER}
read -p "Enter MongoDB password [$YN_MONGO_DEFAULT_PASS]: " YN_MONGO_PASS
YN_MONGO_PASS=${YN_MONGO_PASS:-$YN_MONGO_DEFAULT_PASS}

echo "Installing dependencies..."
echo "Installing Extra Packages for Enterprise Linux (EPEL) repositories..."
yum -y install epel-release
echo "Installing Node.js and NPM..."
yum -y install nodejs npm
echo "Installing Git..."
yum -y install git

echo "Installing MongoDB repositories..."
printf "[mongodb]\n" > /etc/yum.repos.d/mongodb.repo
printf "name=MongoDB Repository\n" >> /etc/yum.repos.d/mongodb.repo
printf "baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/\n" >> /etc/yum.repos.d/mongodb.repo
printf "gpgcheck=0\n" >> /etc/yum.repos.d/mongodb.repo
printf "enabled=1" >> /etc/yum.repos.d/mongodb.repo
yum -y update
echo "Installing MongoDB..."
yum -y install mongodb-org mongodb-org-server

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
printf "port = $YN_MONGO_PORT\n" > "$YN_BASEPATH/mongodb.conf"
printf "auth = true\n" >> "$YN_BASEPATH/mongodb.conf"
printf "dbpath = \"$YN_BASEPATH/db\"\n" >> "$YN_BASEPATH/mongodb.conf"
printf "logpath = \"$YN_BASEPATH/logs/mongodb.log\"\n" >> "$YN_BASEPATH/mongodb.conf"

echo "Creating MongoDB service file for YourNode (yn-mongod)..."
printf "[Unit]\n" > /etc/systemd/system/yn-mongod.service
printf "Description=MongoDB Service for YourNode\n" >> /etc/systemd/system/yn-mongod.service
printf "After=network.target\n\n" >> /etc/systemd/system/yn-mongod.service
printf "[Service]\n" >> /etc/systemd/system/yn-mongod.service
printf "User=$YN_USER\n" >> /etc/systemd/system/yn-mongod.service
printf "ExecStart=/usr/bin/mongod --quiet --config \"$YN_BASEPATH/mongodb.conf\"\n\n" >> /etc/systemd/system/yn-mongod.service
printf "[Install]\n" >> /etc/systemd/system/yn-mongod.service
printf "WantedBy=multi-user.target\n" >> /etc/systemd/system/yn-mongod.service

echo "Reloading system services..."
systemctl daemon-reload
echo "Enabling yn-mongod on system start..."
systemctl enable yn-mongod
echo "Starting yn-mongod..."
systemctl start yn-mongod

echo "Creating MongoDB admin user..."
mongo 127.0.0.1:$YN_MONGO_PORT/admin --eval "db.createUser({user: \"ynmdbAdmin\", pwd: \"$YN_MONGO_ADMIN_PASS\", roles: [{role: \"userAdminAnyDatabase\", db: \"admin\"}]})"
echo "Creating MongoDB user for YNDATA database..."
mongo 127.0.0.1:$YN_MONGO_PORT/YNDATA -u ynmdbAdmin -p $YN_MONGO_ADMIN_PASS --authenticationDatabase admin --eval "db.createUser({user: \"$YN_MONGO_USER\", pwd: \"$YN_MONGO_PASS\", roles: [{role: \"readWrite\", db: \"YNDATA\"}]})"

echo "Cloning YourNode Default Pages..."
git clone "$YN_DEFAULTS_REPOSITORY" "$YN_BASEPATH/lib/defaultpages"
git --git-dir="$YN_BASEPATH/lib/defaultpages/.git" --work-tree="$YN_BASEPATH/lib/defaultpages" checkout $YN_DEFAULTS_BRANCH

echo "Enabling default pages on SELinux to be served..."
chcon -Rt httpd_sys_content_t "$YN_BASEPATH/lib/defaultpages"

echo "Configuring nginx..."
sed -c -i "s/.*\(http {\).*/\http {\n    # YourNode\n    include $YN_BASEPATH\/proxy\/apps-enabled\/\*.conf\n/" /etc/nginx/nginx.conf
echo "Enabling nginx on system start"
systemctl enable nginx
echo "Starting nginx..."
systemctl start nginx

echo "Creating group $YN_GROUP..."
groupadd "$YN_GROUP"
echo "Creating user $YN_USER..."
useradd -g $YN_GROUP $YN_USER

echo "Cloning YourNode Automation Scripts..."
git clone "$YN_AUTOMATION_REPOSITORY" "$YN_BASEPATH/lib/automation"
git --git-dir="$YN_BASEPATH/lib/automation/.git" --work-tree="$YN_BASEPATH/lib/automation" checkout $YN_AUTOMATION_BRANCH

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
