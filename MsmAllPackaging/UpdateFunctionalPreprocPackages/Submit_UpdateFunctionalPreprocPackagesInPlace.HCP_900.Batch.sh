#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
    echo "Environment variable SUBJECT_FILES_DIR must be set!"
    exit 1
fi

printf "Delay until first submission (minutes) [0]: "
read delay

if [ -z "${delay}" ]; then
	delay=0
fi

printf "Interval between submissions (minutes) [60]: "
read interval

if [ -z "${interval}" ]; then
	interval=60
fi

project="HCP_900"
packages_root="/HCP/hcpdb/packages/live/HCP_900"
archive_root="/HCP/hcpdb/archive/${project}/arc001"

packages_tmp="/HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp"

scripts_to_submit_dir="/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MsmAllPackaging/scripts_to_submit"
log_dir="/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MsmAllPackaging/logs"

subject_file_name="${SUBJECT_FILES_DIR}/${project}.UpdateFunctionalPreprocPackagesInPlace.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

mkdir -p ${log_dir}
mkdir -p ${scripts_to_submit_dir}

for subject in ${subjects} ; do

    if [[ ${subject} != \#* ]]; then

		current_time_str=`date +%s`
		script_file_to_submit=${scripts_to_submit_dir}/${subject}.UpdateFunctionalPreprocPackagesInPlace.${current_time_str}.PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=08:00:00,vmem=4000mb" >> ${script_file_to_submit}
		echo "#PBS -q HCPput" >> ${script_file_to_submit}
		echo "#PBS -o ${log_dir}" >> ${script_file_to_submit}
        echo "#PBS -e ${log_dir}" >> ${script_file_to_submit}

		echo ""
		echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MsmAllPackaging/UpdateFunctionalPreprocPackages/UpdateFunctionalPreprocPackagesInPlace.sh \\" >> ${script_file_to_submit}
		echo "  --packages-root=${packages_root} \\" >> ${script_file_to_submit}
		echo "  --archive-root=${archive_root} \\" >> ${script_file_to_submit}
		echo "  --tmp-dir=${packages_tmp} \\" >> ${script_file_to_submit}
		echo "  --release-notes-template-file=/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MsmAllPackaging/UpdateFunctionalPreprocPackages/FunctionalPreprocPackageReleaseNotes.txt \\" >> ${script_file_to_submit}
		echo "  --subject=${subject} \\" >> ${script_file_to_submit}
		echo "  --create-checksum \\" >> ${script_file_to_submit}

		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting UpdateFunctionalPreprocPackages job for subject: ${subject}"
		echo " Submission delayed until ${delay} minutes from now"
		echo "--------------------------------------------------------------------------------"

		submit_cmd="qsub ${script_file_to_submit}"
		#echo "submit_cmd: ${submit_cmd}"

		at now + ${delay} minutes <<EOF
${submit_cmd}
EOF
		
		delay=$((delay + interval))
	fi

done
