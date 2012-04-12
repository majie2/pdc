#! /bin/bash

count=0

while read line
do
    if [ "$line" ]
    then
        let count=$count+1
        
        if [ $count -eq 1 ]
        then
            #line 1
            block=$(echo $line | cut -f1 -d'-')
            
            location=$(echo $block | cut -f1 -d' ')
            name1=$(echo $block | cut -f2 -d' ')
            name2=$(echo $block | cut -f3 -d' ')
            name3=$(echo $block | cut -f4 -d' ')
            
            if [[ "$line" == *terminated* ]]
            then
                date1=$(echo $line | cut -f1 -d'/')
                date2=$(echo $line | cut -f2 -d'/')
                date3=$(echo $line | cut -f3 -d'/' | cut -f1 -d' ')
                
                spaces=$(grep -o " " <<< "$date1" | wc -l)
                let spaces=$spaces+1
                
                date1=$(echo $date1 | cut -f$(echo $spaces) -d' ')
                
                term="$date1/$date2/$date3"
            fi
        else
            #line 2
            
            comp=$(echo $line | cut -f2 -d' ')
            er=$(echo $line | cut -f4 -d' ')
            sr=$(echo $line | cut -f5 -d' ')
            match=$(echo $line | cut -f6 -d' ')
            total=$(echo $line | cut -f7 -d' ')
        fi
    else
        if [[ "$block" == *.* ]]
        then
            echo "$location,$name1,$name2,$name3,$term,\"$comp\",\"$er\",,\"$sr\",\"$match\",,\"$total\""
        else
            echo "$location,$name1,,$name2,$term,\"$comp\",\"$er\",,\"$sr\",\"$match\",,\"$total\""
        fi
        
        count=0
        location=""
        block=""
        name1=""
        name2=""
        name3=""
        comp=""
        er=""
        sr=""
        match=""
        total=""
        term=""
    fi
done < $1
