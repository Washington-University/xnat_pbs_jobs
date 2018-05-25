#!/bin/bash
set -e
g_script_name=$(basename "${0}")

if [ -z "${XNAT_PBS_JOBS}" ]; then
	echo "${g_script_name}: ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

source "${XNAT_PBS_JOBS}/shlib/log.shlib"  # Logging related functions
source "${XNAT_PBS_JOBS}/shlib/utils.shlib"  # Utility functions
log_Msg "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"

usage()
{
	cat <<EOF

Get data from the XNAT archive necessary to run the DeDriftAndResample pipeline script

Usage: ${g_script_name} PARAMETER..."

PARAMETERs are [ ] = optional; < > = user supplied value
  [--help]                 : show usage information and exit with non-zero return code
   --project=<project>     : XNAT project (e.g. HCP_500)
   --subject=<subject>     : XNAT subject ID within project (e.g. 100307)
   --working-dir=<dir>     : Working directory in which to place retrieved data
                             and in which to produce results

EOF
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
	unset g_working_dir

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
			--project=*)
				g_project=${argument#*=}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument#*=}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument#*=}
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
	if [ -z "${g_project}" ]; then
		error_msgs+="\nERROR: project (--project=) required"
	else
		log_Msg "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		error_msgs+="\nERROR: subject (--subject=) required"
	else
		log_Msg "g_subject: ${g_subject}"
	fi

	if [ -z "${g_working_dir}" ]; then
		error_msgs+="\nERROR: working directory (--working-dir=) required"
	else
		log_Msg "g_working_dir: ${g_working_dir}"
	fi

	# check required environment variables
	if [ -z "${XNAT_PBS_JOBS}" ]; then
		error_msgs+="\nERROR: XNAT_PBS_JOBS environment variable must be set"
	else
		g_xnat_pbs_jobs=${XNAT_PBS_JOBS}
		log_Msg "g_xnat_pbs_jobs: ${g_xnat_pbs_jobs}"
	fi
	
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

	# Link CinaB-style data
	log_Msg "Activating Python 3"
	set_g_python_environment
	source activate ${g_python_environment} 2>&1

	mkdir -p ${g_working_dir}/tmp
	
	log_Msg "Getting CinaB-Style data"
	${g_xnat_pbs_jobs}/lib/ccf/get_cinab_style_data.py \
		--project=${g_project} \
		--subject=${g_subject} \
		--study-dir=${g_working_dir}/tmp \
		--phase=dedriftandresample_prereqs \
		--remove-non-subdirs
	
	mv ${g_working_dir}/tmp/* ${g_working_dir}
	rmdir ${g_working_dir}/tmp
	
	log_Msg "Complete"
}

# Invoke the main to get things started
main "$@"
