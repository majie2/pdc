#! /bin/bash

count=0

while read line
do
    if [ "$line" ]
    then
        let count=$count+1
        
        if [ $count -eq 1 ]
        then
            extract=$(echo $line | cut -f1 -d'-')
            
            if [[ "$extract" =~ [0-9] ]]
            then
                key=$(echo $line | cut -f1 -d' ')
            else
                key="0"
            fi
        else
            birth=$(echo $line | cut -f7 -d' ')
            hire=$(echo $line | cut -f8 -d' ')
            
            echo "$key,$birth,$hire"
            
            birth=""
            hire=""
            extract=""
            key=""
            
            count=0
        fi
    fi
done < $1
