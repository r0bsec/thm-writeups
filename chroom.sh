#!/bin/bash

newDir=~/gitlocal/r0bsec/thm-writeups/${1}/

echo "[+] Creating symbolic 'current' link to new directory: ${newDir}"

rm -Rf ~/current
ln -f -s $newDir ~/current

echo "[+] Switching to new directory: ${newDir}"

cd ~/current

newDir=''
