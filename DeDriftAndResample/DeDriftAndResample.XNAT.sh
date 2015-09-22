#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # DeDriftAndResample.XNAT.sh
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
# This script runs the MSM-All pipeline script that does DeDrifting and 
# Resampling for the Human Connectome Project for a specified project, 
# subject, & session in the ConnectomeDB (db.humanconnectome.org) XNAT 
# database.
#
# The script is run not as an XNAT pipeline (under the control of the
# XNAT Pipeline Engine), but in an "XNAT-aware" and "pipeline-like" manner.
# 
# The data to be processed is retrieved via filesystem operations instead
# of using REST API calls. So the database archive and resource directory 
# structure is "known and used" by this script.
# 
# This script can be invoked by a job submitted to a worker or execution
# node in a cluster, e.g. a Sun Grid Engine (SGE) managed or Portable Batch
# System (PBS) managed cluster. Alternatively, if the machine being used
# has adequate resources (RAM, CPU power, storage space), this script can 
# simply be invoked interactively.
#
#~ND~END~

echo "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to setup the environment
SCRIPTS_HOME=/home/HCPpipeline/SCRIPTS
echo "SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for XNAT related utilities
XNAT_UTILS_HOME=/home/HCPpipeline/pipeline_tools/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# Set up to run Python
echo "Setting up to run Python"
source ${SCRIPTS_HOME}/epd-python_setup.sh

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
	unset g_project
	unset g_subject
	unset g_session
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
			--working-dir=*)
				g_working_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--workflow-id=*)
				g_workflow_id=${argument/*=/""}
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

	if [ -z "${g_working_dir}" ]; then
		echo "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_working_dir: ${g_working_dir}"
	fi

	if [ ! -z "${g_workflow_id}" ]; then
		echo "g_workflow_id: ${g_workflow_id}"
	fi

	if [ ${error_count} -gt 0 ]; then
		echo "For usage information, use --help"
		exit 1
	fi
}

# Show information about a specified XNAT Workflow
show_xnat_workflow()
{
	if [ ! -z "${g_workflow_id}" ]; then
		${XNAT_UTILS_HOME}/xnat_workflow_info \
			--server="${g_server}" \
			--username="${g_user}" \
			--password="${g_password}" \
			--workflow-id="${g_workflow_id}" \
			show
	fi
}

# Update information (step id, step description, and percent complete)
# for a specified XNAT Workflow
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

	if [ ! -z "${g_workflow_id}" ]; then
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
	fi
}

# Mark the specified XNAT Workflow as complete
complete_xnat_workflow()
{
	if [ ! -z "${g_workflow_id}" ]; then
		${XNAT_UTILS_HOME}/xnat_workflow_info \
			--server="${g_server}" \
			--username="${g_user}" \
			--password="${g_password}" \
			--workflow-id="${g_workflow_id}" \
			complete
	fi
}

# Mark the specified XNAT Workflow as failed
fail_xnat_workflow()
{
	if [ ! -z "${g_workflow_id}" ]; then
		${XNAT_UTILS_HOME}/xnat_workflow_info \
			--server="${g_server}" \
			--username="${g_user}" \
			--password="${g_password}" \
			--workflow-id="${g_workflow_id}" \
			fail
	fi
}

# Update specified XNAT Workflow to Failed status and exit this script
die()
{
	fail_xnat_workflow ${g_workflow_id}
	exit 1
}

# Initialize the step counters
init_steps()
{
	local total_steps=${1}
	g_total_steps=${total_steps}
	g_current_step=0
}

# Increment the current step
increment_step()
{
	g_current_step=$(( g_current_step + 1 ))
	if [ ${g_current_step} -gt ${g_total_steps} ] ; then
		echo "ERROR: g_current_step: ${g_current_step} greater than g_total_steps: ${g_total_steps}"
		exit 1
	fi
	g_step_percent=$(( (g_current_step * 100) / g_total_steps ))
}

# Main processing
#   Carry out the necessary steps to:
#   - get prerequisite data for DeDriftAndResample.sh
#   - run the script
main()
{
	get_options $@

	# Set up step counters
	init_steps 2

	show_xnat_workflow





	# ----------------------------------------------------------------------------------------------
	# Step - Create a start_time file
	# ----------------------------------------------------------------------------------------------
	increment_step
	update_xnat_workflow ${g_current_step} "Create a start_time file" ${g_step_percent}
	
	start_time_file="${g_working_dir}/DeDriftAndResample.starttime"
	if [ -e "${start_time_file}" ]; then
		echo "Removing old ${start_time_file}"
		rm -f ${start_time_file}
	fi
	
	# Sleep for 1 minute to make sure start_time file is created at least a
	# minute after any files copied or linked above.
	echo "Sleep for 1 minute before creating start_time file."
	sleep 1m || die

	echo "Creating start time file: ${start_time_file}"
	touch ${start_time_file} || die 
	ls -l ${start_time_file}

	# Sleep for 1 minute to make sure any files created or modified by the script below
	# are created at least 1 minute after the start_time file
	echo "Sleep for 1 minute after creating start_time file."
	sleep 1m || die 

	# ----------------------------------------------------------------------------------------------
	# Step - Run DeDriftAndResample.sh script
	# ----------------------------------------------------------------------------------------------
	increment_step
	update_xnat_workflow ${g_current_step} "Run DeDriftAndResamplePipeline.sh script" ${g_step_percent}
	
	# Source setup script to setup environment for running the script
	setup_file="${SCRIPTS_HOME}/SetUpHCPPipeline_DeDriftAndResample.sh"
	if [ ! -e ${setup_file} ] ; then
		echo "ERROR: setup_file: ${setup_file} DOES NOT EXIST! ABORTING"
		die
	fi

	source ${setup_file}

	scan_names=`echo "${scan_names}" | sed s/" "/"@"/g`
	echo "scan_names: ${scan_names}"
		
	# Run DeDriftAndResamplePipeline.sh script
	${HCPPIPEDIR}/DeDriftAndResample/DeDriftAndResamplePipeline.sh \
		--path=${g_working_dir} \
		--subject=${g_subject} 


# 		--fmri-names-list=${scan_names} \
# 		--output-fmri-name="rfMRI_REST" \
# 		--fmri-proc-string="_Atlas_hp2000_clean" \
# 		--msm-all-templates="${HCPPIPEDIR}/global/templates/MSMAll" \
# 		--output-registration-name="MSMAll_InitalReg" \
# 		--high-res-mesh="164" \
# 		--low-res-mesh="32" \
# 		--input-registration-name="MSMSulc"
	
	if [ $? -ne 0 ]; then
		die 
	fi

	# ----------------------------------------------------------------------------------------------
	# Step - Show any newly created or modified files
	# ----------------------------------------------------------------------------------------------
	increment_step
	update_xnat_workflow ${g_current_step} "Show newly created or modified files" ${g_step_percent}
	
	echo "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}
	
	# ----------------------------------------------------------------------------------------------
	# Step - Remove any files that are not newly created or modified
	# ----------------------------------------------------------------------------------------------
#	increment_step
#	update_xnat_workflow ${g_current_step} "Remove files not newly created or modified" ${g_step_percent}
#
#	echo "The following files are being removed"
#	find ${g_working_dir}/${g_subject} -not -newer ${start_time_file} -print -delete || die 
	
	# ----------------------------------------------------------------------------------------------
	# Step - Complete Workflow
	# ----------------------------------------------------------------------------------------------
	increment_step
	complete_xnat_workflow 
}

# Invoke the main function to get things started
main $@