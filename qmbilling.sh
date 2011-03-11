#! /bin/bash
# author:	Josef Kelly
# date:		March 9 2011
# license:	MIT
#
# description:
# Generates billing pdfs for 
# args 1:

# invoice file
INVOICE="${1}/invoices.pdf"

# invoice file
STATEMENT="${1}/statements.pdf"

# check if the directory exists
if [ -d ${1} ]; then
	echo "found ${1}..."
else
	echo "could not find ${1}, exiting..."
	exit 0
fi

# location where this script is being executed
THIS_PATH="`dirname \"$0\"`"

echo -n "Generate File Copy [y / n]? "
read answer

if [ $answer == "n" ]; then
    # split source pdf documents, uses the splitPDF script
    ${THIS_PATH}/splitPDF.sh ${STATEMENT} ${1}/statements 2

    # construct the invoices from pdfs in Excel
    if [ -d ${1}/excel ]; then
	    echo "building client invoices..."

	    # create final directory if it doesn't already exist
	    if [ ! -d ${1}/final ]; then
		    mkdir ${1}/final
	    fi

	    # for each pdf in Excel, build final pdf
	    shopt -s nullglob
	    for f in ${1}/excel/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    # if the statement file exists for this client, add to queue
		    if [ -e ${1}/statements/$fileName ]; then
			    outStatement=`echo ${1}/statements/$fileName`
		    else
			    outStatement=``
		    fi

		    # if the attachment file exists for this client, add to queue
		    if [ -e ${1}/attachment/$fileName ]; then
			    outAttachment=`echo ${1}/Attachment/$fileName`
		    else
			    outAttachment=``
		    fi
     
		    # combine all files added to queue and invoice page into final pdf
		    echo "${fileName} final..."
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/final/${fileName} ${1}/excel/${fileName} ${outStatement} ${outAttachment}
	    done
    fi
fi

if [ $answer == "y" ]; then
    # split source pdf documents, uses the splitPDF script
    ${THIS_PATH}/splitPDF.sh ${INVOICE} ${1}/invoices 2
    
    # build file copy invoice
    if [ -d ${1}/excel ]; then
	    echo "building file copy invoices..."

	    if [ ! -d ${1}/file_copy ]; then
		    mkdir ${1}/file_copy
	    fi

	    shopt -s nullglob
	    for f in ${1}/excel/*.pdf
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

		    if [ -e ${1}/trusts/$fileName ]; then
			    fcTrustInvoice=`echo ${1}/trusts/$fileName`
		    else
			    fcTrustInvoice=``
		    fi

		    if [ -e ${1}/attachment/$fileName ]; then
			    fcAttachment=`echo ${1}/attachment/$fileName`
		    else
			    fcAttachment=``
		    fi

		    if [ -e ${1}/source/$fileName ]; then
			    fcSource=`echo ${1}/source/$fileName`
		    else
			    fcSource=``
		    fi

		    echo "${fileName} file copy..."
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/file_copy/${fileName} ${1}/excel/${fileName} ${fcInvoice} ${fcCreditMemo} ${fcTrustInvoice} ${fcAttachment} ${fcSource}
	    done
    fi
fi
