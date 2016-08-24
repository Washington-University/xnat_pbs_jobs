#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
    echo "Environment variable SUBJECT_FILES_DIR must be set!"
    exit 1
fi

project="HCP_900"

# This is a temporary change because the normal packages directory is inaccessible
#packages_root="/HCP/hcpdb/packages/live/${project}"
packages_root="/HCP/hcpdb/build_ssd/chpc/BUILD/temp_packages_dir/${project}"

archive_root="/HCP/hcpdb/archive/${project}/arc001"

#packages_tmp="/HCP/hcpdb/packages/temp"
packages_tmp="/HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp"

# This is a temporary change because the normal packages directory is inaccessible
#output_dir="/HCP/hcpdb/packages/PostMsmAll"
output_dir="/HCP/hcpdb/build_ssd/chpc/BUILD/temp_packages_dir/PostMsmAll"

scripts_to_submit_dir="/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MsmAllPackaging/scripts_to_submit"
log_dir="/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MsmAllPackaging/logs"

subject_file_name="${SUBJECT_FILES_DIR}/${project}.UpdateTaskAnalysisPackages.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

mkdir -p ${log_dir}
mkdir -p ${scripts_to_submit_dir}

for subject in ${subjects} ; do

    if [[ ${subject} != \#* ]]; then

		current_time_str=`date +%s`
		script_file_to_submit=${scripts_to_submit_dir}/${subject}.UpdateTaskAnalysisPackages.${current_time_str}.PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${script_file_to_submit}
		echo "#PBS -q HCPput" >> ${script_file_to_submit}
		echo "#PBS -o ${log_dir}" >> ${script_file_to_submit}
        echo "#PBS -e ${log_dir}" >> ${script_file_to_submit}

		echo ""
		echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MsmAllPackaging/UpdateTaskAnalysisPackages/UpdateTaskAnalysisPackages.sh \\" >> ${script_file_to_submit}
		echo "  --packages-root=${packages_root} \\" >> ${script_file_to_submit}
		echo "  --archive-root=${archive_root} \\" >> ${script_file_to_submit}
		echo "  --tmp-dir=${packages_tmp} \\" >> ${script_file_to_submit}
		echo "  --release-notes-template-file=/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MsmAllPackaging/UpdateTaskAnalysisPackages/TaskAnalysiPackageReleaseNotes.txt \\" >> ${script_file_to_submit}
		echo "  --output-dir=${output_dir}/${project} \\" >> ${script_file_to_submit}
		echo "  --subject=${subject} \\" >> ${script_file_to_submit}
		echo "  --create-checksum \\" >> ${script_file_to_submit}

		submit_cmd="qsub ${script_file_to_submit}"
		echo "submit_cmd: ${submit_cmd}"
		
		processing_job_no=`${submit_cmd}`

		echo "processing_job_no: ${processing_job_no}"

	fi

done
