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
            echo -e "[${Yellow}!${NC}] ${Yellow}${description}${NC}"
        ;;
        "info")
            echo -e "[${LightCyan}*${NC}] ${LightCyan}${description}${NC}"
        ;;
    esac
}

# Define the release URL
release_url="https://github.com/carlospolop/PEASS-ng/releases"

# Get the latest release URL
print_msg "info" "Fetching the latest release URL..."
latest_release_url=$(curl -sSLI -o /dev/null -w %{url_effective} "$release_url/latest")

# Extract the latest release version from the URL
latest_release_version=$(basename "$latest_release_url")

# Check if linpeas.sh already exists
if [ -f "linpeas.sh" ]; then
    print_msg "warning" "linpeas.sh already exists. Removing..."
    rm linpeas.sh
fi

# Construct the URL for linpeas.sh
linpeas_url="$release_url/download/$latest_release_version/linpeas.sh"

# Download linpeas.sh using wget
print_msg "info" "Downloading the latest version of linpeas.sh..."
wget -q -O linpeas.sh "$linpeas_url"

# Check if download was successful
if [ $? -eq 0 ]; then
    print_msg "success" "linpeas.sh has been downloaded successfully."
    # chmod +x linpeas.sh # I don't want this runnable on my workstation.
    print_msg "info" "linpeas.sh has been made executable."
else
    print_msg "error" "Failed to download linpeas.sh."
fi
