#!/bin/bash

g_pipeline_name="MultiRunICAFIX"

if [ -z "${XNAT_PBS_JOBS}" ]; then
	script_name=$(basename "${0}")
	echo "${script_name}: ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

source "${XNAT_PBS_JOBS}/shlib/log.shlib"  # Logging related functions
source "${XNAT_PBS_JOBS}/shlib/utils.shlib"  # Utility functions
log_Msg "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"

usage()
{
	cat <<EOF

Run the HCP MultiRunICAFIX pipeline

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
	unset g_working_dir
	unset g_setup_script
	g_groups=""
	g_concat_names=""
	unset g_group_count
	
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
			--working-dir=*)
				g_working_dir=${argument#*=}
				index=$(( index + 1 ))
				;;
			--setup-script=*)
				g_setup_script=${argument#*=}
				index=$(( index + 1 ))
				;;
			--group=*)
				a_group=${argument#*=}
				if [ -z "${g_groups}" ]; then
					g_groups="${a_group}"
				else
					g_groups+=" ${a_group}"
				fi
				index=$(( index + 1 ))
				;;
			--concat-name=*)
				a_concat_name=${argument#*=}
				if [ -z "${g_concat_names}" ]; then
					g_concat_names="${a_concat_name}"
				else
					g_concat_names+=" ${a_concat_name}"
				fi
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
		error_msgs+="\nERROR: user (--user=) required"
	else
		log_Msg "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		error_msgs+="\nERROR: password (--password=) required"
	else
		log_Msg "g_password: ***** password mask *****"
	fi

	if [ -z "${g_server}" ]; then
		error_msgs+="\nERROR: server (--server=) required"
	else
		log_Msg "g_server: ${g_server}"
	fi

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

	if [ -z "${g_session}" ]; then
		error_msgs+="\nERROR: session (--session=) required"
	else
		log_Msg "g_session: ${g_session}"
	fi

	if [ -z "${g_working_dir}" ]; then
		error_msgs+="\nERROR: working directory (--working-dir=) required"
	else
		log_Msg "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_setup_script}" ]; then
		error_msgs+="\nERROR: set up script (--setup-script=) required"
	else
		log_Msg "g_setup_script: ${g_setup_script}"
	fi

	if [ -z "${g_groups}" ]; then
		error_msgs+="\nERROR: at least one group (--group=) required"
	else
		log_Msg "g_groups: ${g_groups}"
	fi
	
	if [ -z "${g_concat_names}" ]; then
		error_msgs+="\nERROR: at least one concat name (--concat-name=) required"
	else
		log_Msg "g_concat_names: ${g_concat_names}"
	fi

	g_groups=( $g_groups )
	g_group_count=${#g_groups[@]}
	
	g_concat_names=( $g_concat_names )
	local concat_name_count=${#g_concat_names[@]}

	if [ ${g_group_count} -ne ${concat_name_count} ]; then
		error_msgs+="\nERROR: number of groups specified must equal number of concat names specified"
	else
		log_Msg "group count: ${g_group_count}"
		log_Msg "concat names count: ${concat_name_count}"
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

	create_start_time_file ${g_working_dir} ${g_pipeline_name}

	source_script ${g_setup_script}

	source_script ${XNAT_PBS_JOBS}/ToolSetupScripts/epd-python_setup.sh

	export FSL_FIXDIR=${ICAFIX}
	log_Msg "FSL_FIXDIR: ${FSL_FIXDIR}"
	
	local index=0
	while [ ${index} -lt ${g_group_count} ]; do
		fMRI_names=${g_groups[index]}
		concat_name=${g_concat_names[index]}

		fMRI_names=${fMRI_names//@/ }

		files=""
		for fMRI_name in ${fMRI_names} ; do
			if [ -z "${files}" ]; then
				files=${g_working_dir}/${g_subject}/MNINonLinear/Results/${fMRI_name}/${fMRI_name}.nii.gz
			else
				files=${files}@${g_working_dir}/${g_subject}/MNINonLinear/Results/${fMRI_name}/${fMRI_name}.nii.gz
			fi
		done

		log_Msg "files: ${files}"
		log_Msg "concat_name: ${concat_name}"
		
		# Run the hcp_fix_multi_run script
		cmd="${HCPPIPEDIR}/ICAFIX/hcp_fix_multi_run"
		cmd+=" ${files}"
		cmd+=" 2000"
		cmd+=" ${concat_name}"

		log_Msg "About to issue the following command"
		log_Msg "${cmd}"

		${cmd}
		return_code=$?
		if [ ${return_code} -ne 0 ]; then
			log_Err_Abort "hcp_fix_multi_run non-zero return code: ${return_code}"
		fi
		
		index=$(( index + 1 ))
	done
	
	log_Msg "Complete"
}

# Invoke the main to get things started
main "$@"
