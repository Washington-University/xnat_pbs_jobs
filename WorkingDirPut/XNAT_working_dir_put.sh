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
	echo "    --scan=<scan>              : Scan ID (e.g. rfMRI_REST1_LR)"
	echo "    --working-dir=<dir>        : Working directory from which to push data"
	echo "    --resource-suffix=<suffix> : Suffix for resource in which to push data"
	echo "                                 Resource will be named <scan>_<suffix>"
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

	if [ -z "${g_scan}" ]; then
		echo "ERROR: scan (--scan=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_scan: ${g_scan}"
	fi

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

	if [ ${error_count} -gt 0 ]; then
		echo "For usage information, use --help"
		exit 1
	fi
}

# Main processing 
main()
{
	get_options $@
	
	# Set up to run Python
	echo "-------------------------------------------------"
	echo "Setting up to run Python"
	echo "-------------------------------------------------"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	# Get XNAT Session ID (a.k.a. the experiment ID, e.g ConnectomeDB_E1234)
	echo "-------------------------------------------------"
	echo "Getting XNAT Session ID"
	echo "-------------------------------------------------"
	get_session_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=db.humanconnectome.org --username=${g_user} --password=${g_password} --project=${g_project} --subject=${g_subject} --session=${g_session}"
	echo "get_session_id_cmd: ${get_session_id_cmd}"
	sessionID=`${get_session_id_cmd}`
	echo "XNAT session ID: ${sessionID}"

	# Delete any previous resource
	echo "-------------------------------------------------"
	echo "Deleting previous resource"	
	echo "-------------------------------------------------"
	java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar \
		-u ${g_user} -p ${g_password} -m DELETE \
		-r http://${g_server}/REST/projects/${g_project}/subjects/${g_subject}/experiments/${sessionID}/resources/${g_scan}_${g_resource_suffix}/

	# Make processing job log files readable so they can be pushed into the database
	chmod a+r ${g_working_dir}/*

	# Move resulting files out of the subject-id directory
	echo "-------------------------------------------------"
	echo "Moving resulting files up one level out of the ${g_subject} directory in ${g_working_dir}"
	echo "-------------------------------------------------"
	mv ${g_working_dir}/${g_subject}/* ${g_working_dir}
	mv ${g_working_dir}/${g_subject}/.* ${g_working_dir}

	rm -rf ${g_working_dir}/${g_subject}

	# Push the data into the DB
	db_working_dir=${g_working_dir/HCP/data}
	echo "-------------------------------------------------"
	echo "Putting new data into DB from db_working_dir: ${db_working_dir}"
	echo "-------------------------------------------------"
	java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar \
		-u ${g_user} -p ${g_password} -m PUT \
		-r http://${g_server}/REST/projects/${g_project}/subjects/${g_subject}/experiments/${sessionID}/resources/${g_scan}_${g_resource_suffix}/files?overwrite=true\&replace=true\&event_reason=RestingStateStatsPipeline\&reference=${db_working_dir}
	
	# Cleanup
	echo "-------------------------------------------------"
	echo "Cleanup"
	echo "-------------------------------------------------"
	echo "Removing g_working_dir: ${g_working_dir}"
	rm -rf ${g_working_dir}
}

# Invoke the main function to get things started
main $@
