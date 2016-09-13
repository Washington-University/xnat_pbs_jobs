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

subject_file_name="${SUBJECT_FILES_DIR}/CheckForAddResolutionPatchHCP7T.subjects"

inform "Retrieving subject list from ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

rm -f *.complete.status
rm -f *.incomplete.status

for project_subject in ${subjects} ; do
	if [[ ${project_subject} != \#* ]]; then

		project=${project_subject%%:*}
		subject=${project_subject##*:}

		./CheckForAddResolutionPatchHCP7TCompletion.sh --project=${project} --subject=${subject}

	fi

done
