#! /bin/bash
# author:	Josef Kelly
# date:		February 11 2011
# license:	MIT
#
# description: a
# Generates the final and file copy billing pdfs for 401k clients
#
# args 1: directory of files containing the original billing pdfs (statements, invoices, credit memos, etc...)

# STATIC FILES

STATEMENT="${1}/Statement.pdf"
INVOICE="${1}/Invoice.pdf"
#CREDITMEMO="${1}/Credit.pdf"
TRUST="${1}/Trust.pdf"

# STATIC DIRECTORIES

INVOICES="${1}/Invoices"
STATEMENTS="${1}/Statements"
EXCEL="${1}/Excel"
ATTACHMENTS="${1}/Attachment"
DIST="${1}/Dist"
MISC="${1}/Misc"
SOURCE="${1}/Source"
DUMMY="${1}/Dummy"
CREDITMEMOS="${1}/Credit_memo"
FINAL="${1}/Final"
FILECOPY="${1}/File_copy"

# STATIC DIRECTORIES

# check if the directory specified by the user exists, if it doesn't, exit
if [ -d ${1} ]; then
	echo "found ${1}..."
else
	echo "could not find ${1}, exiting..."
	exit 0
fi

# location where this script is being executed
THIS_PATH="`dirname \"$0\"`"

# split source pdf documents, uses the splitPDF script
${THIS_PATH}/splitPDF.sh ${STATEMENT} ${STATEMENTS} 2
${THIS_PATH}/splitPDF.sh ${INVOICE} ${INVOICES} 2 dummy 1

echo "Type the number of your selection and press enter"

select word in "Plan Invoices" "File Copy"
do
    break
done

if [ "$word" = "Plan Invoices" ]; then
    # construct the invoices from pdf pages in Invoice.pdf
    if [ -d "${INVOICES}" ]; then
	    echo "building client invoices..."

	    # create final directory if it doesn't already exist
	    if [ ! -d "${FINAL}" ]; then
		    mkdir ${FINAL}
	    fi

	    # for each page/client (one page per client) in Invoice.pdf build the final billing pdf
	    shopt -s nullglob
	    for f in ${INVOICES}/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    # if the statement file exists for this client, add to queue
		    if [ -e "${STATEMENTS}/${fileName}" ]; then
			    outStatement=`echo ${STATEMENTS}/${fileName}`
		    else
			    outStatement=``
		    fi

		    # if the excel file exists for this client, add to queue
		    if [ -e "${EXCEL}/${fileName}" ]; then
			    outExcelInvoice=`echo ${EXCEL}/${fileName}`
		    else
			    outExcelInvoice=``
		    fi

		    # if the attachment file exists for this client, add to queue
		    if [ -e "${ATTACHMENTS}/${fileName}" ]; then
			    outAttachment=`echo ${ATTACHMENTS}/${fileName}`
		    else
			    outAttachment=``
		    fi
     
		    # combine all files added to queue and invoice page into final pdf
		    echo "${fileName} final..."
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${FINAL}/${fileName} ${outExcelInvoice} ${1}/invoices/${fileName} ${outAttachment} ${outStatement}
	    done
    fi

    # build invoices to clients
    if [ -d "${EXCEL}" ]; then
	    echo "building client invoices from excel..."

	    if [ ! -d "${FINAL}" ]; then
		    mkdir ${FINAL}
	    fi

	    shopt -s nullglob
	    for f in ${EXCEL}/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    if [ -e "${STATEMENTS}/${fileName}" ]; then
			    outStatement=`echo ${STATEMENTS}/${fileName}`
		    else
			    outStatement=``
		    fi

		    if [ -e "${ATTACHMENTS}/${fileName}" ]; then
			    outAttachment=`echo ${ATTACHMENTS}/${fileName}`
		    else
			    outAttachment=``
		    fi

		    echo "${fileName} final..."
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${FINAL}/${fileName} ${outStatement} ${EXCEL}/${fileName} ${outAttachment}
	    done
    fi
fi

if [ "$word" = "File Copy" ]; then
    #${THIS_PATH}/splitPDF.sh ${CREDITMEMO} ${1}/credit_memos 2
    ${THIS_PATH}/splitPDF.sh ${TRUST} ${1}/trusts 2

    # build file copy invoice
    if [ -d "${INVOICES}" ]; then
	    echo "building file copy invoices..."

	    if [ ! -d "${FILECOPY}" ]; then
		    mkdir ${FILECOPY}
	    fi

	    shopt -s nullglob
	    for f in ${INVOICES}/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    if [ -e "${EXCEL}/${fileName}" ]; then
			    fcExcelInvoice=`echo ${EXCEL}/${fileName}`
		    else
			    fcExcelInvoice=``
		    fi

		    if [ -e "${CREDITMEMOS}/${fileName}" ]; then
			    fcCreditMemo=`echo ${CREDITMEMOS}/${fileName}`
		    else
			    fcCreditMemo=``
		    fi

		    if [ -e ${1}/trusts/$fileName ]; then
			    fcTrustInvoice=`echo ${1}/trusts/$fileName`
		    else
			    fcTrustInvoice=``
		    fi

		    if [ -e "${ATTACHMENTS}/${fileName}" ]; then
			    fcAttachment=`echo ${ATTACHMENTS}/${fileName}`
		    else
			    fcAttachment=``
		    fi

		    if [ -e "${DIST}/${fileName}" ]; then
			    fcDistributionChecklist=`echo ${DIST}/$fileName`
		    else
			    fcDistributionChecklist=``
		    fi

		    if [ -e "${MISC}/${fileName}" ]; then
			    fcEmail=`echo ${MISC}/${fileName}`
		    else
			    fcEmail=``
		    fi

		    echo "${fileName} file copy..."
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${FILECOPY}/${fileName} ${fcExcelInvoice} ${INVOICES}/${fileName} ${fcCreditMemo} ${fcTrustInvoice} ${fcAttachment} ${fcDistributionChecklist} ${fcEmail}
	    done
    fi

    # build file copy invoice
    if [ -d "${DUMMY}" ]; then
	    echo "building file copy invoices from excel..."

	    if [ ! -d "${FILECOPY}" ]; then
		    mkdir ${FILECOPY}
	    fi

	    shopt -s nullglob
	    for f in ${DUMMY}/*.pdf
	    do
		    fileName=`echo ${f##*/}`

		    if [ -e "${EXCEL}/${fileName}" ]; then
			    fcExcel=`echo ${EXCEL}/${fileName}`
		    else
			    fcExcel=``
		    fi

		    if [ -e "${CREDITMEMOS}/${fileName}" ]; then
			    fcCreditMemo=`echo ${CREDITMEMOS}/${fileName}`
		    else
			    fcCreditMemo=``
		    fi

		    if [ -e ${1}/trusts/$fileName ]; then
			    fcTrustInvoice=`echo ${1}/trusts/$fileName`
		    else
			    fcTrustInvoice=``
		    fi

		    if [ -e "${ATTACHMENTS}/${fileName}" ]; then
			    fcAttachment=`echo ${ATTACHMENTS}/${fileName}`
		    else
			    fcAttachment=``
		    fi

		    if [ -e "${DIST}/${fileName}" ]; then
			    fcDistributionChecklist=`echo ${DIST}/${fileName}`
		    else
			    fcDistributionChecklist=``
		    fi

		    if [ -e "${MISC}/${fileName}" ]; then
			    fcEmail=`echo ${MISC}/${fileName}`
		    else
			    fcEmail=``
		    fi

		    echo "${fileName} file copy..."
		    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${FILECOPY}/${fileName} ${fcExcel} ${DUMMY}/${fileName} ${fcCreditMemo} ${fcTrustInvoice} ${fcAttachment} ${fcDistributionChecklist} ${fcEmail}
	    done
    fi
fi

echo "cleaning up..."

#rm -r ${1}/statements
#rm -r ${1}/invoices

echo "done!"
echo "Invoices to clients in final folder & file copy invoices in the file_copy folder"
