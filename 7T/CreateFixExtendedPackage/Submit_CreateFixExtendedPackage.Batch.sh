#!/bin/bash
set -e

if [ "${1}" = "run" ]; then
	run="TRUE"
fi

inform()
{
	echo "${g_script_name}: ${1}"
}

g_script_name="Submit_CreateFixExtendedPackage.Batch.sh"
g_name=${g_script_name%.*}
g_subject_file_name="${g_name}.subjects"
g_log_dir="${XNAT_PBS_JOBS_LOG_DIR}/package_logs/CreateFixExtendedPackage"
g_scripts_to_submit_dir="${XNAT_PBS_JOBS_BUILD_DIR}/package_scripts_to_submit/CreateFixExtendedPackage"
g_archive_root="/HCP/hcpdb/archive"
g_packages_tmp="/HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp"

inform "Retrieving subject list from: ${g_subject_file_name}"
g_subject_list_from_file=( $( cat ${g_subject_file_name} ) )
g_subjects="`echo "${g_subject_list_from_file[@]}"`"

#echo ${g_subjects}

mkdir -p ${g_log_dir}
mkdir -p ${g_scripts_to_submit_dir}

for subject_spec in ${g_subjects} ; do

	if [[ ${subject_spec} != \#* ]]; then

		parsing_subject_spec="${subject_spec}"

		project=${parsing_subject_spec%%:*}
		parsing_subject_spec=${parsing_subject_spec#*:}

		refproject=${parsing_subject_spec%%:*}
		parsing_subject_spec=${parsing_subject_spec#*:}
		
		subject=${parsing_subject_spec%%:*}
		parsing_subject_spec=${parsing_subject_spec#*:}

		comments=${parsing_subject_spec}

		g_output_dir="/HCP/hcpdb/packages/prerelease/zip/${project}"

		inform ""
		inform "Submitting package creation job for"
		inform "     Project: ${project}"
		inform "  RefProject: ${refproject}"
		inform "     Subject: ${subject}"

		current_time_str=`date +%s`
		script_file_to_submit=${g_scripts_to_submit_dir}/${subject}-CreateFixExtendedPackage-${current_time_str}.PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=08:00:00,vmem=4000mb" >> ${script_file_to_submit}
		#echo "#PBS -q HCPput" >> ${script_file_to_submit}
		echo "#PBS -o ${g_log_dir}" >> ${script_file_to_submit}
        echo "#PBS -e ${g_log_dir}" >> ${script_file_to_submit}
		echo ""
		echo "${XNAT_PBS_JOBS}/7T/CreateFixExtendedPackage/CreateFixExtendedPackage.sh \\" >> ${script_file_to_submit}
		echo "  --archive-root=${g_archive_root} \\" >> ${script_file_to_submit}
		echo "  --tmp-dir=${g_packages_tmp} \\" >> ${script_file_to_submit}
		echo "  --subject=${subject} \\" >> ${script_file_to_submit}
		echo "  --three-t-project=${refproject} \\" >> ${script_file_to_submit}
		echo "  --seven-t-project=${project} \\" >> ${script_file_to_submit}
		echo "  --release-notes-template-file=${XNAT_PBS_JOBS}/7T/CreateFixExtendedPackage/ReleaseNotes.txt \\" >> ${script_file_to_submit}
		echo "  --output-dir=${g_output_dir} \\" >> ${script_file_to_submit}
		echo "  --create-checksum \\" >> ${script_file_to_submit}
		echo "  --create-contentlist \\" >> ${script_file_to_submit}
		echo "  --dont-overwrite \\" >> ${script_file_to_submit}
		echo "  --ignore-missing-files " >> ${script_file_to_submit}
		echo "" >> ${script_file_to_submit}

		chmod +x ${script_file_to_submit}

		if [ "${run}" = "TRUE" ]; then
			${script_file_to_submit}
		else
			submit_cmd="qsub ${script_file_to_submit}"
			inform "submit_cmd: ${submit_cmd}"
			
			processing_job_no=`${submit_cmd}`
			inform "processing_job_no: ${processing_job_no}"
		fi
		
	fi

done 
