#! /bin/bash
# author:	Josef Kelly
# date:		February 11 2011
# license:	MIT

VERSION=2.0

# reference to path where this script is being run
THIS_PATH="`dirname \"$0\"`"

# billing directories
BD="/mnt/billing"
PD="/mnt/billing_401k"

# pdf names
STATEMENT="Statement.pdf"
INVOICE="Invoice.pdf"
TRUST="Trust.pdf"

# specific directories
INVOICES="Invoices"
STATEMENTS="Statements"
EXCEL="Excel"
ATTACHMENTS="Attachment"
DIST="Dist"
MISC="Misc"
SOURCE="Source"
DUMMY="Dummy"
CREDITMEMOS="Credit_memo"
FINAL="Final"
FILECOPY="File_copy"

echo "##############################"
echo "# BILLING.SH v2.0            #"
echo "#                            #"
echo "# author  : josef kelly      #"
echo "# license : mit              #"
echo "# version : 2.0              #"
echo "##############################"

menu () {
    echo "MENU"
    echo "Type the number of your selection and press enter"

    select word in "401(k) Billing" "Flexible Benefits Billing"
    do
        break
    done
    
    if [ "$word" = "401(k) Billing" ]; then
        pdc_billing
    fi
    
    if [ "$word" = "Flexible Benefits Billing" ]; then
        bd_billing
    fi
}

# expects a few arguments
# arg 1 : filename
# arg 2 : directory to find everything
# arg 3 : directory to place pdf
build_pdf () {
    fileName=`echo ${1##*/}`
    
    # if the statement file exists for this client, add to queue
    if [ -e "${2}/${INVOICES}/${fileName}" ]; then
	    finalPDInvoice=`echo ${2}/${INVOICES}/${fileName}`
    else
	    finalPDInvoice=``
    fi
    
    # if the statement file exists for this client, add to queue
    if [ -e "${2}/${STATEMENTS}/${fileName}" ]; then
	    finalPDStatement=`echo ${2}/${STATEMENTS}/${fileName}`
    else
	    finalPDStatement=``
    fi

    # if the excel file exists for this client, add to queue
    if [ -e "${2}/${EXCEL}/${fileName}" ]; then
	    finalPDExcel=`echo ${2}/${EXCEL}/${fileName}`
    else
	    finalPDExcel=``
    fi

    # if the attachment file exists for this client, add to queue
    if [ -e "${2}/${ATTACHMENTS}/${fileName}" ]; then
	    finalPDAttachment=`echo ${2}/${ATTACHMENTS}/${fileName}`
    else
	    finalPDAttachment=``
    fi

    # combine all files added to queue and invoice page into final pdf
    echo "${fileName} final..."
    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${2}/${3}/${fileName} ${finalPDExcel} ${finalPDInvoice} ${finalPDAttachment} ${finalPDStatement}
}

bd_billing () {
    echo "bd billing"
}

pdc_billing () {
    echo "pdc billing"

    # split source pdf documents
    # TODO check if these files were already created
    ${THIS_PATH}/splitPDF.sh "${PD}/${STATEMENT}" "${PD}/${STATEMENTS}" 2
    ${THIS_PATH}/splitPDF.sh "${PD}/${INVOICE}" "${PD}/${INVOICES}" 2 dummy 1
    
    # for each page/client (one page per client) in Invoice.pdf build the final billing pdf
    shopt -s nullglob
    for f in ${PD}/${INVOICES}/*.pdf
    do
	    build_pdf ${f} ${PD} ${FINAL}
    done
}

menu
