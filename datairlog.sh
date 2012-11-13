#! /bin/bash

echo "SSN,Last Name,First Name,New EE Created,Event 1,Event 2"

ssn=""
trimmed=""
lastname=""
firstname=""
created=""
eventone=""
eventtwo=""

while read line
do
	event="false"
	
	if [ "$(echo $line | cut -f1-2 -d' ')" == '== Employee:' ]
	then
		ssn=$(echo $line | cut -f3 -d' ')
		trimmed=$(echo $line | cut -f1 -d',')
		
		lastname=$(echo $trimmed | cut -f4-$(echo "${trimmed//[^ ]}" | wc -c) -d' ')
		firstname=$(echo $line | cut -f2 -d',' | cut -f2 -d' ' | tr -d ';' | tr -d '\r')
	fi
	
	if [ "$(echo $line | tr -d '\r')" == "New employee created" ]
	then
		created="true"
	fi
	
	if [ "$(echo $line | cut -f1 -d' ')" == "EE" ] && [ "${#eventone}" -eq "0" ]
	then
		eventone=$(echo $line | cut -f2 -d: | tr -d '\r')
		event="true"
	fi
	
	if [ "$(echo $line | cut -f1 -d' ')" == "EE" ] && [ -n "$eventone" ] && [ "$event" == "false" ]
	then
		eventtwo=$(echo $line | cut -f2 -d: | tr -d '\r')
	fi
	
	if [ "${#line}" -eq "1" ] && [ -n "$ssn" ]
	then
		echo "$ssn,$lastname,$firstname,$created,$eventone,$eventtwo"
		
		ssn=""
		trimmed=""
		lastname=""
		firstname=""
		created=""
		eventone=""
		eventtwo=""
	fi
done < "${1}"
