#! /bin/bash
# author:	Josef Kelly
# date:		February 11 2011
# license:	MIT

VERSION=2.0

# reference to path where this script is being run
THIS_PATH="`dirname \"$0\"`"

bar_width=50

# billing directories
#BD="/mnt/billing"
#PD="/mnt/billing_401k"

PD="/home/josef/documents/billing_pdc"

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
    echo -e "\nmenu: ${1}\nType the number of your selection and press enter\n"
}

menu () {
    menu_prompt "Main"

    select word in "401(k) Billing" "QM 401(k) Billing" "Flexible Benefits Billing" "Sort 401(k)" "Sort Flexible Benefits" "Edit 401(k) Sort Map"
    do
        break
    done
    
    if [ "$word" = "401(k) Billing" ]; then
        pdc_billing
    fi
    
    if [ "$word" = "Flexible Benefits Billing" ]; then
        bd_billing
    fi
    
    if [ "$word" = "Edit 401(k) Sort Map" ]; then
        edit_file ${PD}/${PD_SORT_CONFIG}
    fi
}

edit_file () {
    if [ -e ${1} ]; then
        echo "Editing ${1}"
        nano ${1}
    else
        echo -e "File not found: ${1}\nPlease check"
    fi
    
    menu
}

# draws a progress bar
# arg 1 : current size of bar
# arg 2 : final size of bar
draw_progressbar() {
    local part=$1
    local place=$((part*bar_width/$2))
    local i
 
    echo -ne "\r$((part*100/$2))% ["
 
    for i in $(seq 1 $bar_width); do
        [ "$i" -le "$place" ] && echo -n "#" || echo -n " ";
    done
    echo -n "]"
}

# builds a pdf from the other pdf files specified
# arg 1 : filename (used for finding existing pdfs and naming built pdf)
# arg 2 : directory to find and place pdfs
# arg 3 : directory to place pdf (either final or file copy)
build_pdf () {
    local fileName=$(echo ${1##*/})
    
    if [ -e "${2}/${INVOICES}/${fileName}" ]; then
	    render_invoice=`echo ${2}/${INVOICES}/${fileName}`
    else
	    render_invoice=``
    fi
    
    if [ -e "${2}/${STATEMENTS}/${fileName}" ]; then
	    render_statement=`echo ${2}/${STATEMENTS}/${fileName}`
    else
	    render_statement=``
    fi

    if [ -e "${2}/${EXCEL}/${fileName}" ]; then
	    render_excel=`echo ${2}/${EXCEL}/${fileName}`
    else
	    render_excel=``
    fi

    if [ -e "${2}/${ATTACHMENTS}/${fileName}" ]; then
	    render_attachment=`echo ${2}/${ATTACHMENTS}/${fileName}`
    else
	    render_attachment=``
    fi
    
    if [ -e "${2}/${CREDITMEMOS}/${fileName}" ]; then
	    render_credit=`echo ${2}/${CREDITMEMOS}/${fileName}`
    else
	    render_credit=``
    fi

    if [ -e "${2}/${TRUSTS}/${fileName}" ]; then
	    render_trust=`echo ${2}/${TRUSTS}/${fileName}`
    else
	    render_trust=``
    fi
    
    if [ -e "${2}/${DIST}/${fileName}" ]; then
	    render_dist=`echo ${2}/${DIST}/${fileName}`
    else
	    render_dist=``
    fi

    if [ -e "${2}/${MISC}/${fileName}" ]; then
	    render_misc=`echo ${2}/${MISC}/${fileName}`
    else
	    render_misc=``
    fi
    
    if [ -e "${2}/${DUMMY}/${fileName}" ]; then
	    render_dummy=`echo ${2}/${DUMMY}/${fileName}`
    else
	    render_dummy=``
    fi
    
    if [ "${3}" = "Final" ]; then
        echo "${fileName}" >> ${PD}/final.log.txt
        # render final invoice, should work fine with excel based invoices since all dummy's are moved when split
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_invoice} ${render_attachment} ${render_statement}
        
        # render final excel
        # gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_attachment} ${render_statement}
    fi
    
    if [ "${3}" = "File_copy" ]; then
        echo "${fileName}" >> ${PD}/file_copy.log.txt
        # render file copy
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_invoice} ${render_dummy} ${render_credit} ${render_trust} ${render_attachment} ${render_dist} ${render_misc}
        
        # render file copy dummy
        # gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${render_excel} ${render_dummy} ${render_credit} ${render_trust} ${render_attachment} ${render_dist} ${render_misc}
    fi
}

bd_billing () {
    echo "bd billing"
}

pdc_billing () {
    # split source pdf documents
    
    if [ -e "${PD}/${STATEMENT}.info.txt" ]; then
        created=`grep "CreationDate" "${PD}/${STATEMENT}.info.txt"`
        
        echo -e "\n${STATEMENT} was processed on ${created:13}"
        read -p "Do you want to process ${STATEMENT} again [y/n] ? "
        
        if [ $REPLY = "y" ]; then
            ${THIS_PATH}/splitPDF.sh "${PD}/${STATEMENT}" "${PD}/${STATEMENTS}" 2
        fi
    else
        ${THIS_PATH}/splitPDF.sh "${PD}/${STATEMENT}" "${PD}/${STATEMENTS}" 2
    fi
    
    if [ -e "${PD}/${INVOICE}.info.txt" ]; then
        created=`grep "CreationDate" "${PD}/${INVOICE}.info.txt"`
        
        echo -e "\n${INVOICE} was processed on ${created:13}"
        read -p "Do you want to process ${INVOICE} again [y/n] ? "
        
        if [ $REPLY = "y" ]; then
            ${THIS_PATH}/splitPDF.sh "${PD}/${INVOICE}" "${PD}/${INVOICES}" 2 dummy 1
        fi
    else
        ${THIS_PATH}/splitPDF.sh "${PD}/${INVOICE}" "${PD}/${INVOICES}" 2 dummy 1
    fi
    
    if [ -e "${PD}/${TRUST}.info.txt" ]; then
        created=`grep "CreationDate" "${PD}/${TRUST}.info.txt"`
        
        echo -e "\n${TRUST} was processed on ${created:13}"
        read -p "Do you want to process ${TRUST} again [y/n] ? "
        
        if [ $REPLY = "y" ]; then
            ${THIS_PATH}/splitPDF.sh "${PD}/${TRUST}" "${PD}/${TRUSTS}" 2
        fi
    else
        ${THIS_PATH}/splitPDF.sh "${PD}/${TRUST}" "${PD}/${TRUSTS}" 2
    fi

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
    if [ ! -d "${PD}/${FINAL}" ]; then
	    mkdir "${PD}/${FINAL}"
    fi
    
    if [ ! -d "${PD}/${FILECOPY}" ]; then
	    mkdir "${PD}/${FILECOPY}"
    fi
}

check_directories
menu
