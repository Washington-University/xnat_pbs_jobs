#!/bin/bash

PIPELINE_NAME="CopyEddyLogsPatchHCP"
SCRIPT_NAME="CopyEddyLogsPatchHCP.XNAT.sh"

# echo message with script name as a prefix
inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

inform "Job started on `hostname` at `date`"

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
inform "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# Root directory for HCP database, packages, etc
HCP_ROOT="/HCP"
inform "HCP_ROOT: ${HCP_ROOT}"

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="${HCP_ROOT}/hcpdb/archive"
inform "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

# source function libraries
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

# Show script usage information
usage()
{
	inform ""
	inform "TBW"
	inform ""
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
			*)
 				usage
 				inform "ERROR: unrecognized option: ${argument}"
 				inform ""
 				exit 1
 				;;
		esac
	done

  	local error_count=0

 	# check required parameters
  	if [ -z "${g_user}" ]; then
  		inform "ERROR: user (--user=) required"
  		error_count=$(( error_count + 1 ))
  	else
  	 	inform "g_user: ${g_user}"
  	fi

  	if [ -z "${g_password}" ]; then
  		inform "ERROR: password (--password=) required"
  		error_count=$(( error_count + 1 ))
  	else
  		inform "g_password: *******"
  	fi

  	if [ -z "${g_server}" ]; then
  		inform "ERROR: server (--server=) required"
  		error_count=$(( error_count + 1 ))
  	else
  		inform "g_server: ${g_server}"
  	fi

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

 	if [ -z "${g_session}" ]; then
 		inform "ERROR: session (--session=) required"
 		error_count=$(( error_count + 1 ))
 	else
 		inform "g_session: ${g_session}"
 	fi

	if [ -z "${g_working_dir}" ]; then
 		inform "ERROR: working directory (--working-dir=) required"
 		error_count=$(( error_count + 1 ))
 	else
 		inform "g_working_dir: ${g_working_dir}"
 	fi

 	if [ ${error_count} -gt 0 ]; then
 		inform "For usage information, use --help"
 		exit 1
  	fi
}

die()
{
	exit 1
}

# Main processing
main()
{
	get_options $@

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	# Step - link previous Diffusion Preprocessed data from DB

	link_hcp_diffusion_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"

	# Step - Create a start_time file

	start_time_file="${g_working_dir}/${PIPELINE_NAME}.starttime"

	if [ -e "${start_time_file}" ]; then
		inform "Removing old ${start_time_file}"
		rm -f ${start_time_file}
	fi

 	# Sleep for 1 minute to make sure start_time file is created at least a
 	# minute after any files copied or linked above.
 	inform "Sleep for 1 minute before creating start_time file."
 	sleep 1m || die 
	
 	inform "Creating start time file: ${start_time_file}"
 	touch ${start_time_file} || die 
 	ls -l ${start_time_file}

 	# Sleep for 1 minute to make sure any files created or modified by the scripts 
 	# are created at least 1 minute after the start_time file
 	inform "Sleep for 1 minute after creating start_time file."
 	sleep 1m || die 

	# Step - Do work
	
	to_location="${g_working_dir}/${g_subject}/T1w/Diffusion/eddylogs"

	from_files=""
	from_files+=" ${g_working_dir}/${g_subject}/Diffusion/eddy/eddy_unwarped_images.eddy_outlier_map "
	from_files+=" ${g_working_dir}/${g_subject}/Diffusion/eddy/eddy_unwarped_images.eddy_outlier_n_sqr_stdev_map "
	from_files+=" ${g_working_dir}/${g_subject}/Diffusion/eddy/eddy_unwarped_images.eddy_outlier_n_stdev_map"
	from_files+=" ${g_working_dir}/${g_subject}/Diffusion/eddy/eddy_unwarped_images.eddy_outlier_report "
	from_files+=" ${g_working_dir}/${g_subject}/Diffusion/eddy/eddy_unwarped_images.eddy_movement_rms "
	from_files+=" ${g_working_dir}/${g_subject}/Diffusion/eddy/eddy_unwarped_images.eddy_restricted_movement_rms "
	from_files+=" ${g_working_dir}/${g_subject}/Diffusion/eddy/eddy_unwarped_images.eddy_parameters "
	from_files+=" ${g_working_dir}/${g_subject}/Diffusion/eddy/eddy_unwarped_images.eddy_post_eddy_shell_alignment_parameters "

	# remove any existing destination files
	rm -rf ${to_location}

	# copy eddy log files
	mkdir --parents ${to_location}
	for filename in ${from_files} ; do
		cp --verbose ${filename} ${to_location}
	done

	# Step - Show any newly created or modified files

	echo "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}

	# Step - Remove any files that are not newly created or modified

	echo "The following files are being removed"
	find ${g_working_dir}/${g_subject} -not -newer ${start_time_file} -print -delete

	return 0
}

# Invoke the main function to get things started
main $@
