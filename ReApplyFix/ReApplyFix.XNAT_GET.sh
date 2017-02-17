#!/bin/bash

g_script_name="ReApplyFix.XNAT_GET.sh"
g_database_archive_root="/HCP/hcpdb/archive"

inform()
{
	local msg=${1}
	echo "${g_script_name}: ${msg}"
}

usage()
{
	cat <<EOF

Get data from the XNAT archive necessary to run the HCP ReApplyFix.sh pipeline script

Usage: ${SCRIPT_NAME} PARAMETER..."

PARAMETERs are [ ] = optional; < > = user supplied value
  [--help]                 : show usage information and exit with non-zero return code
   --project=<project>     : XNAT project (e.g. HCP_500)
   --subject=<subject>     : XNAT subject ID within project (e.g. 100307)
   --working-dir=<dir>     : Working directory in which to place retrieved data
                             and in which to produce results

EOF
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
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
				inform "ERROR: unrecognized option ${argument}"
				exit 1
				;;
		esac
	done

	local error_msgs=""

	# check required parameters
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

	if [ -z "${g_working_dir}" ]; then
		error_msgs+="\nERROR: working directory (--working-dir=) required"
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	# check required environment variables
	if [ -z "${XNAT_PBS_JOBS}" ]; then
		error_msgs+="\nERROR: XNAT_PBS_JOBS environment variable must be set"
	else
		g_xnat_pbs_jobs=${XNAT_PBS_JOBS}
		inform "g_xnat_pbs_jobs: ${g_xnat_pbs_jobs}"
	fi
	
	if [ ! -z "${error_msgs}" ]; then
		usage
		echo -e ${error_msgs}
		exit 1
	fi
}

replace_symlink_with_copy()
{
	local file=${1}
	if [ -L ${file} ] ; then
		inform "Creating local/non-symbolic link version of ${file}"
		cp -L --preserve=timestamps ${file} ${file}.TMP.NOT_A_LINK
		rm ${file}
		mv ${file}.TMP.NOT_A_LINK ${file}
	fi
}

main()
{
	inform "Job started on `hostname` at `date`"

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	get_options $@

	# Link CinaB-style data
	inform "Activating Python 3"
	source activate python3 2>&1

	inform "Getting CinaB-Style 3T data"
	${g_xnat_pbs_jobs}/lib/hcp/hcp3t/get_cinab_style_data.py \
		--project=${g_project} \
		--subject=${g_subject} \
		--study-dir=${g_working_dir} \
		--phase=reapplyfix_prereqs

	# FIX processed Resting State Scans
	inform "Determine FIX processed Resting State Scans"

	g_session=${g_subject}_3T
	pushd ${g_database_archive_root}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	fix_processed_resting_state_scan_names=""
	resting_state_scan_dirs=`ls -d rfMRI_REST*_FIX`
	for resting_state_scan_dir in ${resting_state_scan_dirs} ; do
		scan_name=${resting_state_scan_dir%%_FIX} # take the _FIX off the end
		fix_processed_resting_state_scan_names+="${scan_name} "
	done
	fix_processed_resting_state_scan_names=${fix_processed_resting_state_scan_names% } # remove trailing space
	
	inform "Found the following FIX Processed resting state scans: ${fix_processed_resting_state_scan_names}"

	popd > /dev/null

	# FIX processed Task scans
	inform "Determine FIX processed Task Scans"
	pushd ${g_database_archive_root}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	fix_processed_task_scan_names=""
	task_scan_dirs=`ls -d tfMRI_*_FIX`
	for task_scan_dir in ${task_scan_dirs} ; do
		scan_name=${task_scan_dir%%_FIX} # take the _FIX off the end
		fix_processed_task_scan_names+="${scan_name} "
	done
	fix_processed_task_scan_names=${fix_processed_task_scan_names% } # remove trailing space

	inform "Found the following FIX Processed task scans: ${fix_processed_task_scan_names}"

	popd > /dev/null

	inform "Make local copies instead of symbolic links for .ica directory files."

	local HighPass="2000"
	for scan_name in ${fix_processed_resting_state_scan_names} ${fix_processed_task_scan_names} ; do
		
		inform "scan_name: ${scan_name}"
		
		working_ica_dir=${g_working_dir}/${g_subject}/MNINonLinear/Results/${scan_name}/${scan_name}_hp${HighPass}.ica
		inform "working_ica_dir: ${working_ica_dir}"

		files_to_unlink=`find ${working_ica_dir} -print`
		for file in ${files_to_unlink} ; do
			replace_symlink_with_copy ${file}
		done
		
	done

	# if [ -d "${working_ica_dir}/mc" ] ; then
	# 	inform "Directory: ${working_ica_dir}/mc EXISTS"
	# 	rm --recursive --verbose ${working_ica_dir}/mc
	# fi

	inform "Complete"
}

# Invoke the main to get things started
main $@
