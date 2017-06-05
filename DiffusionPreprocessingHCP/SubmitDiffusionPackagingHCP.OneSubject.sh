#!/bin/bash

# main build directory
BUILD_HOME="/HCP/hcpdb/build_ssd/chpc/BUILD"
echo "BUILD_HOME: ${BUILD_HOME}"

get_options() 
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject

	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--project=*)
				g_project=${argument#*=}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument#*=}
				index=$(( index + 1 ))
				;;
			*)
				echo "ERROR: unrecognized option: ${argument}"
				echo ""
				exit 1
				;;
		esac
	done

	# set defaults and prompt for some unspecified parameters
	if [ -z "${g_project}" ]; then
		g_project="HCP_500"
	fi
    echo "Connectome DB Project: ${g_project}"

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi
	echo "Connectome DB Subject: ${g_subject}"
}

main()
{
	get_options $@

	current_seconds_since_epoch=`date +%s`
	working_directory_name="${BUILD_HOME}/${g_project}/DiffusionPackagingHCP.${g_subject}.${current_seconds_since_epoch}"
	destination_root=${PACKAGES_ROOT}/prerelease/zip/${g_project}

	# Make the working directory
	echo "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Submit job to actually do the work
	script_file_to_submit=${working_directory_name}/${g_subject}.DiffusionPackagingHCP.XNAT_PBS_job.sh
	if [ -e "${script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	touch ${script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${script_file_to_submit}
	echo "#PBS -q HCPput" >> ${script_file_to_submit}
	echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${script_file_to_submit}
	echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${script_file_to_submit}
	echo "" >> ${script_file_to_submit}
	echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/DiffusionPackagingHCP.sh \\" >> ${script_file_to_submit}
	echo "  --project=${g_project} \\" >> ${script_file_to_submit}
	echo "  --subject=${g_subject} \\" >> ${script_file_to_submit}
	echo "  --working-dir=${working_directory_name} \\" >> ${script_file_to_submit}
	echo "  --dest-root=${destination_root} " >> ${script_file_to_submit}

	chmod +x ${script_file_to_submit}

	submit_cmd="qsub ${script_file_to_submit}"
	echo "submit_cmd: ${submit_cmd}"
		
	${submit_cmd}
}

# Invoke the main function to get things started
main $@
