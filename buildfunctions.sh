#! /bin/bash
#args directory of files containing pdfs with plan names

if [ -d ${1} ]; then
	shopt -s nullglob
	for f in ${1}/*.*.pdf
	do
		fileName=`echo ${f##*/}`

		echo "Function Item_Open()"
		echo "Attachments.Add (\"G:\\FLEXFILE\\Admin\\Billing_Data\\final\\${fileName}\")"
		echo "End Function"
	done
fi
