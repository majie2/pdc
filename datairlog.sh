#! /bin/bash

# args 1 file you're parsing
# args 2 output csv file

ssn=""
trimmed=""
lastname=""
firstname=""

declare -A event_types
declare -a event_type_order

if [ ! -e "${1}" ]
then
	read -p "Could not find log file, press enter to exit"
	exit 0
fi

if [ -e "${2}" ]
then
	echo "Deleting old csv file"
	rm "${2}"
fi

echo "Furiously parsing the log file"

while read line
do
	line=$(echo $line | tr -d '\r' | tr -d '\n')
	
	if [ "$(echo $line | cut -f1-2 -d' ')" == '== Company:' ]
	then
		company=$(echo $line | cut -f4 -d'=' | cut -f1 -d';')
	fi
	
	if [ "$(echo $line | cut -f1-2 -d' ')" == '== Employee:' ]
	then
		unset events
		
		ssn=$(echo $line | cut -f3 -d' ')
		trimmed=$(echo $line | cut -f1 -d',')
		
		lastname=$(echo $trimmed | cut -f4-$(echo "${trimmed//[^ ]}" | wc -c) -d' ')
		
		if [ ! "${lastname}" == "**NO NAME**" ]
		then
			firstname=$(echo $line | cut -f2 -d',' | cut -f2 -d' ' | tr -d ';')
		fi
		
		declare -A events
	fi
	
	if [ "$(echo $line | cut -f1 -d' ')" == "EE" ]
	then
		event_type=""
		event_desc=""
		event=""
		event_type_from=""
		event_type_to=""
		event_desc_from=""
		event_desc_to=""
		
		if [[ "${line}" == *"changed"* ]]
		then
			key=$(echo $line | grep -bo "changed" | cut -f1 -d:)
			key_from=$(echo $line | grep -bo "from" | cut -f1 -d:)
			let key_from=$key_from+4
			key_to=$(echo $line | grep -bo "to " | cut -f1 -d:)
			let key_to=$key_to+2
			
			event_type=$(echo ${line:0:$(echo $key)} | cut -f2 -d:)
			event_type_from="$(echo $event_type) from"
			event_type_to="$(echo $event_type) to"
			
			event_desc_from=$(echo ${line:$(echo $key_from)} | cut -f1 -d' ' | tr -d '.')
			event_desc_to=$(echo ${line:$(echo $key_to)} | cut -f1 -d' ' | tr -d '.')
			
			if [ -z "${event_types["${event_type_from// /_}"]}" ]
			then
				event_types["${event_type_from// /_}"]="${event_type_from}"
				event_type_order=("${event_type_order[@]}" "${event_type_from// /_}")
			fi
			
			if [ -z "${event_types["${event_type_to// /_}"]}" ]
			then
				event_types["${event_type_to// /_}"]="${event_type_to}"
				event_type_order=("${event_type_order[@]}" "${event_type_to// /_}")
			fi
			
			events["${event_type_from// /_}"]="${event_desc_from}"
			events["${event_type_to// /_}"]="${event_desc_to}"
		else
			event=$(echo $line | cut -f2 -d:)
			event_type=$(echo $event | cut -f2 -d' ')
			event_desc=$(echo $event | cut -f5 -d' ' | tr -d '.')
			
			if [ -z "${event_types["${event_type// /_}"]}" ]
			then
				event_types["${event_type// /_}"]="${event_type}"
				event_type_order=("${event_type_order[@]}" "${event_type// /_}")
			fi
			
			events["${event_type// /_}"]="${event_desc}"
		fi
	fi
	
	if [ "${#line}" -eq "0" ] && [ -n "$ssn" ]
	then
		
		output_line="$ssn,$company,$lastname,$firstname"
		
		for key in "${event_type_order[@]}"
		do
			if [ -n "${events["$key"]}" ]
			then
				output_line+=",${events["$key"]}"
			else
				output_line+=","
			fi
		done

		echo $output_line >> "${2}"
		
		output_line=""
		ssn=""
		trimmed=""
		lastname=""
		firstname=""
	fi
done < "${1}"

echo "Creating CSV and injecting header..."

header="SSN,Company,Last Name,First Name"

for key in "${event_type_order[@]}"
do
	header+=",${key//_/ }"
done

echo "${header}" | cat - "${2}" > temp && mv temp "${2}"

read -p "Complete, press enter to exit"
