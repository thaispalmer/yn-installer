#!/bin/bash

YN_USER="yournode"
YN_GROUP="yournode"
YN_BASEPATH="/var/yournode"
YN_MONGOPORT="35642"

YN_REPOSITORY="git@bitbucket.org:yournode/yn-automation.git"

mkdir -p "$YN_BASEPATH"
mkdir -p "$YN_BASEPATH/db"
mkdir -p "$YN_BASEPATH/logs"
mkdir -p "$YN_BASEPATH/proxy/apps-available"
mkdir -p "$YN_BASEPATH/proxy/apps-enabled"
mkdir -p "$YN_BASEPATH/keys"
mkdir -p "$YN_BASEPATH/lib"
mkdir -p "$YN_BASEPATH/bin"

printf "port = $YN_MONGOPORT\n" > "$YN_BASEPATH/mongodb.conf"
printf "auth = true\n" >> "$YN_BASEPATH/mongodb.conf"
printf "dbpath = \"$YN_BASEPATH/db\"\n" >> "$YN_BASEPATH/mongodb.conf"
printf "logpath = \"$YN_BASEPATH/logs/mongodb.log\"\n" >> "$YN_BASEPATH/mongodb.conf"

chown -R "$YN_USER:$YN_GROUP" "$YN_BASEPATH"

git clone "$YN_REPOSITORY" "$YN_BASEPATH/lib"
ln -s "$YN_BASEPATH/lib/master/yn-master.js" "$YN_BASEPATH/bin/yn-master.js"
ln -s "$YN_BASEPATH/lib/master/yournode-master.conf" "$YN_BASEPATH/bin/yournode-master.conf"