#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

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

source ${XNAT_PBS_JOBS}/shlib/log.shlib # Logging related functions
log_Msg "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

printf "Project: "
read project

subject_file_name="subjectfiles/${project}.MSMAllRegistration.subjects"
log_Msg "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=${XNAT_PBS_JOBS_MIN_SHADOW}
max_shadow_number=${XNAT_PBS_JOBS_MAX_SHADOW}

shadow_number=$(shuf -i ${start_shadow_number}-${max_shadow_number} -n 1)

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		server="db-shadow${shadow_number}.nrg.mir:8080"

		log_Msg "--------------------------------------------------------------------------------"
		log_Msg " Submitting MSMAllRegistration job for subject: ${subject}"
		log_Msg " Using server: ${server}"
		log_Msg "--------------------------------------------------------------------------------"
		
		${XNAT_PBS_JOBS}/MSMAllRegistration/SubmitMSMAllRegistration.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--server=${server} \
			--project=${project} \
			--subject=${subject}

		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi

	fi

done
