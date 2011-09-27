#! /bin/bash
# author:	Josef Kelly
# date:		February 11 2011
# license:	MIT

VERSION=2.0

# reference to path where this script is being run
THIS_PATH="`dirname \"$0\"`"

bar_width=50

# billing directories
BD="/mnt/billing"
PD="/mnt/billing_401k"

#PD="/home/josef/documents/billing_pdc"
CLIENTS="/mnt/clients"

# pdf names
STATEMENT="Statement.pdf"
INVOICE="Invoice.pdf"
TRUST="Trust.pdf"

# config files
PD_SORT_CONFIG="config/401kSortMap.txt"

# specific directories
INVOICES="Invoices"
STATEMENTS="Statements"
EXCEL="Excel"
ATTACHMENTS="Attachment"
DIST="Dist"
MISC="Misc"
SOURCE="Source"
DUMMY="${INVOICES}/dummy"
TRUSTS="trust"
CREDITMEMOS="Credit_memo"
FINAL="Final"
FILECOPY="File_copy"
QMFINAL="QM_Final"
QMFILECOPY="QM_File_copy"

# system variables
BOLD_ON="\033[1m"
BOLD_OFF="\033[0m"
RED='\E[31;47m'
BLUE='\E[36;40m'
GREEN='\E[32;40m'

clear

echo -e "\n##################################################"
echo "#                                                #"
echo "# billing.sh                                     #"
echo "#                                                #"
echo "# author  : josef kelly                          #"
echo "# license : mit                                  #"
echo "# version : 2.0                                  #"
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

    select word in "401(k) Billing" "QM Billing" "Sort 401(k)" "Copy QM Final to Final" "Edit 401(k) Sort Map" "Help" "Exit"
    do
        break
    done
    
    if [ "$word" = "401(k) Billing" ]; then
        pdc_billing
    fi
    
    if [ "$word" = "QM Billing" ]; then
        qm_billing
    fi
    
    if [ "$word" = "Flexible Benefits Billing" ]; then
        bd_billing
    fi
    
    if [ "$word" = "Edit 401(k) Sort Map" ]; then
        edit_file ${PD}/${PD_SORT_CONFIG}
    fi
    
    if [ "$word" = "Sort 401(k)" ]; then
        sort_pd ${PD}/${PD_SORT_CONFIG}
    fi
    
    if [ "$word" = "Help" ]; then
        help_menu
    fi
    
    if [ "$word" = "Copy QM Final to Final" ]; then
        echo -e $RED
        echo -e "${BOLD_ON}Copying QM final pdfs to the final folder will remove any existing files in the final folder.${BOLD_OFF}"
        tput sgr0
        read -p "Do you want to proceed [y/n]? "
        
        if [ $REPLY = "y" ]; then
            rm ${PD}/${FINAL}/*.pdf
            cp ${PD}/${QMFINAL}/*.pdf ${PD}/${FINAL}
        fi
    fi
    
    if [ "$word" = "Exit" ]; then
        exit 0
    fi
    
    menu
}

help_menu () {
    menu_prompt "Help menu"
    
    select word in "Colors" "Editing Files" "Back to Main menu"
    do
        break
    done
    
    if [ "$word" = "Colors" ]; then
        echo -e $GREEN
        echo -e "${BOLD_ON}This is a menu title${BOLD_OFF}"
        echo -e $RED
        echo -e "${BOLD_ON}This is an error message${BOLD_OFF}"
        echo -e $BLUE
        echo "This is an explaination message. I can offer help about an action or remind you to do something"
        tput sgr0
        help_menu
    fi
    
    if [ "$word" = "Editing Files" ]; then
        echo -e $BLUE
        echo -e "Selecting a menu option to edit a file will automatically open the file with nano.\nTo save changes in nano, press ${BOLD_ON}CTRL-X${BOLD_OFF}${BLUE}, followed by ${BOLD_ON}Y${BOLD_OFF}${BLUE} and finally ${BOLD_ON}ENTER${BOLD_OFF}${BLUE}.\nTo exit nano without saving changes, press ${BOLD_ON}CTRL-X${BOLD_OFF}${BLUE}, followed by ${BOLD_ON}N${BLUE}."
        tput sgr0
        help_menu
    fi
}

edit_file () {
    if [ -e ${1} ]; then
        nano ${1}
    else
        echo -ne ${RED}
        echo -e "\n${BOLD_ON}File not found:${BOLD_OFF} ${1}"
        echo -ne ${BLUE}
        echo "Did the file get renamed, moved or deleted?"
        tput sgr0
    fi
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

#args 1: map
sort_pd () {
    echo -e $GREEN
    echo -e "${BOLD_ON}Sorting utility${BOLD_OFF}"
    
    if [ ! -e "${1}" ]; then
        echo -ne ${RED}
        echo -e "\n${BOLD_ON}File not found:${BOLD_OFF} ${1}"
        echo -ne ${BLUE}
        echo "Did the file get renamed, moved or deleted?"
        tput sgr0
        menu
    fi
    
    echo -ne $BLUE
    echo -e "Type request and press enter.\n"
    tput sgr0

    read -p "Year (e.g. 2011): "
    local year=$REPLY
    
    read -p "Date (e.g. 12-31-11): "
    local filename=$REPLY
    
    local amount=`ls -l ${PD}/${FILECOPY} | wc -l`
    count=1
    
    declare -a keys
    
    draw_progressbar ${count} ${amount}

    while read line
    do
	    key=`echo $line | sed -e 's/ /_/g'`
	    keys=( ${keys[@]-} $(echo "$key") )
    done < $1

    shopt -s nullglob
    find ${PD}/${FILECOPY}/*.pdf -print0 | while read -d $'\0' f
    do
        let count=${count}+1
        draw_progressbar ${count} ${amount}
        
	    clientName=`echo ${f##*/} | cut -f1-2 -d.`
	    clientMap=""
	    key=""

	    for i in ${keys[@]}
	    do
		    key=`echo $i | sed -e 's/_/ /g' | cut -f1 -d:`

		    if [ $key = $clientName ]; then
			    clientMap=`echo "$i" | sed -e 's/_/ /g'`
			    break
		    fi
	    done

	    #make sure clientName is not empty
	    if [ -n "${clientMap}" ]; then
		    #find directory name from mapping file
		    clientDirectory=`echo $clientMap | cut -f2 -d:`
		    planDirectory=`echo $clientMap | cut -f3 -d:`
		    specialDirectory=`echo $clientMap | cut -f4 -d:`

		    #make sure billing directory exists
		    if [ -d "${CLIENTS}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}" ]; then
			    #make sure year directory exists, if not, create it
			    if [ ! -d "${CLIENTS}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}" ]; then
				    echo "Creating directory ${year} for ${f##*/}" >> ${PD}/sort_pd.log.txt
				    mkdir "${CLIENTS}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}"
			    fi

			    #only move the file if it doesn't exist in destination directory
			    if [ ! -e "${CLIENTS}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}/${filename}.pdf" ]; then
				    echo "Moving ${f##*/} to ${clientDirectory}/${planDirectory}/${specialDirectory}/Billing/${year}" >> ${PD}/sort_pd.log.txt
				    mv "${f}" "${CLIENTS}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}/${filename}.pdf"
			    else
				    echo "${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}/${filename}.pdf already exists" >> ${PD}/sort_pd.log.txt
			    fi
		    else
			    echo "Could not find directory for ${f##*/}" >> ${PD}/sort_pd.log.txt
		    fi
	    else
		    echo "Could not find map for ${f##*/}" >> ${PD}/sort_pd.log.txt
	    fi
    done

    menu
}

# builds a pdf from the other pdf files specified
# arg 1 : filename (used for finding existing pdfs and naming built pdf)
# arg 2 : directory to find and place pdfs
# arg 3 : directory to place pdf (either final or file copy)
build_pdf () {
    local fileName=$(echo ${1##*/})
    
    if [ -e "${2}/${INVOICES}/${fileName}" ]; then
	    local render_invoice=`echo ${2}/${INVOICES}/${fileName}`
    fi
    
    if [ -e "${2}/${STATEMENTS}/${fileName}" ]; then
	    local render_statement=`echo ${2}/${STATEMENTS}/${fileName}`
    fi

    if [ -e "${2}/${EXCEL}/${fileName}" ]; then
	    local render_excel=`echo ${2}/${EXCEL}/${fileName}`
    fi

    if [ -e "${2}/${ATTACHMENTS}/${fileName}" ]; then
	    local render_attachment=`echo ${2}/${ATTACHMENTS}/${fileName}`
    fi
    
    if [ -e "${2}/${CREDITMEMOS}/${fileName}" ]; then
	    local render_credit=`echo ${2}/${CREDITMEMOS}/${fileName}`
    fi

    if [ -e "${2}/${TRUSTS}/${fileName}" ]; then
	    local render_trust=`echo ${2}/${TRUSTS}/${fileName}`
    fi
    
    if [ -e "${2}/${DIST}/${fileName}" ]; then
	    local render_dist=`echo ${2}/${DIST}/${fileName}`
    fi

    if [ -e "${2}/${MISC}/${fileName}" ]; then
	    local render_misc=`echo ${2}/${MISC}/${fileName}`
    fi
    
    if [ -e "${2}/${DUMMY}/${fileName}" ]; then
	    local render_dummy=`echo ${2}/${DUMMY}/${fileName}`
    fi
    
    if [ -e "${2}/${SOURCE}/${fileName}" ]; then
	    local render_source=`echo ${2}/${SOURCE}/${fileName}`
    fi
    
    if [ "${3}" = "${FINAL}" ]; then
        echo "${fileName}" >> ${PD}/final.log.txt
        # render final invoice, should work fine with excel based invoices since all dummy's are moved when split
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_invoice} ${render_attachment} ${render_statement}
    fi
    
    if [ "${3}" = "${FILECOPY}" ]; then
        echo "${fileName}" >> ${PD}/file_copy.log.txt
        # render file copy
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_invoice} ${render_dummy} ${render_credit} ${render_trust} ${render_attachment} ${render_dist} ${render_misc}
    fi
    
    if [ "${3}" = "${QMFILECOPY}" ]; then
        echo "${fileName}" >> ${PD}/file_copy_qm.log.txt
        # render file copy
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_invoice} ${render_trust} ${render_credit} ${render_attachment} ${render_source}
    fi
    
    if [ "${3}" = "${QMFINAL}" ]; then
        echo "${fileName}" >> ${PD}/final_qm.log.txt
        # render file copy
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_attachment} ${render_statement}
    fi
}

bd_billing () {
    echo "bd billing"
}

# arguments are exactly the same as splitPDF.sh
split_pdf () {
    if [ -e "${1}.info.txt" ]; then
        created=`grep "CreationDate" "${1}.info.txt"`
        
        echo -e "\n${1##*/} [ ${created:16} ] was already processed."
        read -p "Do you want to process ${1##*/} again [y/n] ? "
        
        if [ $REPLY = "y" ]; then
            ${THIS_PATH}/splitPDF.sh ${1} ${2} ${3} ${4}
        fi
    else
        ${THIS_PATH}/splitPDF.sh ${1} ${2} ${3} ${4}
    fi
}

qm_billing () {
    #split source pdfs
    split_pdf "${PD}/${STATEMENT}" "${PD}/${STATEMENTS}" 2
    split_pdf "${PD}/${INVOICE}" "${PD}/${INVOICES}" 2 trust
    
    menu_prompt "QM Billing"
    
    select word in "Final" "File Copy" "Both"
    do
        break
    done
    
    shopt -s nullglob
    
    amount=`ls -l ${PD}/${EXCEL} | wc -l`
    let amount=${amount}-1
    count=1
    
    echo -e "\nBuilding ${word} from ${EXCEL}"
    
    for f in ${PD}/${EXCEL}/*.pdf
    do
        draw_progressbar ${count} ${amount}
        
        if [ "$word" != "File Copy" ]; then
            build_pdf ${f} ${PD} ${QMFINAL}
        fi
        
        if [ "$word" != "Final" ]; then
            build_pdf ${f} ${PD} ${QMFILECOPY}
        fi
        
        let count=${count}+1
    done
    
    echo -e "\n\nFinished QM Billing"
}

pdc_billing () {
    # split source pdfs
    split_pdf "${PD}/${STATEMENT}" "${PD}/${STATEMENTS}" 2
    split_pdf "${PD}/${INVOICE}" "${PD}/${INVOICES}" 2 dummy 1
    split_pdf "${PD}/${TRUST}" "${PD}/${TRUSTS}" 2

    menu_prompt "401(k) Billing"
    
    select word in "Final" "File Copy" "Both"
    do
        break
    done
    
    shopt -s nullglob
    
    amount=`ls -l ${PD}/${INVOICES} | wc -l`
    let amount=${amount}-2
    count=1
    
    echo -e "\nBuilding ${word} from ${INVOICES}"
    
    for f in ${PD}/${INVOICES}/*.pdf
    do
        draw_progressbar ${count} ${amount}
        
        if [ "$word" != "File Copy" ]; then
            build_pdf ${f} ${PD} ${FINAL}
        fi
        
        if [ "$word" != "Final" ]; then
            build_pdf ${f} ${PD} ${FILECOPY}
        fi
        
        let count=${count}+1
    done
    
    if [ "$word" != "File Copy" ]; then
        amount=`ls -l ${PD}/${EXCEL} | wc -l`
        let amount=${amount}-1
        count=1
        
        echo -e "\n\nBuilding Final from ${EXCEL}"
        
        for f in ${PD}/${EXCEL}/*.pdf
	    do
	        draw_progressbar ${count} ${amount}
	        build_pdf ${f} ${PD} ${FINAL}
	        let count=${count}+1
        done
    fi
    
    if [ "$word" != "Final" ]; then
        amount=`ls -l ${PD}/${DUMMY} | wc -l`
        let amount=${amount}-1
        count=1
        
        echo -e "\n\nBuilding File Copy from ${DUMMY}"
        
        for f in ${PD}/${DUMMY}/*.pdf
	    do
	        draw_progressbar ${count} ${amount}
	        build_pdf ${f} ${PD} ${FILECOPY}
	        let count=${count}+1
        done
    fi
    
    echo -e "\n\nFinished 401(k) Billing"
}

check_directories () {
    for d in "${PD}/${EXCEL}" "${PD}/${ATTACHMENTS}" "${PD}/${DIST}" "${PD}/${MISC}" "${PD}/${SOURCE}" "${PD}/${CREDITMEMOS}"
    do
        if [ ! -d "${d}" ]; then
            echo -ne ${RED}
            echo -e "\n${BOLD_ON}Directory not found:${BOLD_OFF} ${d}"
            echo -ne ${BLUE}
            echo "Did the directory get renamed, moved or deleted?"
            tput sgr0
        fi
    done
    
    for d in "${PD}/${FINAL}" "${PD}/${FILECOPY}" "${PD}/${QMFINAL}" "${PD}/${QMFILECOPY}"
    do
        if [ ! -d "${d}" ]; then
	        mkdir "${d}"
        fi
    done
}

check_directories
menu
