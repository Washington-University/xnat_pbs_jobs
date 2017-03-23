#!/bin/bash
set -e

if [ -z "${XNAT_PBS_JOBS}" ]; then
	script_name=$(basename "${0}")
	echo "${script_name}: ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

source ${XNAT_PBS_JOBS}/shlib/log.shlib # Logging related functions
log_Msg "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"

get_options() 
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_server
	unset g_project
	unset g_subject

	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--user=*)
				g_user=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--password=*)
				g_password=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--server=*)
				g_server=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--project=*)
				g_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				log_Err_Abort "unrecognized option: ${argument}"
				;;
		esac
	done

	# set defaults and prompt for some unspecified parameters
	if [ -z "${g_user}" ]; then
		printf "Enter Connectome DB Username: "
		read g_user
	fi
	log_Msg "Connectome DB User: ${g_user}"
	
	if [ -z "${g_password}" ]; then
		stty -echo
		printf "Enter Connectome DB Password: "
		read g_password
		echo ""
		stty echo
	fi
	log_Msg "Connectome DB Password: ****password mask****"
	
	if [ -z "${g_server}" ]; then
		g_server="db.humanconnectome.org"
	fi
	log_Msg "Connectome DB Server: ${g_server}"

	if [ -z "${g_project}" ]; then
		g_project="HCP_500"
	fi
    log_Msg "Connectome DB Project: ${g_project}"

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi
	log_Msg "Connectome DB Subject: ${g_subject}"
}


main()
{
	get_options $@

	# Figure Out/Specify what scans should be grouped together 



}

main $@

