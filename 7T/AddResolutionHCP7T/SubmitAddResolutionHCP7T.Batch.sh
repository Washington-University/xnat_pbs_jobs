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

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

#project="HCP_900"
subject_file_name=${SUBJECT_FILES_DIR}/7T.subjects
inform "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=1
max_shadow_number=8

shadow_number=${start_shadow_number}

for project_subject in ${subjects} ; do

	if [[ ${project_subject} != \#* ]]; then

		project=${project_subject%%:*}
		subject=${project_subject##*:}

		server="db-shadow${shadow_number}.nrg.mir:8080"

 		inform ""
		inform "--------------------------------------------------------------------------------"
		inform " Submitting AddResolutionHCP7T Preprocessing job for:"
		inform "   project: ${project}"
		inform "   subject: ${subject}"
		inform "    server: ${server}"
		inform "--------------------------------------------------------------------------------"

		${HOME}/pipeline_tools/xnat_pbs_jobs/7T/AddResolutionHCP7T/SubmitAddResolutionHCP7T.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--project=${project} \
			--subject=${subject} \
			--setup-script=${SCRIPTS_HOME}/SetUpHCPPipeline_7T_FunctionalPreprocessing.sh
			# --do-not-clean-first

		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi
		
	fi
	
done
