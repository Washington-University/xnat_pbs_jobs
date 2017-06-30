#!/bin/bash

g_pipeline_name="ReApplyFix"

if [ -z "${XNAT_PBS_JOBS}" ]; then
	local script_name=$(basename "${0}")
	echo "${script_name}: ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi
 
source "${XNAT_PBS_JOBS}/shlib/log.shlib"  # Logging related functions
source "${XNAT_PBS_JOBS}/shlib/utils.shlib"  # Utility functions
log_Msg "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"

usage()
{
	local script_name=$(basename "${0}")
	cat << EOF

Run the HCP ReApplyFix.sh pipeline script for a subject

Usage: ${script_name} PARAMETER..."

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
  [--reg-name=reg_name]    : Name of registration upon which to work
   
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
    unset g_reg_name

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
			--reg-name=*)
				g_reg_name=${argument#*=}
				index=$(( index + 1 ))
				;;
			*)
				usage
				log_Err_Abort "unrecognized option ${argument}"
				;;		
		esac

	done

	local error_msgs=""

	# check required parameters
	if [ -z "${g_user}" ]; then
		error_msgs+="\n user (--user=) required"
	else
		log_Msg "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		error_msgs+="\n password (--password=) required"
	else
		log_Msg "g_password: ***** password mask *****"
	fi

	if [ -z "${g_server}" ]; then
		error_msgs+="\n server (--server=) required"
	else
		log_Msg "g_server: ${g_server}"
	fi

	if [ -z "${g_project}" ]; then
		error_msgs+="\n project (--project=) required"
	else
		log_Msg "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		error_msgs+="\n subject (--subject=) required"
	else
		log_Msg "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		error_msgs+="\n session (--session=) required"
	else
		log_Msg "g_session: ${g_session}"
	fi

	if [ -z "${g_scan}" ]; then
		error_msgs+="\n scan (--scan=) required"
	else
		log_Msg "g_scan: ${g_scan}"
	fi

	if [ -z "${g_working_dir}" ]; then
		error_msgs+="\n: working directory (--working-dir=) required"
	else
		log_Msg "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_setup_script}" ]; then
		error_msgs+="\n set up script (--setup-script=) required"
	else
		log_Msg "g_setup_script: ${g_setup_script}"
	fi

	log_Msg "g_reg_name: ${g_reg_name}"

	if [ ! -z "${error_msgs}" ]; then
		usage
		log_Err_Abort ${error_msgs}
	fi
}

main()
{
	show_job_start
	
	show_platform_info
	
	get_options "$@"

	create_start_time_file ${g_working_dir} ${g_pipeline_name}	

	source_script ${g_setup_script}

	# Run ReApplyFix.sh script

	log_Msg "HCPPIPEDIR: ${HCPPIPEDIR}"

	cmd=${HCPPIPEDIR}/ReApplyFix/ReApplyFixPipeline.sh
	cmd+=" --path=${g_working_dir}"
	cmd+=" --subject=${g_subject}"
	cmd+=" --fmri-name=${g_scan}"
	cmd+=" --high-pass=2000"

	if [ ! -z "${g_reg_name}" ] ; then 
		cmd+=" --reg-name=${g_reg_name}"
	else
		cmd+=" --reg-name=NONE"
	fi
	cmd+=" --low-res-mesh=32"
	cmd+=" --matlab-run-mode=0"

	log_Msg "About to issue the following cmd"
	log_Msg "${cmd}"

	${cmd}
	return_code=$?
	if [ ${return_code} -ne 0 ]; then
		log_Err_Abort "ReApplyFixPipeline.sh non-zero return code: ${return_code}"
 	fi

	log_Msg "Complete"
}

# Invoke the main to get things started
main "$@"
