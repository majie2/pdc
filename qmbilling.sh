#! /bin/bash
# author:	Josef Kelly
# date:		March 9 2011
# license:	MIT
#
# description:
# args 1:

# invoice file
INVOICE="${1}/invoices.pdf"

# check if the directory exists
if [ -d ${1} ]; then
	echo "found ${1}..."
else
	echo "could not find ${1}, exiting..."
	exit 0
fi

# location where this script is being executed
THIS_PATH="`dirname \"$0\"`"

# split source pdf documents, uses the splitPDF script
${THIS_PATH}/splitPDF.sh ${STATEMENT} ${1}/statements 2
