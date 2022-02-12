#!/bin/bash

if [[ $1 == "" ]];
then
    echo "USAGE: $0 x.x.x.x"
    echo "Missing argument. Where x.x.x.x is the ip address of the server."
    exit -2
fi

echo "[+] Starting nmap..." && echo -e "Starting enn map" | espeak
nmap $1 &> ./nmap.log &

echo "[+] Starting gobuster..." && echo -e "Starting go buster" | espeak
gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -u http://$1 > ./gobuster.log 2> /dev/null &

echo "[+] Starting nikto..." && echo -e "Starting nick tow" | espeak
nikto -h $1 &> ./nikto.log &

