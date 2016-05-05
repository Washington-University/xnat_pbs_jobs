#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # XNAT_working_dir_put.sh
#
# ## Copyright Notice
#
# Copyright (C) 2015 The Human Connectome Project
#
# * Washington University in St. Louis
# * University of Minnesota
# * Oxford University
#
# ## Author(s)
#
# * Timothy B. Brown, Neuroinformatics Research Group, 
#   Washington University in St. Louis
#
# ## Description
#
# This script pushes data from a working directory into a resource in 
# the ConnectomeDB (db.humanconnectome.org) XNAT database.
#
#~ND~END~

# If any commands exit with a non-zero value, this script exits
set -e

echo "Job started on `hostname` at `date`"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs
echo "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# home directory for scripts to be sourced to setup the environment
SCRIPTS_HOME=/home/HCPpipeline/SCRIPTS
echo "SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=/home/HCPpipeline/pipeline
echo "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# Show script usage information 
usage()
{
    echo ""
    echo "  Push data from a working directory into a resource in the "
	echo "  ConnectomeDB XNAT database."
	echo ""
	echo "  Usage: XNAT_working_dir_put.sh <options>"
	echo ""
	echo "  Options: [ ] = optional, < > = user-supplied-value"
	echo ""
	echo "   [--help] : show usage information and exit"
	echo ""
	echo "    --user=<username>          : XNAT DB username"
	echo "    --password=<password>      : XNAT DB password"
	echo "    --server=<server>          : XNAT server (e.g. db.humanconnectome.org)"
	echo "    --project=<project>        : XNAT project (e.g. HCP_500)"
	echo "    --subject=<subject>        : XNAT subject ID within project (e.g. 100307)"
	echo "    --session=<session>        : XNAT session ID within project (e.g. 100307_3T)"
	echo "   [--scan=<scan>]             : Scan ID (e.g. rfMRI_REST1_LR)"
	echo "    --working-dir=<dir>        : Working directory from which to push data"
	echo "    --resource-suffix=<suffix> : Suffix for resource in which to push data"
	echo "                                 Resource will be named <scan>_<suffix> or"
	echo "                                 simply <suffix> if scan is not specified"
	echo "   [--reason=<reason>]         : Reason for data update (e.g. name of pipeline run)"
	echo ""
}

# Parse specified command line options and verify that required options are
# specified. "Return" the options to use in global variables.
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

	if [ -z "${g_session}" ]; then
		echo "ERROR: session (--session=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_session: ${g_session}"
	fi

	# --scan= is optional
	echo "g_scan: ${g_scan}"

	if [ -z "${g_working_dir}" ]; then
		echo "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_resource_suffix}" ]; then
		echo "ERROR: resource suffix (--resource-suffix=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_resource_suffix: ${g_resource_suffix}"
	fi

	# --reason= is optional and has a default value
	if [ -z "${g_reason}" ]; then
		g_reason="Unspecified"
	fi
	echo "g_reason: ${g_reason}"

	if [ ${error_count} -gt 0 ]; then
		echo "For usage information, use --help"
		exit 1
	fi
}

# Main processing 
main()
{
	get_options $@

	# Determine DB resource name
	echo "-------------------------------------------------"
	echo "Determining DB resource name"
	echo "-------------------------------------------------"
 	if [ ! -z "${g_scan}" ]; then
		resource="${g_scan}_${g_resource_suffix}"
	else
		resource="${g_resource_suffix}"
	fi
	echo "resource: ${resource}"

	# Delete previous resource
	echo "-------------------------------------------------"
	echo "Deleting previous resource"	
	echo "-------------------------------------------------"
	${XNAT_PBS_JOBS_HOME}/WorkingDirPut/DeleteResource.sh \
		--user=${g_user} \
		--password=${g_password} \
		--server=${g_server} \
		--project=${g_project} \
		--subject=${g_subject} \
		--session=${g_session} \
		--resource=${resource} \
		--force
	
	# Make processing job log files readable so they can be pushed into the database
	chmod a+r ${g_working_dir}/*

	# Move resulting files out of the subject-id directory
	echo "-------------------------------------------------"
	echo "Moving resulting files up one level out of the ${g_subject} directory in ${g_working_dir}"
	echo "-------------------------------------------------"
	mv ${g_working_dir}/${g_subject}/* ${g_working_dir}
	rm -rf ${g_working_dir}/${g_subject}

	# Mask password (${g_password})
	files=`find ${g_working_dir} -maxdepth 1 -print`
	for file in ${files} ; do
		${XNAT_PBS_JOBS_HOME}/WorkingDirPut/mask_password --password="${g_password}" --file="${file}" --verbose
	done

	# Push the data into the DB
	db_working_dir=${g_working_dir/HCP/data}
	echo "-------------------------------------------------"
	echo "Putting new data into DB from db_working_dir: ${db_working_dir}"
	echo "-------------------------------------------------"
	${XNAT_PBS_JOBS_HOME}/WorkingDirPut/PutDirIntoResource.sh \
		--user=${g_user} \
		--password=${g_password} \
		--server=${g_server} \
		--project=${g_project} \
		--subject=${g_subject} \
		--session=${g_session} \
		--resource=${resource} \
		--reason=${g_reason} \
		--dir=${db_working_dir} \
		--force

	# Cleanup
	echo "-------------------------------------------------"
	echo "Cleanup"
	echo "-------------------------------------------------"
	echo "Removing g_working_dir: ${g_working_dir}"
	rm -rf ${g_working_dir}
}

# Invoke the main function to get things started
main $@
