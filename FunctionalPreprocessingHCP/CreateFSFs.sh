#!/bin/bash

# This script's name
SCRIPT_NAME="CreateFSFs.sh"

# Show script usage information
usage()
{
	echo ""
	echo "TBW"
	echo ""
}

# Parse specified command line options and verify that required options are 
# specified. "Return" the options to use in global variables
get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_server
	unset g_working_dir
	unset g_project
	unset g_subject
	unset g_series

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
			--working-dir=*)
				g_working_dir=${argument/*=/""}
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
			--series=*)
				g_series=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				usage
				echo "ERROR: unrecognized option: ${argument}"
				echo ""
				exit 1
				;;
		esac
	done

	local error_count=0

	# check required parameters
	if [ -z "${g_user}" ]; then
		echo "ERROR: user (--user=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		echo "ERROR: password (--password=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_password: *******"
	fi

	if [ -z "${g_server}" ]; then
		echo "ERROR: server (--server=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_server: ${g_server}"
	fi

	if [ -z "${g_working_dir}" ]; then
		echo "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_project}" ]; then
		echo "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		echo "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_subject: ${g_subject}"
	fi

	if [ -z "${g_series}" ]; then
		echo "ERROR: series (--series=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_series: ${g_series}"
	fi

	if [ ${error_count} -gt 0 ]; then
		echo "For usage information, use --help"
		exit 1
	fi
}

main()
{
	get_options $@

	# make sure ${HOME}/bin/dos2unix and ${HOME}/bin/unix2dos can be found
	export PATH="${HOME}/bin:${PATH}"
	echo "${SCRIPT_NAME}: PATH: ${PATH}"

	local create_fsfs_cmd=""
	create_fsfs_cmd+="${NRG_PACKAGES}/tools/HCP/FSF/callCreateFSFs.sh"
	create_fsfs_cmd+=" --host ${g_server}"
	create_fsfs_cmd+=" --user ${g_user}"
	create_fsfs_cmd+=" --pw ${g_password}"
	create_fsfs_cmd+=" --buildDir ${g_working_dir}"
	create_fsfs_cmd+=" --project ${g_project}"
	create_fsfs_cmd+=" --subject ${g_subject}"
	create_fsfs_cmd+=" --series ${g_series}"

	echo "create_fsfs_cmd: ${create_fsfs_cmd}"
	${create_fsfs_cmd}
}

# Invoke the main function to get things started
main $@

