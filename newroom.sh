#!/bin/bash

Black='\033[0;30m'
DarkGray='\033[1;30m'
Red='\033[0;31m'
LightRed='\033[1;31m'
Green='\033[0;32m'
LightGreen='\033[1;32m'
Brown='\033[0;33m'
Yellow='\033[1;33m'
Blue='\033[0;34m'
LightBlue='\033[1;34m'
Purple='\033[0;35m'
LightPurple='\033[1;35m'
Cyan='\033[0;36m'
LightCyan='\033[1;36m'
LightGray='\033[0;37m'
White='\033[1;37m'
NC='\033[0m' # No Color

function setStatus(){

    description=$1
    severity=$2

    case "$severity" in
        s)
            echo -e "[${LightGreen}+${NC}] ${LightGreen}${description}${NC}"
        ;;
        f)
            echo -e "[${Red}-${NC}] ${LightRed}${description}${NC}"
        ;;
        q)
            echo -e "[${LightPurple}?${NC}] ${LightPurple}${description}${NC}"
        ;;
        *)
            echo -e "[${LightCyan}*${NC}] ${LightCyan}${description}${NC}"
        ;;
    esac
}

newDir=~/gitlocal/r0bsec/thm-writeups/${1}/

setStatus "Creating new directory: $newDir" "*"

mkdir $newDir

setStatus "Creating symbolic '~/current/' link to new directory: $newDir" "*"

rm -Rf ~/current
ln -f -s $newDir ~/current

setStatus "Copying template notes to new directory: ${newDir}index.md" "*"

cp ${newDir}../_Template.md ~/current/index.md

setStatus "Copying helper scripts (kickoff.sh, killbyname.sh) to new directory ${newDir}" "*"

cp ${newDir}../kickoff.sh ~/current/
cp ${newDir}../killbyname.sh ~/current/
chmod +x ${newDir}../*.sh

setStatus "Switching to new directory ${newDir} via '~/current/'..." "*"

cd ~/current

newDir=''
