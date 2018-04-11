#!/bin/bash

archive_root="/HCP/hcpdb/archive"
packages_tmp="/HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp"
output_dir="/HCP/hcpdb/packages/prerelease/zip/HCP_1200"

subject_file_name="CreateAllPackages.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

for subject_spec in ${subjects} ; do

	if [[ ${subject_spec} != \#* ]]; then

		parsing_subject_spec="${subject_spec}"

		project=${parsing_subject_spec%%:*}
		parsing_subject_spec=${parsing_subject_spec#*:}

		refproject=${parsing_subject_spec%%:*}
		parsing_subject_spec=${parsing_subject_spec#*:}
		
		subject=${parsing_subject_spec%%:*}
		parsing_subject_spec=${parsing_subject_spec#*:}

		comments=${parsing_subject_spec}

		names=""
		names+=" Create1p6mmFixPackage "          # 1
		names+=" Create1p6mmPreprocPackage "      # 2
		names+=" Create2mmFixPackage "            # 3
		names+=" Create2mmPreprocPackage "        # 4
		names+=" CreateFixExtendedPackage "       # 5
		names+=" CreatePreprocExtendedPackage "   # 6
		names+=" CreateStructuralPreprocPackage " # 7
		# names+=" CreateVolumeFixPackage "         # 8
		# names+=" CreateVolumePreprocPackage "     # 9

		for name in ${names} ; do 

			scripts_to_submit_dir="${XNAT_PBS_JOBS_BUILD_DIR}/package_scripts_to_submit/${name}"
			log_dir="${XNAT_PBS_JOBS_LOG_DIR}/package_logs/${name}"

			mkdir -p ${log_dir}
			mkdir -p ${scripts_to_submit_dir}

			current_time_str=`date +%s`
			script_file_to_submit=${scripts_to_submit_dir}/${subject}.${name}.${current_time_str}.PBS_job.sh
			if [ -e "${script_file_to_submit}" ]; then
				rm -f "${script_file_to_submit}"
			fi

			touch ${script_file_to_submit}
			echo "#PBS -l nodes=1:ppn=1,walltime=08:00:00,vmem=4000mb" >> ${script_file_to_submit}
			#echo "#PBS -q HCPput" >> ${script_file_to_submit}
			echo "#PBS -o ${log_dir}" >> ${script_file_to_submit}
			echo "#PBS -e ${log_dir}" >> ${script_file_to_submit}

			echo ""
			echo "${HOME}/pipeline_tools/xnat_pbs_jobs/7T/${name}/${name}.sh \\" >> ${script_file_to_submit}
			echo "  --archive-root=${archive_root} \\" >> ${script_file_to_submit}
 			echo "  --subject=${subject} \\" >> ${script_file_to_submit}
			echo "  --three-t-project=${refproject} \\" >> ${script_file_to_submit}
			echo "  --seven-t-project=${project} \\" >> ${script_file_to_submit}
			echo "  --tmp-dir=${packages_tmp} \\" >> ${script_file_to_submit}
			echo "  --release-notes-template-file=${HOME}/pipeline_tools/xnat_pbs_jobs/7T/${name}/ReleaseNotes.txt \\" >> ${script_file_to_submit}
			echo "  --output-dir=${output_dir} \\" >> ${script_file_to_submit}
			echo "  --create-checksum \\" >> ${script_file_to_submit}
			echo "  --create-contentlist \\" >> ${script_file_to_submit}
			echo "  --dont-overwrite \\" >> ${script_file_to_submit}
			echo "  --ignore-missing-files " >> ${script_file_to_submit}

			chmod +x ${script_file_to_submit}

			submit_cmd="qsub ${script_file_to_submit}"
			echo "submit_cmd: ${submit_cmd}"
			
			processing_job_no=`${submit_cmd}`
			
			echo "${name}: processing_job_no: ${processing_job_no}"

		done

	fi

done
