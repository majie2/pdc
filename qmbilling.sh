#! /bin/bash
# author:	Josef Kelly
# date:		March 14 2011
# license:	MIT
#
# description:
# Generates billing pdfs for qm
#
# args 1:

# invoice file
INVOICE="${1}/Invoice.pdf"

# invoice file
STATEMENT="${1}/Statement.pdf"

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
    if [ -d ${1}/Excel ]; then
	    echo "Building client invoices..."

	    # create final directory if it doesn't already exist
	    if [ ! -d ${1}/final ]; then
		    mkdir ${1}/final
	    fi

	    # for each pdf in Excel, build final pdf
	    shopt -s nullglob
	    for f in ${1}/Excel/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    # if the statement file exists for this client, add to queue
		    if [ -e ${1}/statements/$fileName ]; then
			    outStatement=`echo ${1}/statements/$fileName`
		    else
			    outStatement=``
		    fi

		    # if the attachment file exists for this client, add to queue
		    if [ -e ${1}/Attachment/$fileName ]; then
			    outAttachment=`echo ${1}/Attachment/$fileName`
		    else
			    outAttachment=``
		    fi
     
		    # combine all files added to queue and invoice page into final pdf
		    echo "${fileName}"
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/final/${fileName} ${outStatement} ${1}/Excel/${fileName} ${outAttachment}
	    done
    fi
fi

if [ "$word" = "File Copy" ]; then
    # split source pdf documents, uses the splitPDF script
    ${THIS_PATH}/splitPDFt.sh ${INVOICE} ${1}/invoices 2
    
    # build file copy invoice
    if [ -d ${1}/Excel ]; then
	    echo "Building file copy invoices..."

	    if [ ! -d ${1}/file_copy ]; then
		    mkdir ${1}/file_copy
	    fi

	    shopt -s nullglob
	    for f in ${1}/Excel/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    if [ -e ${1}/invoices/$fileName ]; then
			    fcInvoice=`echo ${1}/invoices/$fileName`
		    else
			    fcInvoice=``
		    fi

		    if [ -e ${1}/credit_memos/$fileName ]; then
			    fcCreditMemo=`echo ${1}/credit_memos/$fileName`
		    else
			    fcCreditMemo=``
		    fi

		    if [ -e ${1}/invoices/TRUST/$fileName ]; then
			    fcTrustInvoice=`echo ${1}/invoices/TRUST/$fileName`
		    else
			    fcTrustInvoice=``
		    fi

		    if [ -e ${1}/Attachment/$fileName ]; then
			    fcAttachment=`echo ${1}/Attachment/$fileName`
		    else
			    fcAttachment=``
		    fi

		    if [ -e ${1}/Source/$fileName ]; then
			    fcSource=`echo ${1}/Source/$fileName`
		    else
			    fcSource=``
		    fi

		    echo "${fileName}"
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/file_copy/${fileName} ${1}/Excel/${fileName} ${fcInvoice} ${fcTrustInvoice} ${fcCreditMemo} ${fcAttachment} ${fcSource}
	    done
    fi
fi
