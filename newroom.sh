#!/bin/bash

newDir=`pwd`/${1}/

echo "[+] Creating new directory: $newDir"

mkdir $newDir

echo "[+] Creating symbolic 'current' link to new directory: ${newDir}"

cd ~
rm -Rf ~/current
ln -f -s $newDir ~/current
cd -

echo "[+] Copying template notes to new directory: ${newDir}"

cp ./_Template.md ~/current/index.md

echo "[+] Switching to new directory: ${newDir}"

cd ~/current

newDir=''
