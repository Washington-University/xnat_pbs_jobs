#!/bin/bash

PIPELINE_NAME="RepairIcaFixProcessingHCP7T"
SCRIPT_NAME="${PIPELINE_NAME}.XNAT.sh"

# echo message with script name as prefix
inform()
{
	local msg=${1}
	echo "$(date) - ${SCRIPT_NAME}: ${msg}"
}

inform "Job started on $(hostname) at $(date)"

# home directory for scripts to be sourced to set up the environment
SCRIPTS_HOME=${HOME}/SCRIPTS
inform "SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
inform "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home director for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
inform "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

usage()
{
	inform ""
	inform "TBW"
	inform ""
}

# Parse specified command line options and verify that required options are
# specified. "Return" the specified values in global variables.
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
	unset g_structural_reference_project
	unset g_structural_reference_session
	unset g_scan
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
				;;
			--password=*)
				g_password=${argument/*=/""}
				;;
			--server=*)
				g_server=${argument/*=/""}
				;;
			--project=*)
				g_project=${argument/*=/""}
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				;;
			--session=*)
				g_session=${argument/*=/""}
				;;
			--structural-reference-project=*)
				g_structural_reference_project=${argument/*=/""}
				;;
			--structural-reference-session=*)
				g_structural_reference_session=${argument/*=/""}
				;;
			--scan=*)
				g_scan=${argument/*=/""}
				;;
			--working-dir=*)
				g_working_dir=${argument/*=/""}
				;;
			--setup-script=*)
				g_setup_script=${argument/*=/""}
				;;
			*)
				usage
				echo "ERROR: unrecognized option: ${argument}"
				echo ""
				exit 1
				;;
		esac
		index=$(( index + 1 ))

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
		inform "g_password: *********"
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

	if [ -z "${g_structural_reference_project}" ]; then
		inform "ERROR: structural reference project (--structural-reference-project=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_structural_reference_project: ${g_structural_reference_project}"
	fi

	if [ -z "${g_structural_reference_session}" ]; then
		inform "ERROR: structural reference session (--structural-reference-session=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_structural_reference_session: ${g_structural_reference_session}"
	fi

	if [ -z "${g_scan}" ] ; then
		inform "ERROR: scan (--scan=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_scan: ${g_scan}"
	fi

	if [ -z "${g_working_dir}" ]; then
		inform "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_setup_script}" ] ; then
		inform "ERROR: set up script (--setup-script=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_setup_script: ${g_setup_script}"
	fi

	if [ ${error_count} -gt 0 ]; then
		inform "For usage information, use --help"
		exit 1
	fi
}

die()
{
	inform "FAILING"
	exit 1
}

report_step()
{
	# global input: g_current_step
	# global output: g_current_step

	local msg=${1}

	g_current_step=$(( g_current_step + 1 ))

	inform ""
	inform "---------------------------------------------"
	inform " Step: ${g_current_step} -- Description: ${msg}"
	inform "---------------------------------------------"
	inform ""
}

determine_single_or_concatenated()
{
	# global input: g_scan
	# global output: g_scans
	# global output: g_prefix
	# global output: g_concatenated

	# produce a space separated list of just scan names
    local tesla_spec
	tesla_spec="7T"

	g_scans=${g_scan//${tesla_spec}/}
	g_scans=${g_scans//__/_}

	# does ${g_scans} now start with tfMRI or rfMRI?
	if [[ ${g_scans} == tfMRI_* ]]; then
		g_prefix="tfMRI_"
	elif [[ ${g_scans} == rfMRI_* ]]; then
		g_prefix="rfMRI_"
	else
		inform "Unrecognized prefix"
		die
	fi

	inform "g_prefix: ${g_prefix}"

	# remove the prefix
	g_scans=${g_scans#${g_prefix}}

	# put spaces after phase encoding descriptors
	g_scans=${g_scans//_AP_/_AP }
	g_scans=${g_scans//_PA_/_PA }
	g_scans=${g_scans//_LR_/_LR }
	g_scans=${g_scans//_RL_/_RL }

	inform "g_scans: ${g_scans}"

	# figure out if the processed scan is a concatenation of several scans
	if [[ "${g_scans}" =~ [\ ] ]]; then
		g_concatenated="TRUE"
	else
		g_concatenated="FALSE"
	fi
}

remove_extraneous_files()
{
	# global input: g_working_dir
	# global input: g_subject
	
	find ${g_working_dir}/${g_subject} -name "*XNAT_PBS_job*" -print -delete
	find ${g_working_dir}/${g_subject} -name "*XNAT_PBS_PUT_job*" -print -delete
	find ${g_working_dir}/${g_subject} -name "*catalog.xml" -print -delete
	find ${g_working_dir}/${g_subject} -name "*starttime" -print -delete
	find ${g_working_dir}/${g_subject} -name "StructuralHCP_Provenance.xml" -print -delete
	find ${g_working_dir}/${g_subject} -name "StructuralHCP.err" -print -delete
	find ${g_working_dir}/${g_subject} -name "StructuralHCP.log" -print -delete
	find ${g_working_dir}/${g_subject} -name "ConnectomeDB_*_freesurfer5.xml" -print -delete
}

make_scan_results_nonlinks()
{
	# global input: g_working_dir
	# global input: g_subject
	# global input: g_scan

	local linked_files
	local linked_file

	pushd ${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}

	linked_files=$(find . -type l)
	for linked_file in ${linked_files} ; do
		inform "Making ${linked_file} no longer a link"
		cp -a --preserve=timestamps --remove-destination $(readlink ${linked_file}) ${linked_file}
	done

	popd
}

create_start_time_file()
{
	# global input: g_working_dir
	# global input: PIPELINE_NAME
	# global output: g_start_time_file

	g_start_time_file="${g_working_dir}/${PIPELINE_NAME}.starttime"
	if [ -e "${g_start_time_file}" ]; then
		inform "Removing old ${g_start_time_file}"
		rm -f ${g_start_time_file}
	fi

	# Sleep for 1 minute to make sure start_time file is created at least a
	# minute after any files copied or linked above.
	inform "Sleep for 1 minute before creating start_time file."
	sleep 1m || die 
	
	inform "Creating start time file: ${g_start_time_file}"
	touch ${g_start_time_file} || die 
	ls -l ${g_start_time_file}

	# Sleep for 1 minute to make sure any files created or modified by the scripts 
	# are created at least 1 minute after the start_time file
	inform "Sleep for 1 minute after creating start_time file."
	sleep 1m || die 
}

source_set_up_script()
{
	# global input: g_setup_script

	if [ -e "${g_setup_script}" ]; then
		inform "Sourcing ${g_setup_script} to set up environment"
		source ${g_setup_script}
	else
		inform "Set up environment script: '${g_setup_script}', DOES NOT EXIST"
		die
	fi
}

prepare_for_reapplyfix_59k()
{
	# global input: g_working_dir
	# global input: g_subject
	# global input: g_scan

	# rename input file that the 59k ReApplyFixPipeline will expect
	local highres_atlas_dtseries
	local expected_name
	
	highres_atlas_dtseries="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}_Atlas_1.6mm.dtseries.nii"
	expected_name="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}_Atlas_MSMSulc.59k.dtseries.nii"
	if [ -e "${highres_atlas_dtseries}" ] ; then
		mv_cmd="mv ${highres_atlas_dtseries} ${expected_name}"
		inform "mv_cmd: ${mv_cmd}"
		${mv_cmd}
	else
		inform "HighRes Atlas dtseries file: '${highres_atlas_dtseries}' does not exist!"
		die
	fi

	# remove output files previously generated by 59k ReApplyFixPipeline call
	local highres_cleaned_atlas_dtseries
	highres_cleaned_atlas_dtseries="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}_Atlas_1.6mm_hp2000_clean.dtseries.nii"
	rm_cmd="rm ${highres_cleaned_atlas_dtseries}"
	inform "rm_cmd: ${rm_cmd}"
	${rm_cmd}
	
	# remove generic atlas dtseries file
	generic_atlas_dtseries="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}_hp2000.ica/Atlas.dtseries.nii"
	rm_cmd="rm ${generic_atlas_dtseries}"
	inform "rm_cmd: ${rm_cmd}"
	${rm_cmd}
}

run_reapply_fix_59k()
{
	# global input: HCPPIPEDIR
	# global input: g_working_dir
	# global input: g_subject
	# global input: g_scan

	local reapplyfix_cmd
	local retcode
	
	reapplyfix_cmd=""
	reapplyfix_cmd+="${HCPPIPEDIR}/ReApplyFix/ReApplyFixPipeline.sh"
	reapplyfix_cmd+=" --path=${g_working_dir} "
	reapplyfix_cmd+=" --subject=${g_subject} "
	reapplyfix_cmd+=" --fmri-name=${g_scan} "
	reapplyfix_cmd+=" --high-pass=2000 "
	reapplyfix_cmd+=" --reg-name=MSMSulc "
	reapplyfix_cmd+=" --low-res-mesh=59 "
	reapplyfix_cmd+=" --matlab-run-mode=0 "

	inform "reapplyfix_cmd: ${reapplyfix_cmd}"

	pushd ${g_working_dir}
	${reapplyfix_cmd}
	retcode=$?
	if [ ${retcode} -ne 0 ]; then
		inform "retcode: ${retcode}"
		die
	fi
	popd
}

show_new_files()
{
	# global input: g_working_dir
	# global input: g_subject
	# global input: g_start_time_file

	inform "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${g_start_time_file}
}

remove_non_new_files()
{
	# global input: g_working_dir
	# global input: g_subject
	# global input: g_start_time_file

	inform "The following, non-new files are being removed"
	find ${g_working_dir}/${g_subject} -not -newer ${g_start_time_file} -print -delete
}

rename_resulting_clean_atlas_file()
{
	# global input: g_working_dir
	# global input: g_subject
	# global input: g_scan

	local original_output_name
	local new_name
	
	original_output_name="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}_Atlas_MSMSulc.59k_hp2000_clean.dtseries.nii"
	new_name="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}_Atlas_1.6mm_hp2000_clean.dtseries.nii"

	if [ -e "${original_output_name}" ] ; then
		mv_cmd="mv ${original_output_name} ${new_name}"
		inform "mv_cmd: ${mv_cmd}"
		${mv_cmd}
	else
		inform "Expected original_output_name: '${original_output_name}' file does not exist!"
		die
	fi
}

move_results_up_some()
{
	# global input: g_working_dir
	# global input: g_subject

	mv --verbose ${g_working_dir}/${g_subject}/MNINonLinear/Results/* ${g_working_dir}
	rm -r --verbose ${g_working_dir}/${g_subject}
}

main()
{
	get_options $@

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	# Set up step counter
	g_current_step=0

	# Step - Determine if this is a single scan or a concatenated scan
	report_step "Determine if this is a single scan or a concatenated scan"

	# global input: g_scan
	# global output: g_scans, g_prefix, g_concatenated
	determine_single_or_concatenated
	
	if [ "${g_concatenated}" = "TRUE" ]; then
		inform "concatenated"
	else
		inform "single scan"
	fi
		
	if [ "${g_concatenated}" = "TRUE" ]; then

		inform "This processing is intented for a single scan only, not a concatenated scan."
		die
		
	fi

	local preproc_scan
	preproc_scan=${g_prefix}${g_scans}
	inform "preproc_scan: ${preproc_scan}"
	
	# Step - Link the FIX processed data
	report_step "Link Fix processed data for a single scan from the DB"
	
	link_hcp_fix_proc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" \
						   "${g_session}" "${preproc_scan}" "${g_working_dir}"
	
	# Step - Link the functionally preprocessed data
	report_step "Link the functionally preprocessed data"
	
	link_hcp_func_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" \
							   "${g_session}" "${preproc_scan}" "${g_working_dir}"


	# Step - Link Supplemental Structurally preprocessed data from DB
	#      - the higher resolution greyordinates space
	report_step "Link supplemental structurally preprocessed data from DB"
	
	link_hcp_supplemental_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" \
											  "${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"

	# Step - Link Structurally preprocessed data from DB
	report_step "Link Structurally preprocessed data from DB"

	link_hcp_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" \
								 "${g_structural_reference_session}" "${g_working_dir}"

	# Step - Link unprocessed data from DB
	report_step "Link unprocessed data from DB"

	link_hcp_struct_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" \
								"${g_structural_reference_session}" "${g_working_dir}"
	link_hcp_7T_resting_state_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" \
										  "${g_working_dir}"
	link_hcp_7T_diffusion_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
	link_hcp_7T_task_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"

	# Step - Remove extraneous files
	report_step "Remove extraneous files"

	# global input: g_working_dir, g_subject
	remove_extraneous_files

	# # Step - Make files that are potentially opened for writing into nonlinks
	# # Whether they are actually written to or not, if a file is opened in write mode,
	# # that open will fail due to the read-only nature of the files in the DB archive.
	# # So some files that are symbolic links to files in the DB archive, need to made
	# # "local" (i.e. non-link) files
	report_step "Make files that are potentially opened for writing into nonlinks"

	# global input: g_working_dir, g_subject, g_scan
	make_scan_results_nonlinks

	# Step - Create a start_time file
	report_step "Create a start_time file"

	# global input: g_working_dir, PIPELINE_NAME
	# global output: g_start_time_file
	create_start_time_file

	# Step - source set up script
	report_step "Source set up script"

	# global input: g_setup_script
	source_set_up_script

	# Step - Rename and remove files to be compatible with ReApplyFixPipeline script
	report_step "Rename and remove files to prepare for ReApplyFixPipeline 59k invocation"

	# global input: g_working_dir, g_subject, g_scan
	prepare_for_reapplyfix_59k

	# Step - run ReApplyFixPipeline for 59k low res mesh
	report_step "Run ReApplyFixPipeline for 59k low res mesh"

	# global input: HCPPIPEDIR, g_working_dir, g_subject, g_scan
	run_reapply_fix_59k

	# Step - Show any newly created or modified files
	report_step "Show any newly created or modified files"

	# global input: g_working_dir, g_subject, g_start_time_file
	show_new_files

	# Step - Remove any files that are not newly created or modified
	report_step "Remove any files that are not newly created or modified"

	# global input: g_working_dir, g_subject, g_start_time_file
	remove_non_new_files

	# Step - Rename resulting clean atlas file
	report_step "Rename resulting clean atlas file"

	# global input: g_working_dir, g_subject, g_scan
	rename_resulting_clean_atlas_file

	# Step - Move results up a few directory levels to be compatible with
	#        bad decision made a long time ago
	report_step "Move results up a couple directory levels to be compatible with bad decision made a long time ago"

	# global input: g_working_dir, g_subject
	move_results_up_some
		
	# Step - Complete
	report_step "Complete"
}

# Invoke the main function to get things started
main $@
