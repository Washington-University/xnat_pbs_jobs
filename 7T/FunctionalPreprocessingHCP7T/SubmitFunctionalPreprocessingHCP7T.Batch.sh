#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

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

#project="HCP_Staging_7T"
#reference_project="HCP_500"

subject_file_name="${SUBJECT_FILES_DIR}/FunctionalPreprocessingHCP7T.subjects"
inform "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=1
max_shadow_number=8

shadow_number=${start_shadow_number}

for project_refproject_subject in ${subjects} ; do

	if [[ ${project_refproject_subject} != \#* ]]; then

		project=${project_refproject_subject%%:*}
		
		refproject=${project_refproject_subject%:*}
		refproject=${refproject#*:}

		subject=${project_refproject_subject##*:}
		
		server="db-shadow${shadow_number}.nrg.mir:8080"

		inform ""
		inform "--------------------------------------------------------------------------------"
		inform " Submitting FunctionalPreprocessingHCP7T jobs for:"
		inform "      project: ${project}"
		inform "   refproject: ${refproject}"
		inform "      subject: ${subject}"
		inform "       server: ${server}"
		inform "--------------------------------------------------------------------------------"
		
		${HOME}/pipeline_tools/xnat_pbs_jobs/7T/FunctionalPreprocessingHCP7T/SubmitFunctionalPreprocessingHCP7T.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--put-server=${server} \
			--project=${project} \
			--subject=${subject} \
			--structural-reference-project=${refproject} \
			--structural-reference-session=${subject}_3T \
			--setup-script=${SCRIPTS_HOME}/SetUpHCPPipeline_7T_FunctionalPreprocessing.sh
			# --do-not-clean-first

		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi

	fi

done
