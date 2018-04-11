#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

if [ -z "${SUBJECT_FILES_DIR}" ]; then
	inform "Environment variable SUBJECT_FILES_DIR must be set!"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS}" ]; then
	inform "Environment variable XNAT_PBS_JOBS must be set!"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_MIN_SHADOW}" ]; then
	inform "Environment variable XNAT_PBS_JOBS_MIN_SHADOW must be set!"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_MAX_SHADOW}" ]; then
	inform "Environment variable XNAT_PBS_JOBS_MAX_SHADOW must be set!"
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

project="HCP_Staging_RT"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.RestingStateStats.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=${XNAT_PBS_JOBS_MIN_SHADOW}
max_shadow_number=${XNAT_PBS_JOBS_MAX_SHADOW}

shadow_number=${start_shadow_number}

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		server="db-shadow${shadow_number}.nrg.mir:8080"

 		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting RestingStateStats jobs for subject: ${subject}"
		echo " Using server: ${server}"
		echo " Submission delayed until ${delay} minutes from now"
		echo "--------------------------------------------------------------------------------"

		at now + ${delay} minutes <<EOF 
			${XNAT_PBS_JOBS}/RestingStateStats/SubmitRestingStateStats.OneSubject.sh \
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
