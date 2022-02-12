#!/bin/bash

if [[ $1 == "" ]];
then
    echo "USAGE: $0 [processname]"
    exit -2
fi


kill $(sudo ps -A | grep $1 | cut -d " " -f 1)
