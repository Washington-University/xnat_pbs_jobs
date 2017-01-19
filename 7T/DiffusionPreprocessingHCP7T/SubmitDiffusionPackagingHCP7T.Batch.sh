#!/bin/bash

subject_file_name=DiffusionPackagingHCP7T.subjects
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		arr=(${subject//:/ })
		project=${arr[0]}
		ref_project=${arr[1]}
		subject_id=${arr[2]}

 		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting Diffusion 7T Packaging job for: ${subject}"
		echo "       project: ${project}"
		echo "   ref_project: ${ref_project}"
		echo "    subject_id: ${subject_id}"
		echo "--------------------------------------------------------------------------------"

		${XNAT_PBS_JOBS}/7T/DiffusionPreprocessingHCP7T/SubmitDiffusionPackagingHCP7T.OneSubject.sh \
			--project=${project} \
			--ref-project=${ref_project} \
			--subject=${subject_id} 

	fi

done