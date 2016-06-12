#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
    echo "Environment variable SUBJECT_FILES_DIR must be set!"
    exit 1
fi

packages_root="/HCP/hcpdb/packages/prerelease/zip/HCP_Staging_7T"
archive_root="/HCP/hcpdb/archive"
packages_tmp="/HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp"

output_dir="/HCP/hcpdb/packages/prerelease/zip/HCP_Staging_7T"

scripts_to_submit_dir="${HOME}/pipeline_tools/xnat_pbs_jobs/7T/CreateStructuralPreprocPackage/scripts_to_submit"
log_dir="${HOME}/pipeline_tools/xnat_pbs_jobs/7T/CreateStructuralPreprocPackage/logs"

# ----------
subject_file_name="${SUBJECT_FILES_DIR}/CreateStructuralPreprocPackage.subjects"
# ----------

echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

mkdir -p ${log_dir}
mkdir -p ${scripts_to_submit_dir}

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

		current_time_str=`date +%s`
		script_file_to_submit=${scripts_to_submit_dir}/${subject}.CreateStructuralPreprocPackage.${current_time_str}.PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=08:00:00,vmem=4000mb" >> ${script_file_to_submit}
		echo "#PBS -q HCPput" >> ${script_file_to_submit}
		echo "#PBS -o ${log_dir}" >> ${script_file_to_submit}
        echo "#PBS -e ${log_dir}" >> ${script_file_to_submit}

		echo ""
		echo "${HOME}/pipeline_tools/xnat_pbs_jobs/7T/CreateStructuralPreprocPackage/CreateStructuralPreprocPackage.sh \\" >> ${script_file_to_submit}
		echo "  --archive-root=${archive_root} \\" >> ${script_file_to_submit}
 		echo "  --subject=${subject} \\" >> ${script_file_to_submit}
		echo "  --three-t-project=${refproject} \\" >> ${script_file_to_submit}
		echo "  --seven-t-project=${project} \\" >> ${script_file_to_submit}
		echo "  --tmp-dir=${packages_tmp} \\" >> ${script_file_to_submit}
		echo "  --release-notes-template-file=${HOME}/pipeline_tools/xnat_pbs_jobs/7T/CreateStructuralPreprocPackage/StructuralPreprocPackageReleaseNotes.txt \\" >> ${script_file_to_submit}
		echo "  --output-dir=${output_dir} \\" >> ${script_file_to_submit}
		echo "  --create-checksum \\" >> ${script_file_to_submit}

		submit_cmd="qsub ${script_file_to_submit}"
		echo "submit_cmd: ${submit_cmd}"
		
		processing_job_no=`${submit_cmd}`

		echo "processing_job_no: ${processing_job_no}"

	fi

done
