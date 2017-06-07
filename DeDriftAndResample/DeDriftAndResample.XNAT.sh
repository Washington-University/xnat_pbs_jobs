#!/bin/bash

g_pipeline_name="DeDriftAndResample"

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

Run the HCP DeDriftAndResample pipeline

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
			--setup-script=*)
				g_setup_script=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				usage
				log_Err_Abort "unrecognized option: ${argument}"
				;;
		esac
	done

	local error_count=0

	# check required parameters
	if [ -z "${g_user}" ]; then
		log_Err "user (--user=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		log_Err "password (--password=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "g_password: *******"
	fi

	if [ -z "${g_server}" ]; then
	    log_Err "server (--server=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "g_server: ${g_server}"
	fi

	if [ -z "${g_project}" ]; then
		log_Err "project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		log_Err "subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		log_Err "session (--session=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "g_session: ${g_session}"
	fi

	if [ -z "${g_working_dir}" ]; then
		log_Err "working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_setup_script}" ]; then
		log_Err "setup script (--setup-script=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "g_setup_script: ${g_setup_script}"
	fi

	if [ ${error_count} -gt 0 ]; then
		log_Err_Abort "For usage information, use --help"
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

	# root directory of the XNAT database archive
	DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
	log_Msg "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

	# ----------------------------------------------------------------------------------------------
	#  Figure out what resting state scans are available for this subject/session
	# ----------------------------------------------------------------------------------------------

	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES

	resting_state_scan_names=""
	resting_state_scan_dirs=`ls -d rfMRI_REST*_preproc`
	for resting_state_scan_dir in ${resting_state_scan_dirs} ; do
		scan_name=${resting_state_scan_dir%%_preproc}
		resting_state_scan_names+="${scan_name} "
	done
	resting_state_scan_names=${resting_state_scan_names% } # remove trailing space
	
	if [ -z "${resting_state_scan_names}" ]; then
		resting_state_scan_names="NONE"
	fi

	log_Msg "Found the following resting state scans: ${resting_state_scan_names}"

	popd

	# ----------------------------------------------------------------------------------------------
	#  Figure out what task scans are available for this subject/session 
	# ----------------------------------------------------------------------------------------------

	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES

	task_scan_names=""
	task_scan_dirs=`ls -d tfMRI_*_preproc`
	for task_scan_dir in ${task_scan_dirs} ; do
		scan_name=${task_scan_dir%%_preproc}
		task_scan_names+="${scan_name} "
	done
	task_scan_names=${task_scan_names% } # remove trailing space

	if [ -z "${task_scan_names}" ]; then
		task_scan_names="NONE"
	fi

	log_Msg "Found the following task scans: ${task_scan_names}"

	popd

	# ----------------------------------------------------------------------------------------------
	#  Run DeDriftAndResample.sh script
	# ----------------------------------------------------------------------------------------------

	# Setup variables for command line arguments
	
	local HighResMesh="164"
	local LowResMeshes="32" # Delimit with @ e.g. 32@59, multiple resolutions not currently supported for fMRI data
	#local RegName="MSMAll_InitalReg" # From MSMAllPipeline.bat
	local RegName="MSMAll_InitalReg_2_d40_WRN" # From MSMAllPipeline.bat

	local DeDriftRegFiles=""
	DeDriftRegFiles+="${g_working_dir}/DeDriftingGroup/MNINonLinear/DeDriftMSMAll/DeDriftingGroup.L.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"
	DeDriftRegFiles+="@"
	DeDriftRegFiles+="${g_working_dir}/DeDriftingGroup/MNINonLinear/DeDriftMSMAll/DeDriftingGroup.R.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"
	
	local ConcatRegName="MSMAll" # Final name of ${RegName}, the string that identifies files as being registered with this method
	local Maps="sulc curvature corrThickness thickness" # List of Structural Maps to be resampled
	local MyelinMaps="MyelinMap SmoothedMyelinMap" #List of Myelin Maps to be Resampled (No _BC, this will be reapplied)
	local rfMRINames="${resting_state_scan_names}" #List of Resting State Maps Space delimited list or NONE
	local tfMRINames="${task_scan_names}" #Space delimited list or NONE
	local SmoothingFWHM="2" #Should equal previous grayordiantes smoothing (because we are resampling from unsmoothed native mesh timeseries
	local HighPass="2000" #For resting state fMRI

	Maps=`echo "$Maps" | sed s/" "/"@"/g`
	MyelinMaps=`echo "$MyelinMaps" | sed s/" "/"@"/g`
	rfMRINames=`echo "$rfMRINames" | sed s/" "/"@"/g`
	tfMRINames=`echo "$tfMRINames" | sed s/" "/"@"/g`

	# Run DeDriftAndResamplePipeline.sh script
	cmd=${HCPPIPEDIR}/DeDriftAndResample/DeDriftAndResamplePipeline.sh
	cmd+=" --path=${g_working_dir} "
	cmd+=" --subject=${g_subject} "
	cmd+=" --high-res-mesh=${HighResMesh} "
	cmd+=" --low-res-meshes=${LowResMeshes} "
	cmd+=" --registration-name=${RegName} "
	cmd+=" --dedrift-reg-files=${DeDriftRegFiles} "
	cmd+=" --concat-reg-name=${ConcatRegName} "
	cmd+=" --maps=${Maps} "
	cmd+=" --myelin-maps=${MyelinMaps} "
	cmd+=" --rfmri-names=${rfMRINames} "
	cmd+=" --tfmri-names=${tfMRINames} "
	cmd+=" --smoothing-fwhm=${SmoothingFWHM} "
	cmd+=" --highpass=${HighPass} "
	cmd+=" --matlab-run-mode=0 "

	log_Msg "About to issue the following command"
	log_Msg "${cmd}"

	${cmd}
	return_code=$?
	if [ ${return_code} -ne 0 ]; then
		log_Err_Abort "DeDriftAndResamplePipeline.sh non-zero return code: ${return_code}"
	fi
	
	log_Msg "Complete"
}

# Invoke the main function to get things started
main "$@"

