#! /bin/bash
# author:	Josef Kelly
# date:		January 3 2012
# license:	MIT

VERSION=2.3

# reference to path where this script is being run
THIS_PATH="`dirname \"$0\"`"

bar_width=50

# billing directories
BD="/mnt/billing"
PD="/mnt/billing_401k"

CLIENTS="/mnt/clients"
FLEX="/mnt/flex"

# pdf names
STATEMENT="Statement.pdf"
INVOICE="Invoice.pdf"
TRUST="Trust.pdf"
COMBINE="Combine.pdf"

# config files
PD_SORT_CONFIG="config/401kSortMap.txt"
BD_SORT_CONFIG="config/flexSortMap.txt"

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
QMTRUSTS="${INVOICES}/trust"
CREDITMEMOS="Credit_memo"

FINAL="Final"
FILECOPY="File_copy"
QMFINAL="QM_Final"
QMFILECOPY="QM_File_copy"

DETAIL="Detail"
COVERPAGE="Coverpage"
LIMITED="Limited"
DEBITCARD="Debitcard"

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

warning_prompt() {
    echo -e $RED
    echo -e "${BOLD_ON}${1}${BOLD_OFF}"
    tput sgr0
}

menu () {
    menu_prompt "Main menu"

    select word in "401(k) Billing" "Sort 401(k)" "Edit 401(k) Sort Map" "QM Billing" "Sort QM" "Copy QM Final to Final" "Combine QM Excel" "Flex Billing" "Sort Flex" "Edit Flex Sort Map" "Help" "Exit Billing Application" "Reboot VM" "Shutdown VM"
    do
        break
    done
    
    if [ "$word" = "401(k) Billing" ]; then
        pdc_billing
    fi
    
    if [ "$word" = "QM Billing" ]; then
        qm_billing
    fi
    
    if [ "$word" = "Flex Billing" ]; then
        bd_billing
    fi
    
    if [ "$word" = "Edit 401(k) Sort Map" ]; then
        edit_file ${PD}/${PD_SORT_CONFIG}
    fi
    
    if [ "$word" = "Edit Flex Sort Map" ]; then
        edit_file ${BD}/${BD_SORT_CONFIG}
    fi
    
    if [ "$word" = "Sort 401(k)" ]; then
        sort_files ${PD} ${PD_SORT_CONFIG} ${CLIENTS}
    fi
    
    if [ "$word" = "Sort Flex" ]; then
        sort_files ${BD} ${BD_SORT_CONFIG} ${FLEX}
    fi
    
    if [ "$word" = "Help" ]; then
        help_menu
    fi
    
    if [ "$word" = "Combine QM Excel" ]; then
        echo -e $GREEN
        echo -e "${BOLD_ON}Combination Utility${BOLD_OFF}"
        echo -ne ${BLUE}
        echo "Combining all files from ${EXCEL} to ${COMBINE}"
        tput sgr0
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${PD}/${COMBINE} ${PD}/${EXCEL}/*.pdf
    fi
    
    if [ "$word" = "Copy QM Final to Final" ]; then
        warning_prompt "Make sure you remove all pdfs in the Final folder."
        read -p "Do you want to proceed [y/n]? "
        
        if [ $REPLY = "y" ]; then
            cp ${PD}/${QMFINAL}/*.pdf ${PD}/${FINAL}
        fi
    fi
    
    if [ "$word" = "Sort QM" ]; then
        warning_prompt "Copying QM File Copy pdfs to the file copy folder will remove any existing files in the file folder."
        read -p "Do you want to proceed [y/n]? "
        
        if [ $REPLY = "y" ]; then
            rm ${PD}/${FINAL}/*.pdf
            cp ${PD}/${QMFILECOPY}/*.pdf ${PD}/${FILECOPY}
            sort_files ${PD} ${PD_SORT_CONFIG} ${CLIENTS}
        fi
    fi
    
    if [ "$word" = "Exit Billing Application" ]; then
        exit 0
    fi
    
    if [ "$word" = "Reboot VM" ]; then
        warning_prompt "THIS WILL REBOOT THE VIRTUAL MACHINE."
        read -p "Do you want to proceed [y/n]? "
        
        if [ $REPLY = "y" ]; then
            sudo reboot
        fi
    fi
    
    if [ "$word" = "Shutdown VM" ]; then
        warning_prompt "THIS WILL SHUTDOWN THE VIRTUAL MACHINE."
        read -p "Do you want to proceed [y/n]? "
        
        if [ $REPLY = "y" ]; then
            sudo shutdown -h now
        fi
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

#args 1: location
#args 2: map
#args 3: destination
sort_files () {
    echo -e $GREEN
    echo -e "${BOLD_ON}Sorting utility${BOLD_OFF}"
    
    if [ ! -e "${1}/${2}" ]; then
        echo -ne ${RED}
        echo -e "\n${BOLD_ON}File not found:${BOLD_OFF} ${2}"
        echo -ne ${BLUE}
        echo "Did the file get renamed, moved or deleted?"
        tput sgr0
        menu
    fi
    
    if [ ! -d "${3}" ]; then
        echo -ne ${RED}
        echo -e "\n${BOLD_ON}Directory not found:${BOLD_OFF} ${3}"
        echo -ne ${BLUE}
        echo "This means the billing application could not find the server."
        tput sgr0
        menubd_billing
    fi
    
    echo -ne $BLUE
    echo -e "Type request and press enter.\n"
    tput sgr0

    read -p "Year (e.g. 2011): "
    local year=$REPLY
    
    read -p "Date (e.g. 12-31-11): "
    local filename=$REPLY
    
    local amount=`ls -l ${1}/${FILECOPY} | wc -l`
    count=1
    
    declare -a keys
    
    draw_progressbar ${count} ${amount}

    while read line
    do
	    key=`echo $line | sed -e 's/ /_/g'`
	    keys=( ${keys[@]-} $(echo "$key") )
    done < ${1}/${2}

    shopt -s nullglob
    find ${1}/${FILECOPY}/*.pdf -print0 | while read -d $'\0' f
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
		    if [ -d "${3}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}" ]; then
			    #make sure year directory exists, if not, create it
			    if [ ! -d "${3}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}" ]; then
				    echo "Creating directory ${year} for ${f##*/}" >> ${1}/sort.log.txt
				    #mkdir "${3}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}"
			    fi

			    #only move the file if it doesn't exist in destination directory
			    if [ ! -e "${3}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}/${filename}.pdf" ]; then
				    echo "Moving ${f##*/} to ${clientDirectory}/${planDirectory}/${specialDirectory}/Billing/${year}" >> ${1}/sort.log.txt
				    #mv "${f}" "${3}/${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}/${filename}.pdf"
			    else
				    echo "${clientDirectory}/${planDirectory}/Billing/${specialDirectory}/${year}/${filename}.pdf already exists" >> ${1}/sort.log.txt
			    fi
		    else
			    echo "Could not find directory for ${f##*/}" >> ${1}/sort.log.txt
		    fi
	    else
		    echo "Could not find map for ${f##*/}" >> ${1}/sort.log.txt
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
    
    if [ -e "${2}/${QMTRUSTS}/${fileName}" ]; then
	    local render_qmtrust=`echo ${2}/${QMTRUSTS}/${fileName}`
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
        #if excel exists do not include invoice
        if [ -e "${2}/${EXCEL}/${fileName}" ]; then
	        local render_invoice=`echo ""`
        fi
        
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
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_attachment} ${render_invoice} ${render_qmtrust} ${render_credit} ${render_source}
    fi
    
    if [ "${3}" = "${QMFINAL}" ]; then
        echo "${fileName}" >> ${PD}/final_qm.log.txt
        # render file copy
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_attachment} ${render_statement}
    fi
}

build_flex_pdf () {
    local fileName=$(echo ${1##*/})
		    
    #for determining terminated files
    local fileNameStripped=`echo ${fileName} | cut -f1-2 -d.`
    local isTerm="${fileNameStripped}.TERM"
    
    if [ -e "${2}/${DETAIL}/${isTerm}" ]; then
	    echo "${fileNameStripped} TERMINATED" >> ${2}/final_flex.log.txt
	    echo "${fileNameStripped} TERMINATED" >> ${2}/file_copy_flex.log.txt
    else
        if [ -e "${2}/${INVOICES}/${fileName}" ]; then
		    local render_invoice=`echo ${2}/${INVOICES}/${fileName}`
	    fi
	    
	    if [ -e "${2}/${STATEMENTS}/${fileName}" ]; then
		    local render_statement=`echo ${2}/${STATEMENTS}/${fileName}`
	    fi

	    if [ -e "${2}/${DETAIL}/${fileName}" ]; then
		    local render_detail=`echo ${2}/${DETAIL}/${fileName}`
	    fi

	    if [ -e "${2}/${COVERPAGE}/${fileName}" ]; then
		    local render_coverpage=`echo ${2}/${COVERPAGE}/${fileName}`
	    fi

	    if [ -e "${2}/${DEBITCARD}/${fileName}" ]; then
		    local render_debitcard=`echo ${2}/${DEBITCARD}/${fileName}`
	    fi

	    if [ -e "${2}/${LIMITED}/${fileName}" ]; then
		    local render_limited=`echo ${2}/${LIMITED}/${fileName}`
	    fi
	
	    if [ -e "${2}/${CREDITMEMOS}/${fileName}" ]; then
		    local render_creditmemo=`echo ${2}/${CREDITMEMOS}/${fileName}`
	    fi
	
	    if [ -e "${2}/${MISC}/${fileName}" ]; then
		    local render_misc=`echo ${2}/${MISC}/${fileName}`
	    fi

	    echo "${fileName}" >> ${2}/final_flex.log.txt
	    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${FINAL}/${fileName} ${render_invoice} ${render_coverpage} ${render_detail} ${render_limited} ${render_debitcard} ${render_statement}
	    echo "${fileName}" >> ${2}/file_copy_flex.log.txt
	    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${FILECOPY}/${fileName} ${render_invoice} ${render_coverpage} ${render_detail} ${render_limited} ${render_debitcard} ${render_creditmemo} ${render_misc}
    fi
}

bd_billing () {
    split_flex_pdf "${BD}/${STATEMENT}" "${BD}/${STATEMENTS}"
    split_flex_pdf "${BD}/${INVOICE}" "${BD}/${INVOICES}"

    shopt -s nullglob
    
    amount=`ls -l ${BD}/${INVOICES} | wc -l`
    let amount=${amount}-1
    count=1
    
    echo -e "\nBuilding File copy & Final from ${INVOICES}"
    
    for f in ${BD}/${INVOICES}/*.pdf
    do
	    draw_progressbar ${count} ${amount}
	    build_flex_pdf ${f} ${BD}
	    let count=${count}+1
    done

    echo -e "\n\nFinished Flex Billing"
}

# arguments are exactly the same as splitFlexPDF.sh
split_flex_pdf () {
    if [ -e "${1}.info.txt" ]; then
        created=`grep "CreationDate" "${1}.info.txt"`
        
        echo -e "\n${1##*/} [ ${created:16} ] was already processed."
        read -p "Do you want to process ${1##*/} again [y/n] ? "
        
        if [ $REPLY = "y" ]; then
            ${THIS_PATH}/splitFlexPDF.sh ${1} ${2}
        fi
    else
        ${THIS_PATH}/splitFlexPDF.sh ${1} ${2}
    fi
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
    for d in "${PD}" "${BD}" "${PD}/${EXCEL}" "${PD}/${ATTACHMENTS}" "${PD}/${DIST}" "${PD}/${MISC}" "${PD}/${SOURCE}" "${PD}/${CREDITMEMOS}" "${BD}/${DETAIL}" "${BD}/${LIMITED}" "${BD}/${DEBITCARD}" "${BD}/${MISC}" "${BD}/${CREDITMEMOS}" "${BD}/${COVERPAGE}"
    do
        if [ ! -d "${d}" ]; then
            echo -ne ${RED}
            echo -e "\n${BOLD_ON}Directory not found:${BOLD_OFF} ${d}"
            echo -ne ${BLUE}
            echo "Did the directory get renamed, moved or deleted?"
            tput sgr0
        fi
    done
    
    for d in "${PD}/${FINAL}" "${PD}/${FILECOPY}" "${PD}/${QMFINAL}" "${PD}/${QMFILECOPY}" "${BD}/${FINAL}" "${BD}/${FILECOPY}"
    do
        if [ ! -d "${d}" ]; then
	        mkdir "${d}"
        fi
    done
}

check_directories
menu
