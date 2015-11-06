#!/bin/bash

# home directory for XNAT Resource Stuff
WORKING_DIR_PUT_HOME=/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/WorkingDirPut

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

project="HCP_Staging"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.GenerateSpinEchoBiasFieldPrereqs.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

for subject in ${subjects} ; do
	${WORKING_DIR_PUT_HOME}/DeleteResource.sh --user=${userid} --password=${password} --project=${project} --subject=${subject} --session=${subject}_3T --resource=GenerateSpinEchoBiasFields --force
done

