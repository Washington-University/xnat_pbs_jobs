#!/bin/bash

inform()
{
	local msg=${1}
	echo "SubmitGetDataHCP3T.OneSubject.sh: ${msg}"
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
	unset g_build_dir
	unset g_xnat_pbs_jobs
	unset g_log_dir

	# parse command line arguments
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
				inform "ERROR: unrecognized option: ${argument}"
				inform ""
				exit 1
				;;
		esac
	done

	# prompt for values not specified on command line
	if [ -z "${g_project}" ]; then
		printf "Enter Connectome DB Project: "
		read g_project
	fi

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi

	# validate options
	local error_count=0

	if [ -z "${g_project}" ]; then
		inform "ERROR: Connectome DB Project value required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		inform "ERROR: Connectome DB Subject value required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_subject: ${g_subject}"
	fi

	# validate values retrieved from environment variables
	if [ -z "${XNAT_PBS_JOBS_BUILD_DIR}" ]; then
		inform "ERROR: XNAT_PBS_JOBS_BUILD_DIR environment variable must be set"
		error_count=$(( error_count + 1 ))
	else
		g_build_dir=${XNAT_PBS_JOBS_BUILD_DIR}
		inform "g_build_dir: ${g_build_dir}"
	fi

	if [ -z "${XNAT_PBS_JOBS}" ]; then
		inform "ERROR: XNAT_PBS_JOBS environment variable must be set"
		error_count=$(( error_count + 1 ))
	else
		g_xnat_pbs_jobs=${XNAT_PBS_JOBS}
		inform "g_xnat_pbs_jobs: ${g_xnat_pbs_jobs}"
	fi

	if [ -z "${XNAT_PBS_JOBS_LOG_DIR}" ]; then
		inform "ERROR: XNAT_PBS_JOBS_LOG_DIR environment variable must be set"
		error_count=$(( error_count + 1 ))
	else
		g_log_dir=${XNAT_PBS_JOBS_LOG_DIR}
		inform "g_log_dir: ${g_log_dir}"
	fi

	# exit if option errors are detected
	if [ ${error_count} -gt 0 ]; then
		inform "For usage information, use --help"
		exit 1
	fi
}

main() 
{
	get_options $@

	# determine working directory name
	# current_seconds_since_epoch=`date +%s`
	working_directory_name="${g_build_dir}/${g_project}/GetDataHCP3T.${g_subject}"

	# make working directory
	inform "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Submit job to actually do the work
	script_file_to_submit=${working_directory_name}/${g_subject}.GetDataHCP3T.PBS_JOB.sh
	if [ -e "${script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	touch ${script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=12:00:00,vmem=4000mb" >> ${script_file_to_submit}
	echo "#PBS -q HCPput" >> ${script_file_to_submit}
	echo "#PBS -o ${g_log_dir}" >> ${script_file_to_submit}
	echo "#PBS -e ${g_log_dir}" >> ${script_file_to_submit}
	echo "" >> ${script_file_to_submit}
	echo "${g_xnat_pbs_jobs}/GetHcpDataUtils/GetDataHCP3T.sh \\" >> ${script_file_to_submit}
	echo "  --project=${g_project} \\" >> ${script_file_to_submit}
	echo "  --subject=${g_subject} \\" >> ${script_file_to_submit}
	echo "  --working-dir=${working_directory_name} \\" >> ${script_file_to_submit}
	chmod +x ${script_file_to_submit}

	submit_cmd="qsub ${script_file_to_submit}"
	echo "submit_cmd: ${submit_cmd}"
		
	${submit_cmd}
}

# Invoke the main function to get things started
main $@
