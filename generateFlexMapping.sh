#! /bin/bash

#directory of files to sort
if [ ! -d ${1} ]; then
	exit 0
fi

shopt -s nullglob
for f in ${1}/*.pdf
do
	file=`echo ${f##*/} | cut -f1-2 -d.`
	title=(${file,,})
	title=`echo ${title[@]^} | cut -f1 -d.`
	typ=`echo ${f##*/} | cut -f2 -d.`
	echo "${file}::${title}.${typ}"
done
