#!/bin/bash

YN_USER="yournode"
YN_GROUP="yournode"
YN_BASEPATH="/var/yournode"

YN_REPOSITORY="git@bitbucket.org:yournode/yn-automation.git"

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
