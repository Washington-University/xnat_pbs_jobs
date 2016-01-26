#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
    echo "Environment variable SUBJECT_FILES_DIR must be set!"
    exit 1
fi

project="HCP_900"

subject_file_name="${SUBJECT_FILES_DIR}/${project}.CorrectTaskAnalysisPackages.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

log_dir="/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/correct_task_analysis_packages/logs"

mkdir -p ${log_dir}

for subject in ${subjects} ; do

    if [[ ${subject} != \#* ]]; then

		current_time_str=`date +%s`
		script_file_to_submit=${log_dir}/${subject}.CorrectTaskAnalysisPackages.${current_time_str}.PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${script_file_to_submit}
		echo "#PBS -q HCPput" >> ${script_file_to_submit}
		echo "#PBS -o ${log_dir}" >> ${script_file_to_submit}
        echo "#PBS -e ${log_dir}" >> ${script_file_to_submit}

		echo ""
		echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/correct_task_analysis_packages/correct_task_analysis_packages.sh \\" >> ${script_file_to_submit}
		echo "  --project=${project} \\" >> ${script_file_to_submit}
		echo "  --subject=${subject} \\" >> ${script_file_to_submit}

		submit_cmd="qsub ${script_file_to_submit}"
		echo "submit_cmd: ${submit_cmd}"
		
		processing_job_no=`${submit_cmd}`

		echo "processing_job_no: ${processing_job_no}"

	fi

done
