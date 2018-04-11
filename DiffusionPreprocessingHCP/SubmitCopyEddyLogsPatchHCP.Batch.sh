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

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject_file_name=SubmitCopyEddyLogsPatchHCP.Batch.subjects
inform "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=${XNAT_PBS_JOBS_MIN_SHADOW}
max_shadow_number=${XNAT_PBS_JOBS_MAX_SHADOW}

shadow_number=`shuf -i ${start_shadow_number}-${max_shadow_number} -n 1`

for project_subject in ${subjects} ; do

	if [[ ${project_subject} != \#* ]]; then

		project=${project_subject%%:*}
		subject=${project_subject##*:}

		server="db-shadow${shadow_number}.nrg.mir:8080"

 		inform ""
		inform "--------------------------------------------------------------------------------"
		inform " Submitting CopyEddyLogsPatchHCP job for:"
		inform "   project: ${project}"
		inform "   subject: ${subject}"
		inform "    server: ${server}"
		inform "--------------------------------------------------------------------------------"

		${XNAT_PBS_JOBS}/DiffusionPreprocessingHCP/SubmitCopyEddyLogsPatchHCP.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--project=${project} \
			--subject=${subject}

		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi
		
	fi
	
done
