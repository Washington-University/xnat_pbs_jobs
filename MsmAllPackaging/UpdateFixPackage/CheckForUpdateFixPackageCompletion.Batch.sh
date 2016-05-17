#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
	echo "Environment variable SUBJECT_FILES_DIR must be set!"
	exit 1
fi

debug_msg() {
	msg=${1}
	#echo "DEBUG: ${msg}"
}

project="${1}"

if [ -z "${project}" ]; then
	printf "project name: "
	read project
fi

subject_file_name="${SUBJECT_FILES_DIR}/${project}.CheckUpdateFixPackageCompletion.subjects"
debug_msg "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
debug_msg "subject_list_from_file: ${subject_list_from_file}"
subjects="`echo "${subject_list_from_file[@]}"`"
debug_msg "subjects: ${subjects}"

for subject in ${subjects} ; do
	debug_msg "subject: ${subject}"
	if [[ ${subject} != \#* ]]; then
		./CheckForUpdateFixPackageCompletion.sh \
			--archive-root="/HCP/hcpdb/archive/${project}/arc001" \
			--subject=${subject} \
			--output-dir="/HCP/hcpdb/packages/PostMsmAll/${project}"
	fi
done
