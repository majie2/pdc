#! /bin/bash
# author:	Josef Kelly
# date:		March 14 2011
# license:	MIT
#
# description:
# Generates billing pdfs for qm
#
# args 1:

# STATIC FILES

INVOICE="${1}/Invoice.pdf"
STATEMENT="${1}/Statement.pdf"

# STATIC DIRECTORIES

INVOICES="${1}/Invoices"
STATEMENTS="${1}/Statements"
EXCEL="${1}/Excel"
ATTACHMENTS="${1}/Attachment"
SOURCE="${1}/Source"
CREDITMEMO="${1}/Credit_memo"
FINAL="${1}/Final"
FILECOPY="${}/File_copy"

# check if the directory exists
if [ ! -d "$1" ]; then
    echo "Directory does not exist: $1"
    exit 0
fi

# location where this script is being executed
THIS_PATH="`dirname \"$0\"`"

echo "Type the number of your selection and press enter"

select word in "Plan Invoices" "File Copy"
do
    break
done

if [ "$word" = "Plan Invoices" ]; then
    # split source pdf documents, uses the splitPDF script
    ${THIS_PATH}/splitPDF.sh ${STATEMENT} ${1}/statements 2

    # construct the invoices from pdfs in Excel
    if [ -d "${EXCEL}" ]; then
	    echo "Building client invoices..."

	    # create final directory if it doesn't already exist
	    if [ ! -d "${FINAL}" ]; then
		    mkdir ${FINAL}
	    fi

	    # for each pdf in Excel, build final pdf
	    shopt -s nullglob
	    for f in ${EXCEL}/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    # if the statement file exists for this client, add to queue
		    if [ -e "${STATEMENTS}/${fileName}" ]; then
			    outStatement=`echo ${STATEMENTS}/${fileName}`
		    else
			    outStatement=``
		    fi

		    # if the attachment file exists for this client, add to queue
		    if [ -e "${ATTACHMENTS}/${fileName}" ]; then
			    outAttachment=`echo ${ATTACHMENTS}/${fileName}`
		    else
			    outAttachment=``
		    fi
     
		    # combine all files added to queue and invoice page into final pdf
		    echo "${fileName}"
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${FINAL}/${fileName} ${outStatement} ${EXCEL}/${fileName} ${outAttachment}
	    done
    fi
fi

if [ "$word" = "File Copy" ]; then
    # split source pdf documents, uses the splitPDF script
    ${THIS_PATH}/splitPDF.sh ${INVOICE} ${1}/invoices 2 TRUST
    
    # build file copy invoice
    if [ -d "${EXCEL}" ]; then
	    echo "Building file copy invoices..."

	    if [ ! -d "${FILECOPY}" ]; then
		    mkdir ${FILECOPY}
	    fi

	    shopt -s nullglob
	    for f in ${EXCEL}/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    if [ -e "${INVOICES}/${fileName}" ]; then
			    fcInvoice=`echo ${INVOICES}/${fileName}`
		    else
			    fcInvoice=``
		    fi

		    if [ -e "${CREDITMEMO}/${fileName}" ]; then
			    fcCreditMemo=`echo ${CREDITMEMO}/${fileName}`
		    else
			    fcCreditMemo=``
		    fi

            #this cannot change since it relies on splitPDF.sh
		    if [ -e ${1}/invoices/TRUST/$fileName ]; then
			    fcTrustInvoice=`echo ${1}/invoices/TRUST/$fileName`
		    else
			    fcTrustInvoice=``
		    fi

		    if [ -e "${ATTACHMENTS}/${fileName}" ]; then
			    fcAttachment=`echo ${ATTACHMENTS}/${fileName}`
		    else
			    fcAttachment=``
		    fi

		    if [ -e "${SOURCE}/${fileName}" ]; then
			    fcSource=`echo ${SOURCE}/${fileName}`
		    else
			    fcSource=``
		    fi

		    echo "${fileName}"
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${FILECOPY}/${fileName} ${EXCEL}/${fileName} ${fcInvoice} ${fcTrustInvoice} ${fcCreditMemo} ${fcAttachment} ${fcSource}
	    done
    fi
fi
