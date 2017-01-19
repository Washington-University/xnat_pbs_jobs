#!/bin/bash

subject_file_name=SubmitGetDataHCP3T.Batch.subjects
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		arr=(${subject//:/ })
		project=${arr[0]}
		subject_id=${arr[1]}

		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting GetDataHCP3T job for: ${subject}"
		echo "       project: ${project}"
		echo "    subject_id: ${subject_id}"
		echo "--------------------------------------------------------------------------------"

		${XNAT_PBS_JOBS}/GetHcpDataUtils/SubmitGetDataHCP3T.OneSubject.sh \
			--project=${project} \
			--subject=${subject_id} 

	fi

done
