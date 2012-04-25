#! /bin/bash

read_next=0

#echo "shop code,employee number,first name,last name,gross pay,EE amt,ER amt,dob,doh"

shop=$(echo ${1##*/} | cut -f1 -d.)

while read line
do
	data=$(echo $line | grep "XXX-XX-XXXX")
	
	if [ $read_next -eq 1 ]
	then
		#echo $line
		
		read_next=0
		check=$(echo $line | sed "s: : \n:g" | grep -c " ")

		if [ "$check" -eq 6 ]
		then
			dob=$(echo $line | cut -f2 -d' ')
			doh=$(echo $line | cut -f3 -d' ')
			er_amt=$(echo $line | cut -f6 -d' ')
		else
			dob=$(echo $line | cut -f1 -d' ')
			doh=$(echo $line | cut -f2 -d' ')
			er_amt=$(echo $line | cut -f5 -d' ')
		fi
		
		echo "$shop,$employee_number,$first_name,${one:${num_length}},$gross_pay,$ee_amt,$er_amt,${dob//\//},${doh//\//}"
		
		dob=""
		doh=""
		er_amt=""
		one=""
		two=""
		employee_number=""
		first_name=""
		gross_pay=""
		ee_amt=""
	fi
	
	if [ "${#data}" -gt 0 ]
	then
		read_next=1
		
		one=$(echo $line | cut -f1 -d',' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
		two=$(echo $line | cut -f2 -d',' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
		
		employee_number=$(echo $line | cut -f1 -d' ')
		let num_length=${#employee_number}+1
		
		first_name=$(echo $two | cut -f1 -d' ')
		gross_pay=$(echo $two | cut -f3 -d' ')
		
		if [ "$gross_pay" = "Xxx-Xx-Xxxx" ]
		then
			gross_pay=$(echo $two | cut -f4 -d' ')
			ee_amt=$(echo $two | cut -f6 -d' ')
			first_name=$(echo $two | cut -f1-2 -d' ')
		else
			ee_amt=$(echo $two | cut -f5 -d' ')
		fi
		
		#echo $line
	fi
done < $1
