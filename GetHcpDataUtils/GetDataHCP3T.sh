#!/bin/bash

inform()
{
	local msg=${1}
	echo "GetDataHCP3T.sh: ${msg}"
}

usage()
{
	inform "usage: TBW"
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
	unset g_working_dir
	unset g_xnat_pbs_jobs

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
				inform "ERROR: unrecognized option: ${argument}"
				inform ""
				exit 1
				;;
		esac
	done

	local error_count=0

	if [ -z "${g_project}" ]; then
		inform "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		inform "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_working_dir}" ]; then
		inform "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${XNAT_PBS_JOBS}" ]; then
		inform "ERROR: XNAT_PBS_JOBS environment variable must be set"
		error_count=$(( error_count + 1 ))
	else
		g_xnat_pbs_jobs=${XNAT_PBS_JOBS}
		inform "g_xnat_pbs_jobs: ${g_xnat_pbs_jobs}"
	fi

	if [ ${error_count} -gt 0 ]; then
		inform "For usage information, use --help"
		exit 1
	fi
}

if [ -z "${XNAT_PBS_JOBS}" ]; then
	inform "XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

source ${XNAT_PBS_JOBS}/shlib/utils.shlib

main()
{
	get_options $@

	inform "Setting up to run Python 3"
	set_g_python_environment
	source activate ${g_python_environment}

	inform "Getting CinaB-Style data"
	${g_xnat_pbs_jobs}/lib/hcp/hcp3t/get_cinab_style_data.py \
		--project=${g_project} \
		--subject=${g_subject} \
		--study-dir=${g_working_dir} \
		--copy \
		--phase=full
}

# Invoke the main function to get things started
main $@
