#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # RestingStateStatsHCP7T.XNAT.sh
#
# ## Copyright Notice
#
# Copyright (C) 2016 The Human Connectome Project
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
# This script runs the RestingStatStats pipeline script from the 
# Human Connectome Project for a HCP7T subject.
#
# The script is run not as an XNAT pipeline (under the control of the 
# XNAT Pipeline Engine), but in an "XNAT-aware" and "pipeline-like" manner.
#
# The data to be processed is retrieved via filesystem operations instead
# of using REST API calls to retrieve that data. So the database archive
# and resource directory structure is "known and used" by this script.
#
# This script can be invoked by a job submitted to a worker or execution
# node in a cluster, e.g. a Sun Grid Engine (SGE) managed or Portable Batch
# System (PBS) managed cluster. Alternatively, if the machine being used
# has adequate resources (RAM, CPU powere, storage space), this script can
# simply be invoked interactively.
#
#~ND~END~

PIPELINE_NAME="RestingStateStatsHCP7T"
SCRIPT_NAME="RestingStateStatsHCP7T.XNAT.sh"
XNAT_UTILS_HOME="${HOME}/pipeline_tools/xnat_utilities"

inform() 
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

usage()
{
	cat << EOF

Run the HCP RestingStateStats.sh pipeline script for an HCP 7T
subject in an XNAT-aware and XNAT-pipeline-like manner.

Usage: ${SCRIPT_NAME} PARAMETER..."

PARAMETERs are [ ] = optional; < > = user supplied value
  [--help]               : show usage information and exit with non-zero return code
   --user=<username>     : XNAT DB username
   --password=<password> : XNAT DB password
   --server=<server>     : XNAT server (e.g. db.humanconnectome.org)
   --project=<project>   : XNAT project (e.g. HCP_Staging_7T)
   --subject=<subject>   : XNAT subject ID within project (e.g. 102311)
   --session=<session>   : XNAT session ID within project (e.g. 102311_7T)
   --scan=<scan>         : Scan ID (e.g. rfMRI_REST1_PA)
   --working-dir=<dir>   : Working directory in which to place retrieved data
                           and in which to produce results
   --workflow-id=<id>    : XNAT Workflow ID to update as steps are completed
 
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
	unset g_workflow_id

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
			--workflow-id=*)
				g_workflow_id=${argument#*=}
				index=$(( index + 1 ))
				;;
			*)
				usage
				inform "ERROR: unrecognized option ${argument}"
				exit 1
				;;		
		esac

	done

	local error_msgs=""

	# check required parameters
	if [ -z "${g_user}" ]; then
		error_msgs+="\nERROR: user (--user=) required"
	else
		inform "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		error_msgs+="\nERROR: password (--password=) required"
	else
		inform "g_password: ***** password mask *****"
	fi

	if [ -z "${g_server}" ]; then
		error_msgs+="\nERROR: server (--server=) required"
	else
		inform "g_server: ${g_server}"
	fi

	if [ -z "${g_project}" ]; then
		error_msgs+="\nERROR: project (--project=) required"
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		error_msgs+="\nERROR: subject (--subject=) required"
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		error_msgs+="\nERROR: session (--session=) required"
	else
		inform "g_session: ${g_session}"
	fi

	if [ -z "${g_scan}" ]; then
		error_msgs+="\nERROR: scan (--scan=) required"
	else
		inform "g_scan: ${g_scan}"
	fi

	if [ -z "${g_working_dir}" ]; then
		error_msgs+="\nERROR: working directory (--working-dir=) required"
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_workflow_id}" ]; then
		error_msgs+="\nERROR: workflow (--workflow-id=) required"
	else
		inform "g_workflow_id: ${g_workflow_id}"
	fi

	# check required environment variables
	if [ -z "${XNAT_PBS_JOBS}" ]; then
		error_msgs+="\nERROR: XNAT_PBS_JOBS environment variable must be set"
	else
		inform "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"
	fi

	if [ -z "${SCRIPTS_HOME}" ]; then
		error_msgs+="\nERROR: SCRIPTS_HOME environment variable must be set"
	else
		inform "SCRIPTS_HOME: ${SCRIPTS_HOME}"
	fi

	if [ -z "${HOME}" ]; then
		error_msgs+="\nERROR: HOME environment variable must be set"
	else
		inform "HOME: ${HOME}"
	fi

	if [ -z "${XNAT_ARCHIVE_ROOT}" ]; then
		error_msgs+="\nERROR: XNAT_ARCHIVE_ROOT environment variable must be set"
	else
		inform "XNAT_ARCHIVE_ROOT: ${XNAT_ARCHIVE_ROOT}"
	fi

	if [ ! -z "${error_msgs}" ]; then
		usage
		echo -e ${error_msgs}
		exit 1
	fi
}

show_xnat_workflow()
{
	${XNAT_UTILS_HOME}/xnat_workflow_info \
		--server=${g_server} \
		--username=${g_user} \
		--password=${g_password} \
		--workflow-id=${g_workflow_id} \
		show
}

update_xnat_workflow()
{
	local step_id=${1}
	local step_desc=${2}
	local percent_complete=${3}

	echo ""
	echo ""
	echo "---------- Step: ${step_id} "
	echo "---------- Desc: ${step_desc} "
	echo ""
	echo ""

	echo "update_xnat_workflow - workflow_id: ${g_workflow_id}"
	echo "update_xnat_workflow - step_id: ${step_id}"
	echo "update_xnat_workflow - set_desc: ${step_desc}"
	echo "update_xnat_workflow - percent_complete: ${percent_complete}"

	${XNAT_UTILS_HOME}/xnat_workflow_info \
		--server="${g_server}" \
		--username="${g_user}" \
		--password="${g_password}" \
		--workflow-id="${g_workflow_id}" \
		update \
		--step-id="${step_id}" \
		--step-description="${step_desc}" \
		--percent-complete="${percent_complete}"
}

main()
{
	inform "Job started on `hostname` at `date`"

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	get_options $@

	source ${XNAT_PBS_JOBS}/GetHcpDataUtils/GetHcpDataUtils.sh


	# Set up step counters
	total_steps=5
	current_step=0

	# Set up to run Python
	inform "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	show_xnat_workflow

	# VERY IMPORTANT NOTE:
	#
	# Since ConnectomeDB resources contain overlapping files (e.g. the functionally preprocessed
	# data resource may contain some of the exact same files as the structurally preprocessed
	# data resource) extra care must be taken with the order in which data is linked in to the
	# working directory.
	#
	# If, for example, a file named ${g_subject}/subdir1/subdir2/this_file.nii.gz exists in both
	# the structurally preprocessed data resource and in the functionally preprocessed data 
	# resource, whichever resource we link in to the working directory _first_ will take 
	# precedence.  (This is due to the behavior of the lndir command used by the link_hcp...
	# functions, and is unlike the behavior of the rsync command used by the get_hcp...
	# functions. The rsync command will copy/update the newer version of the file from its
	# source.) 
	#
	# The lndir command will report to stderr any links that it could not (would not) create 
	# because they already exist in the destination directories.
	# 
	# So if we link in the structurally preprocessed data first and then link in the functionally
	# preprocessed data second, the file ${g_subject}/subdir1/subdir2/this_file.nii.gz in the 
	# working directory will be linked back to the structurally preprocessed version of the file.
	#
	# Since functional preprocessing comes _after_ structural preprocessing, this is not likely
	# to be what we want.  Instead, we want the file as it exists after functional preprocessing
	# to be the one that is linked in to the working directory.
	#
	# Therefore, it is important to consider the order in which we call the link_hcp... functions
	# below.  We should call them in order from the results of the latest prerequisite pipelines 
	# to the earliest prerequisite pipelines.
	#
	# Thus, we first link in the FIX processed data from the DB, followed by the functionally
	# preprocessed data from the DB, followed by the structurally preprocessed data from the 
	# DB.

	# Step - Link FIX processed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${current_step} "Link FIX processed data from DB" ${step_percent}

	link_hcp_fix_proc_data "${XNAT_ARCHIVE_ROOT}" "${g_project}" "${g_session}" "${g_scan}" "${g_working_dir}"







}

# Invoke the main function to get things started
main $@


