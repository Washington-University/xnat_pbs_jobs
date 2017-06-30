#!/bin/bash

g_script_name="ApplyHandReclassification.XNAT.sh"
g_pipeline_name="ApplyHandReClassification"

inform()
{
	local msg=${1}
	echo "${g_script_name}: ${msg}"
}

# check required environment variables
if [ -z "${XNAT_PBS_JOBS}" ]; then
	inform "ERROR: XNAT_PBS_JOBS environment variable must be set"
	exit 1
else
	g_xnat_pbs_jobs=${XNAT_PBS_JOBS}
	inform "g_xnat_pbs_jobs: ${g_xnat_pbs_jobs}"
fi

usage()
{
	cat << EOF

Run the HCP ApplyHandReClassifications.sh pipeline script for a subject

Usage: ${SCRIPT_NAME} PARAMETER..."

PARAMETERs are [ ] = optional; < > = user supplied value
  [--help]                 : show usage information and exit with non-zero return code
   --user=<username>       : XNAT DB username
   --password=<password>   : XNAT DB password
   --server=<server>       : XNAT server (e.g. ${XNAT_PBS_JOBS_XNAT_SERVER})
   --project=<project>     : XNAT project (e.g. HCP_Staging_7T)
   --subject=<subject>     : XNAT subject ID within project (e.g. 102311)
   --session=<session>     : XNAT session ID within project (e.g. 102311_7T)
   --scan=<scan>           : Scan ID (e.g. rfMRI_REST1_PA)
   --working-dir=<dir>     : Working directory in which to place retrieved data
                             and in which to produce results
   --setup-script=<script> : Script to source to set up environment

EOF
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_server
	unset g_project
	unset g_subject
	unset g_session
	unset g_scan
	unset g_working_dir
	unset g_setup_script

	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--help)
				usage
				exit 1
				;;
			--user=*)
				g_user=${argument#*=}
				index=$(( index + 1 ))
				;;
			--password=*)
				g_password=${argument#*=}
				index=$(( index + 1 ))
				;;
			--server=*)
				g_server=${argument#*=}
				index=$(( index + 1 ))
				;;
			--project=*)
				g_project=${argument#*=}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument#*=}
				index=$(( index + 1 ))
				;;
			--session=*)
				g_session=${argument#*=}
				index=$(( index + 1 ))
				;;
			--scan=*)
				g_scan=${argument#*=}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument#*=}
				index=$(( index + 1 ))
				;;
			--setup-script=*)
				g_setup_script=${argument#*=}
				index=$(( index + 1 ))
				;;
			*)
				usage
				inform "ERROR: unrecognized option ${argument}"
				exit 1
				;;		
		esac

	done

	local error_msgs=""

	# check required parameters
	if [ -z "${g_user}" ]; then
		error_msgs+="\nERROR: user (--user=) required"
	else
		inform "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		error_msgs+="\nERROR: password (--password=) required"
	else
		inform "g_password: ***** password mask *****"
	fi

	if [ -z "${g_server}" ]; then
		error_msgs+="\nERROR: server (--server=) required"
	else
		inform "g_server: ${g_server}"
	fi

	if [ -z "${g_project}" ]; then
		error_msgs+="\nERROR: project (--project=) required"
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		error_msgs+="\nERROR: subject (--subject=) required"
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		error_msgs+="\nERROR: session (--session=) required"
	else
		inform "g_session: ${g_session}"
	fi

	if [ -z "${g_scan}" ]; then
		error_msgs+="\nERROR: scan (--scan=) required"
	else
		inform "g_scan: ${g_scan}"
	fi

	if [ -z "${g_working_dir}" ]; then
		error_msgs+="\nERROR: working directory (--working-dir=) required"
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_setup_script}" ]; then
		error_msgs+="\nERROR: set up script (--setup-script=) required"
	else
		inform "g_setup_script: ${g_setup_script}"
	fi

	if [ ! -z "${error_msgs}" ]; then
		usage
		echo -e ${error_msgs}
		exit 1
	fi
}

die()
{
	inform "Dying"
	exit 1
}

main()
{
	inform "Job started on `hostname` at `date`"

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	get_options $@

	# Create a start_time file
	inform "Create a start time file"
	start_time_file=${g_working_dir}/${g_pipeline_name}.starttime
	if [ -e "${start_time_file}" ]; then
		inform "Removing old ${start_time_file}"
		rm -f ${start_time_file}
	fi

	# Sleep for 1 minute to make sure start time file is created at least a
	# minute after any files retrieved in the "get data" job
	inform "Sleep for 1 minute before creating start time file."
	sleep 1m || die

	# Create start time file
	inform "Creating start time file: ${start_time_file}"
	touch ${start_time_file} || die
	ls -l ${start_time_file}

	# Sleep for 1 minute to make sure any files created or modified by the scripts
	# are created at least 1 minute after the start time file
	inform "Sleep for 1 minute after creating start time file."
	sleep 1m || die

	# Source set up script
	if [ -e ${g_setup_script} ]; then
		source ${g_setup_script}
	else
		inform "Set up script: ${g_setup_script} DOES NOT EXIST"
		die
	fi

	# Run ApplyHandReClassifications.sh script

	inform "HCPPIPEDIR: ${HCPPIPEDIR}"

	cmd=${HCPPIPEDIR}/ApplyHandReClassifications/ApplyHandReClassifications.sh 
	cmd+=" --path=${g_working_dir}"
	cmd+=" --subject=${g_subject}"
	cmd+=" --fmri-name=${g_scan}"
	cmd+=" --high-pass=2000"

	inform "About to issue the following cmd"
	inform "${cmd}"

	${cmd}
	return_code=$?
	if [ ${return_code} -ne 0 ]; then
		die
 	fi

	inform "Complete"
}

# Invoke the main to get things started
main $@
