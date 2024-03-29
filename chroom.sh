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
if [ $# -eq 0 ]; then
    echo "Change to an existing THM room write-up directory."
    echo ""
    echo "  Usage: $0 <room_name>"
    exit 1
fi

ROOM_PATH=`pwd`/${1}/

if [ -d "$ROOM_PATH" ]; then
    export_statement="export ROOM=${ROOM_PATH}"
    zshrc_file=~/.zshrc

    sed -i '/^export ROOM=/d' $zshrc_file
    echo "$export_statement" >> $zshrc_file
    print_msg success "ROOM export statement added to: $zshrc_file"

    print_msg success "ROOM environment variable changed to $1"

    echo ""
    print_msg info "Please run the following command to reload your environment:"
    echo ""
    echo "  source ${zshrc_file}"

else
    print_msg error "The room '$1' does not exist"
fi
