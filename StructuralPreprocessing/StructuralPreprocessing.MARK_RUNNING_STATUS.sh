#!/bin/bash
g_script_name=$(basename "${0}")

if [ -z "${XNAT_PBS_JOBS}" ]; then
	echo "${g_script_name}: ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

source "${XNAT_PBS_JOBS}/shlib/log.shlib"
source "${XNAT_PBS_JOBS}/shlib/utils.shlib"
log_Msg "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"

if [ -z "${XNAT_PBS_JOBS_RUNNING_STATUS_DIR}" ]; then
	log_Err_Abort "XNAT_PBS_JOBS_RUNNING_STATUS_DIR environment variable must be set"
else
	log_Msg "XNAT_PBS_JOBS_RUNNING_STATUS_DIR: ${XNAT_PBS_JOBS_RUNNING_STATUS_DIR}"
fi

usage()
{
	cat <<EOF

Mark that Structural Preprocessing is queued/running or no longer queued/running

Usage: ${g_script_name} PARAMETER..."

PARAMETERs are [ ] = optional; < > = user supplied value
  [--help]                   : show usage information and exit with non-zero return code
   --project=<project>       : XNAT project (e.g. HCP_500)
   --subject=<subject>       : XNAT subject ID within project (e.g. 100307)
   --classifier=<classifier> : XNAT session classifier (e.g. 3T, 7T, MR, V1, V2, etc.)
  {
    one of the following must be specified

    --submitted              : all these mean the same thing
	--queued                 :  jobs have been submitted and are either queued up or
    --running                :  running

    --not-running            : all these mean the same thing
    --not-queued             :  jobs are not queued, submitted, running 
    --done                   :  jobs may have completed successfully or not
  }

EOF
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
	unset g_classifier
	unset g_running
	
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
			--classifier=*)
				g_classifier=${argument#*=}
				index=$(( index + 1 ))
				;;
			--submitted)
				g_running="TRUE"
				index=$(( index + 1 ))
				;;
			--queued)
				g_running="TRUE"
				index=$(( index + 1 ))
				;;
			--running)
				g_running="TRUE"
				index=$(( index + 1 ))
				;;
			--not-running)
				g_running="FALSE"
				index=$(( index + 1 ))
				;;
			--not-queued)
				g_running="FALSE"
				index=$(( index + 1 ))
				;;
			--done)
				g_running="FALSE"
				index=$(( index + 1 ))
				;;
			*)
				usage
				log_Err_Abort "unrecognized option ${argument}"
				;;
		esac
	done

	local error_count=0
	
	# check required parameters
	if [ -z "${g_project}" ]; then
		log_Err "project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		log_Err "subject (--subject=) required"
	else
		log_Msg "subject: ${g_subject}"
	fi

	if [ -z "${g_classifier}" ]; then
		log_Err "classifier (--classifier=) required"
	else
		log_Msg "classifier: ${g_classifier}"
	fi

	if [ -z "${g_running}" ]; then
		log_Err "running status must be specified"
	else
		log_Msg "running status: ${g_running}"
	fi
	
	if [ ${error_count} -gt 0 ]; then
		log_Err_Abort "For usage information, use --help"
	fi
}

main()
{
	show_job_start

	show_platform_info

	get_options "$@"

	local directory=${XNAT_PBS_JOBS_RUNNING_STATUS_DIR}/${g_project}
	local file="StructuralPreprocessing.${g_subject}_${g_classifier}.RUNNING"
	local path=${directory}/${file}
	
	if [ "${g_running}" = "TRUE" ]; then
		mkdir -p ${directory}
		touch ${path}
		
	else
		if [ -e "${path}" ]; then
			rm -f ${path}
		fi

	fi

	log_Msg "Complete"
}

# Invoke the main function to get things started
main "$@"
