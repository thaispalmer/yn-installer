#!/bin/bash

YN_USER="yournode"
YN_GROUP="yournode"
YN_BASEPATH="/var/yournode"
YN_REPOSITORY="git@bitbucket.org:yournode/yn-automation.git"

echo "__     __              _   _           _"
echo "\ \   / /             | \ | |         | |"
echo " \ \_/ /__  _   _ _ __|  \| | ___   __| | ___"
echo "  \   / _ \| | | | '__| . \` |/ _ \ / _\` |/ _ \\"
echo "   | | (_) | |_| | |  | |\  | (_) | (_| |  __/"
echo "   |_|\___/ \__,_|_|  |_| \_|\___(_)__,_|\___|"
echo ""
echo "          Shard Server Installation"
echo ""

echo "Installing dependencies..."
echo "Installing Extra Packages for Enterprise Linux (EPEL) repositories."
yum --y install epel-release
echo "Installing Node.js and NPM..."
yum --y install nodejs npm
echo "Installing Git..."
yum --y install git

echo "Creating folder structure..."
mkdir -p "$YN_BASEPATH"
mkdir -p "$YN_BASEPATH/logs"
mkdir -p "$YN_BASEPATH/keys"
mkdir -p "$YN_BASEPATH/lib"
mkdir -p "$YN_BASEPATH/bin"

echo "Clone YourNode Automation Scripts..."
git clone "$YN_REPOSITORY" "$YN_BASEPATH/lib"

echo "Installing YourNode Shard Automation..."
ln -s "$YN_BASEPATH/lib/shard/yn-shard.js" "$YN_BASEPATH/bin/yn-shard"
ln -s "$YN_BASEPATH/lib/shard/yournode-shard.conf" "$YN_BASEPATH/bin/yournode-shard.conf"
export PATH=$PATH:$YN_BASEPATH/bin

echo "Changing folder and files owners..."
chown -R "$YN_USER:$YN_GROUP" "$YN_BASEPATH"

echo "YourNode Shard - Installation sucessful."
