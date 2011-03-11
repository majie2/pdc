#! /bin/bash
# author:	Josef Kelly
# date:		March 9 2011
# license:	MIT
#
# description:
# Determines if a mapping file is correct
#
# args 1: directory to search for map results
# args 2: mapping file

if [ ! -d $1 ]; then
    echo "$1 not found"
fi

if [ ! -e $2 ]; then
    echo "$2 not found"
fi

echo "testing map: $2"

declare -a keys

while read line
do
	key=`echo $line`
	keys=( ${keys[@]-} $(echo "$key") )
done < $2

for i in ${keys[@]}
do
    count=`echo $i | grep -o ":" | wc -l | sed /\ //g`
done
