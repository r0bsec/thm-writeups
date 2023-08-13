#!/bin/zsh

# Define color codes for messages
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

function print_msg(){

    description=$2
    severity=$1

    case "$severity" in
        "success")
            echo -e "[${LightGreen}+${NC}] ${LightGreen}${description}${NC}"
        ;;
        "error")
            echo -e "[${Red}-${NC}] ${LightRed}${description}${NC}"
        ;;
        "warning")
            echo -e "[${Yellow}?${NC}] ${Yellow}${description}${NC}"
        ;;
        "info")
            echo -e "[${LightCyan}*${NC}] ${LightCyan}${description}${NC}"
        ;;
    esac
}

# Check for arguments
if [[ $1 == "" ]];
then
    echo "Start nmap, gobuster, and nikto in background tasks."
    echo ""
    echo "  Usage: $0 <IPAddress>"
    exit -2
else
    HOST=$1
fi

# Define an array of program names and corresponding commands
declare -A tasks
tasks["nmap"]="nmap -sCV ${HOST} | tee ${ROOM}/nmap.log &"
tasks["gobuster"]="gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://${HOST} 2> /dev/null | tee ${ROOM}/gobuster.log &"
tasks["nikto"]="nikto -h ${HOST} 2>&1 | tee ${ROOM}/nikto.log &"

# Loop through the array and launch tasks
for program in "${(k)tasks[@]}"; do
    print_msg info "Starting $program..." && echo -e "Starting $program" | espeak
    echo "    - Executing: ${tasks[$program]}"
    eval ${tasks[$program]}
    sleep .5 # Add a short sleep between tasks
done

print_msg info "Waiting for tasks to complete..." && echo -e "Waiting for tasks to complete" | espeak
# Wait for all processes to complete
wait

# Notify completion
print_msg success "All tasks completed."

# Notify using espeak
echo -e "All tasks completed." | espeak
