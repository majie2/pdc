#! /bin/bash
# author:	Josef Kelly
# date:		January 3 2012
# license:	MIT

VERSION=1.1

# reference to path where this script is being run
THIS_PATH="`dirname \"$0\"`"
USER=$(whoami)
USER_PATH="/home/${USER}"
LOGFILE="${USER_PATH}/create.sh.log"

bar_width=50
SHARE_DIR="/mnt"

# system variables
BOLD_ON="\033[1m"
BOLD_OFF="\033[0m"
RED='\E[31;47m'
BLUE='\E[36;40m'
GREEN='\E[32;40m'

rm ${LOGFILE}
touch ${LOGFILE}

clear

echo -e "\n##################################################"
echo "#                                                #"
echo "# create.sh                                      #"
echo "#                                                #"
echo "# author  : josef kelly                          #"
echo "# license : mit                                  #"
echo "# version : ${VERSION}                                  #"
echo "#                                                #"
echo "##################################################"

menu_prompt () {
    echo -ne $GREEN
    echo -e "\n${BOLD_ON}${1}${BOLD_OFF}"
    echo -ne $BLUE
    echo -e "Type the number of your selection and press enter\n"
    tput sgr0
}

menu () {
    menu_prompt "Main menu"

    select word in "Create Folders" "View Log" "Exit"
    do
        break
    done
    
    if [ "$word" = "Create Folders" ]; then
        create_folders
    fi
    
    if [ "$word" = "View Log" ]; then
        nano ${LOGFILE}
    fi
    
    if [ "$word" = "Exit" ]; then
        exit 0
    fi
    
    menu
}

create_folders () {
    echo -ne $BLUE
    echo -e "Type request and press enter.\n"
    tput sgr0
    
    echo -e "Directory structure is ${BOLD_ON}share/ALL_FOLDERS/folder/path/new_folder${BOLD_OFF}\n"
    
    echo "The following shares are available"
    ls ${SHARE_DIR}
    
    echo -e "\nInput the share we are searching within"
    read -p "Share: "
    local f_main=$REPLY
    
    read -p "In folder path: "
    local f_path=$REPLY

    read -p "Create folder named: "
    local f_name=$REPLY
    
    local target_directories=$(find "${SHARE_DIR}/${f_main}" -maxdepth 1 -mindepth 1 -type d)
    local total=$(echo ${target_directories} | wc -w)
    local count=1
    
    for f in ${target_directories}
    do
        draw_progressbar $count $total
        if [ -d "${f}/${f_path}" ]
        then
            make_directory "${f}/${f_path}/${f_name}"
        else
            local additional_directories=$(find "${f}" -maxdepth 1 -mindepth 1 -type d)
            local verify=$(echo ${additional_directories} | wc -w)
            
            if [ ${verify} -lt 5 ]
            then
				for g in ${additional_directories}
				do
					if [ -d "${g}/${f_path}" ]
					then
						make_directory "${g}/${f_path}/${f_name}"
					else
						log_message "error: ${g}/${f_path}"
					fi
				done
            fi
        fi
        
        let count=$count+1
    done
}

# makes a directory
# arg 1 : path
make_directory () {
    if [ ! -d "${1}" ]
    then
        log_message "creating: ${1}"
        mkdir "${1}"
    else
        log_message "already exists: ${1}"
    fi
}

log_message () {
    echo "${1}" >> ${LOGFILE}
}

# draws a progress bar
# arg 1 : current size of bar
# arg 2 : final size of bar
draw_progressbar () {
    local part=$1
    local place=$((part*bar_width/$2))
    local i
    echo -ne "\r$((part*100/$2))% ["
 
    for i in $(seq 1 $bar_width); do
        [ "$i" -le "$place" ] && echo -n "#" || echo -n " ";
    done
    echo -n "]"
}

menu
