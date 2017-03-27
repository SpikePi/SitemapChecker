#!/bin/bash

# clear screen to see exciting stuff happen
clear

function checkTools {
    distribution=$(lsb_release -is)

    if [ $? -eq 0 ]; then
        echo "Cant't identify your Linux Distribution because lsb_release is not installed"
        read -p "Press any key to exit ... " -n 1
        exit 1
    fi

    case $distribution in
        Debian | LinuxMint | Ubuntu )
            sudo apt-get update; sudo apt-get install curl libxml2-utils wget coreutils sed grep
        Fedora )
            sudo dnf install curl libxml2 wget coreutils sed grep;;
        * )
            echo "Your Linux Distribution is not yet supported"
            echo "Please manually install the following tools: curl sed grep coreutils"
            read -p "Press any key to exit ... " -n 1
            exit 1
    esac
}
