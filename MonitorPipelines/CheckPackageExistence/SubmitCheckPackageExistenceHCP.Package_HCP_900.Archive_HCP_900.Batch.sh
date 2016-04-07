#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
	echo "Environment variable SUBJECT_FILES_DIR must be set!"
	exit 1
fi

package_project="HCP_900"
archive_project="HCP_900"

subject_file_name="${SUBJECT_FILES_DIR}/Package_${package_project}.Archive_${archive_project}.CheckPackageExistenceHCP.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

 		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting Package Existence check job for subject: ${subject}"
		echo "--------------------------------------------------------------------------------"

		${HOME}/pipeline_tools/xnat_pbs_jobs/MonitorPipelines/CheckPackageExistence/SubmitCheckPackageExistenceHCP.OneSubject.sh \
			--subject=${subject} \
			--archive-project=${archive_project} \
			--package-project=${package_project}

	fi
	
done
