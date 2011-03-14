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

function checkDir {
    if [ ! -d "$1" ]; then
        echo "Directory does not exist: $1"
    fi
}

checkDir $1

if [ ! -e "$2" ]; then
    echo "File not found: $2"
fi

echo "Testing map: $2"
declare -a keys

while read line
do
	key=`echo $line | sed -e 's/ /_/g'`
	keys=( ${keys[@]-} $(echo "$key") )
done < $2

for i in ${keys[@]}
do
    count=`echo $i | sed -e 's/_/ /g' | grep -o ':' | wc -l | sed 's/\ //g'`
    
    case $count in
    1)
        dirA=`echo $i | cut -f2 -d:`
        checkDir $1/$dirA
        ;;
    2)
        dirA=`echo $i | cut -f2 -d:`
        dirB=`echo $i | cut -f3 -d:`
        checkDir $1/$dirA/$dirB
        ;;
    *)
        echo "Unable to check $i"
    esac
done
