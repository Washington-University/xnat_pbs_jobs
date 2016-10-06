#!/bin/bash

projects="HCP_500 HCP_900"

error_count=0
subjects_checked=0

for project in ${projects} ; do

	archive_root=/HCP/hcpdb/archive/${project}/arc001
	#echo "archive_root: ${archive_root}"

	sessions=`ls -d ${archive_root}/*3T | sort`
	#echo "sessions: ${sessions}"

	for session in ${sessions} ; do

		# get DWI scan sizes

		resources_dir=${session}/RESOURCES
		#echo "resources_dir: ${resources_dir}"

		diffusion_unproc_dir=${resources_dir}/Diffusion_unproc
		#echo "diffusion_unproc_dir: ${diffusion_unproc_dir}"

		diffusion_preproc_dir=${resources_dir}/Diffusion_preproc
		#echo "diffusion_preproc_dir: ${diffusion_preproc_dir}"

		if [ -e ${diffusion_unproc_dir} ] ; then
			#echo "${diffusion_unproc_dir} exists"
			pushd ${diffusion_unproc_dir} > /dev/null 

			dwi_dir_files=`ls *DWI*_[RL][LR].nii.gz | sort`
			
			sum=0
			for dwi_dir_file in ${dwi_dir_files} ; do
				volume_count=`fslinfo ${dwi_dir_file} | grep dim4 | grep -v pix | head -1 | tr -s ' ' | cut -d ' ' -f 2`
				#echo "dwi_dir_file: ${dwi_dir_file}"
				#echo "volume_count: ${volume_count}"
				sum=$((sum + volume_count))
			done

			#echo "sum of volume counts: ${sum}"
			expected_data_size=$(( sum / 2 ))
			#echo "expected_data_size: ${expected_data_size}"

			popd > /dev/null


			if [ -e ${diffusion_preproc_dir} ] ; then
				#echo "${diffusion_preproc_dir} exists"

				subjects_checked=$(( subjects_checked + 1 ))

				diff_data_file=${diffusion_preproc_dir}/Diffusion/data/data.nii.gz
				#echo "diff_data_file: ${diff_data_file}"

				T1w_diff_data_file=${diffusion_preproc_dir}/T1w/Diffusion/data.nii.gz
				#echo "T1w_diff_data_file: ${T1w_diff_data_file}"

				diff_data_volume_count=`fslinfo ${diff_data_file} | grep dim4 | grep -v pix | head -1 | tr -s ' ' | cut -d ' ' -f 2`
				#echo "diff_data_volume_count: ${diff_data_volume_count}"

				T1w_diff_data_volume_count=`fslinfo ${T1w_diff_data_file} | grep dim4 | grep -v pix | head -1 | tr -s ' ' | cut -d ' ' -f 2`
				#echo "T1w_diff_data_volume_count: ${T1w_diff_data_volume_count}"

				#echo ""
				#echo "Expected volume count: ${expected_data_size}"
				#echo "${diff_data_file} : ${diff_data_volume_count}"
				#echo "${T1w_diff_data_file} : ${T1w_diff_data_volume_count}"

				if [ "${diff_data_volume_count}" -ne "${expected_data_size}" -o "${T1w_diff_data_volume_count}" -ne "${expected_data_size}" ] ; then
					error_count=$(( error_count + 1 ))
					echo -e "${error_count}\tERROR: ${diff_data_file}\tExpected: ${expected_data_size}\tActual: ${diff_data_volume_count}"
					echo -e "\tERROR: ${T1w_diff_data_file}\tExpected: ${expected_data_size}\tActual: ${T1w_diff_data_volume_count}"
				fi

			fi

		fi

	done

done

echo ""
echo "Total subjects checked: ${subjects_checked} that had a Diffusion_unproc and Diffusion_preproc directory"
echo ""