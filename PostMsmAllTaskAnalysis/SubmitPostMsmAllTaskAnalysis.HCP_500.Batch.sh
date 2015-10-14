#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
	echo "Environment variable SUBJECT_FILES_DIR must be set!"
	exit 1
fi

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

printf "Delay until first submission (minutes) [0]: "
read delay

if [ -z "${delay}" ]; then
	delay=0
fi

printf "Interval between submissions (minutes) [60]: "
read interval

if [ -z "${interval}" ]; then
	interval=60
fi

project="HCP_500"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.PostMsmAllTaskAnalysis.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=1
max_shadow_number=8

shadow_number=${start_shadow_number}

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		server="db-shadow${shadow_number}.nrg.mir:8080"

		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting PostMsmAllTaskAnalysis job for subject: ${subject}"
		echo " Using server: ${server}"
		echo " Submission delayed until ${delay} minutes from now"
		echo "--------------------------------------------------------------------------------"
		
		at now + ${delay} minutes <<EOF 
			/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/PostMsmAllTaskAnalysis/SubmitPostMsmAllTaskAnalysis.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--server=${server} \
			--project=${project} \
			--subject=${subject}
EOF
	
		delay=$((delay + interval))

		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi

	fi

done
