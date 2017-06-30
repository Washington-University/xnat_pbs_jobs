#!/bin/bash

# If any commands exit with a non-zero value, this script exits
set -e

SCRIPT_NAME=`basename ${0}`

inform() 
{
	msg=${1}
	echo "${SCRIPT_NAME} | ${msg}"
}

inform "Job stared on `hostname` at `date`"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${HOME}/pipeline_tools/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

usage()
{
	inform ""
	inform "  Push files from a working directory into a resource in the  "
	inform "  ConnectomeDB XNAT database. Do not replace or overwrite the "
	inform "  entire specified resource. Instead simply place the files   "
	inform "  in the working directory in the existing resource. The files"
	inform "  will overwrite any existing files with the same path.       "
	inform ""
	inform "  Usage: ${SCRIPT_NAME} <options>"
	inform ""
	inform "  Options: [ ] = optional, < > = user-supplied-value"
	inform ""
	inform "   [--help] : show this usage information and exit"
	inform ""
	inform "    --user=<username>          : XNAT DB username"
	inform "    --password=<password>      : XNAT DB password"
	inform "    --server=<server>          : XNAT server (e.g. ${XNAT_PBS_JOBS_XNAT_SERVER})"
	inform "    --project=<project>        : XNAT project (e.g. HCP_500)"
	inform "    --subject=<subject>        : XNAT subject ID within project (e.g. 100307)"
	inform "    --session=<session>        : XNAT session ID within project (e.g. 100307_3T)"
	inform "   [--scan=<scan>]             : Scan ID (e.g. rfMRI_REST1_LR)"
	inform "    --working-dir=<dir>        : Working directory from which to push data"
	inform "    --resource-suffix=<suffix> : Suffix for resource in which to push data"
	inform "                                 Resource will be named <scan>_<suffix> or"
	inform "                                 simply <suffix> if scan is not specified"
	inform "   [--reason=<reason>]         : Reason for data update (e.g. name of pipeline run)"
	inform ""
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
	unset g_resource_suffix
	unset g_reason

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
			--project=*)
				g_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--session=*)
				g_session=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--scan=*)
				g_scan=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--resource-suffix=*)
				g_resource_suffix=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--reason=*)
				g_reason=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				usage
				inform ""
				inform "ERROR: unrecognized option: ${argument}"
				inform ""
				exit 1
				;;
		esac

	done

	# check required parameters
	local error_count=0

	if [ -z "${g_user}" ]; then
		inform "ERROR: user (--user=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		inform "ERROR: password (--password=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "password: *******"
	fi

	if [ -z "${g_server}" ]; then
		inform "ERROR: server (--server=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "server: ${g_server}"
	fi

	if [ -z "${g_project}" ]; then
		inform "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		inform "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		inform "ERROR: session (--session=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "session: ${g_session}"
	fi

	# --scan= is optional
	if [ ! -z "${g_scan}" ]; then
		inform "scan: ${g_scan}"
	fi

	if [ -z "${g_working_dir}" ]; then
		inform "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "working directory: ${g_working_dir}"
	fi

	if [ -z "${g_resource_suffix}" ]; then
		inform "ERROR: resource suffix (--resource-suffix=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "resource suffix: ${g_resource_suffix}"
	fi

	# --reason= is optional and has a default value
	if [ -z "${g_reason}" ]; then
		g_reason="Unspecified"
	fi
	inform "g_reason: ${g_reason}"

	if [ ${error_count} -gt 0 ]; then
		inform "For usage information, use --help"
		exit 1
	fi
}

main()
{
	get_options $@

	inform "Determining database resource name"
	local resource=""

	if [ ! -z "${g_scan}" ]; then
		resource="${g_scan}_${g_resource_suffix}"
	else
		resource="${g_resource_suffix}"
	fi
	inform "resource name: ${resource}"

	# Make log files readable so they can be pushed into the database
	chmod --recursive a+r ${g_working_dir}/*

	# Move resulting files out of the subject-id subdirectory
	inform "Moving files out of the ${g_subject} subdirectory in ${g_working_dir}"
	mv ${g_working_dir}/${g_subject}/* ${g_working_dir}
	rm -rf ${g_working_dir}/${g_subject}

	# Mask password
	local files=`find ${g_working_dir} -maxdepth 1 -print`
	for file in ${files} ; do
		${XNAT_PBS_JOBS_HOME}/WorkingDirPut/mask_password.sh --password="${g_password}" --file="${file}" --verbose
	done

	# Push files into the DB
	#db_working_dir=${g_working_dir/HCP/data}
	#inform "Putting files into DB from db_working_dir: ${db_working_dir}"

	files=`find ${g_working_dir} -print`

	for file in ${files} ; do

		if [ -f ${file} ]; then 
			# file is a "regular" file (not a directory or device file)

			relative_file_name=${file##${g_working_dir}/}
			
			if [ ! -z "${relative_file_name}" ] ; then
				inform "Putting file: ${relative_file_name} into DB resource: ${resource}"

				db_file=${file/HCP/data}

				${XNAT_PBS_JOBS_HOME}/WorkingDirPut/PutFileIntoResource.sh \
					--user=${g_user} \
					--password=${g_password} \
					--project=${g_project} \
					--subject=${g_subject} \
					--session=${g_session} \
					--resource=${resource} \
					--file=${db_file} \
					--file-path-within-resource=${relative_file_name} \
					--reason=${g_reason} \
					--force

			fi
		fi

	done

	inform "Cleanup"
	inform "Removing working dir: ${g_working_dir}"
	rm -rf ${g_working_dir}
}

# Invoke the main function to get things started
main $@
