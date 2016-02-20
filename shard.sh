#!/bin/bash

YN_USER="yournode"
YN_GROUP="yournode"
YN_BASEPATH="/var/yournode"
YN_APPLICATIONPATH="/home/yournode"
YN_AUTOMATION_REPOSITORY="git@bitbucket.org:yournode/yn-automation.git"
YN_HELLOWORLD_REPOSITORY="git@bitbucket.org:yournode/yn-helloworld.git"

echo "__     __              _   _           _"
echo "\ \   / /             | \ | |         | |"
echo " \ \_/ /__  _   _ _ __|  \| | ___   __| | ___"
echo "  \   / _ \| | | | '__| . \` |/ _ \ / _\` |/ _ \\"
echo "   | | (_) | |_| | |  | |\  | (_) | (_| |  __/"
echo "   |_|\___/ \__,_|_|  |_| \_|\___(_)__,_|\___|"
echo ""
echo "          Shard Server Installation"
echo ""

read -r -p "Do you want to install YourNode Shard on this server? [y/N] " RESPONSE
if [[ $RESPONSE =~ ^([yY])$ ]]
then
    echo ""
else
    exit
fi

echo "Installing dependencies..."
echo "Installing Extra Packages for Enterprise Linux (EPEL) repositories..."
yum -y install epel-release
echo "Installing Node.js and NPM..."
yum -y install nodejs npm
echo "Installing Git..."
yum -y install git

echo "Creating folder structure..."
mkdir -p "$YN_BASEPATH"
mkdir -p "$YN_BASEPATH/logs"
mkdir -p "$YN_BASEPATH/keys"
mkdir -p "$YN_BASEPATH/lib"
mkdir -p "$YN_BASEPATH/bin"

echo "Creating group $YN_GROUP..."
groupadd "$YN_GROUP"
echo "Creating user $YN_USER..."
useradd -d "$YN_APPLICATIONPATH" -g $YN_GROUP $YN_USER

echo "Clone YourNode Automation Scripts..."
git clone "$YN_AUTOMATION_REPOSITORY" "$YN_BASEPATH/lib/automation"

echo "Installing YourNode Shard Automation..."
ln -s "$YN_BASEPATH/lib/automation/shard/yn-shard.js" "$YN_BASEPATH/bin/yn-shard"
ln -s "$YN_BASEPATH/lib/automation/shard/yournode-shard.conf" "$YN_BASEPATH/bin/yournode-shard.conf"
export PATH=$PATH:$YN_BASEPATH/bin

echo "Clone YourNode Hello World App..."
git clone "$YN_HELLOWORLD_REPOSITORY" "$YN_BASEPATH/lib/helloworld"

echo "Changing folder and files owners..."
chown -R "$YN_USER:$YN_GROUP" "$YN_BASEPATH"

echo "YourNode Shard - Installation sucessful."
