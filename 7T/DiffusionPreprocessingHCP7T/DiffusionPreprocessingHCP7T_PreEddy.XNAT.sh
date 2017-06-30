#!/bin/bash

PIPELINE_NAME="DiffusionPreprocessingHCP7T"
SCRIPT_NAME="DiffusionPreprocessingHCP7T_PreEddy.XNAT.sh"

# echo messsage with script name as prefix
inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

inform "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to setup the environment
SCRIPTS_HOME=${HOME}/SCRIPTS
inform "SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
inform "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for XNAT related utilities
XNAT_UTILS_HOME=${PIPELINE_TOOLS_HOME}/xnat_utilities
inform "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=${HOME}/pipeline

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
inform "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

# source XNAT workflow utility functions
source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh

# source utility functions for getting data
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

# set up to run Python
source ${SCRIPTS_HOME}/epd-python_setup.sh

RLLR_POSITIVE_DIR="RL"
RLLR_NEGATIVE_DIR="LR"

PAAP_POSITIVE_DIR="PA"
PAAP_NEGATIVE_DIR="AP"

TESLA_SPEC="7T"

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
    unset g_phase_encoding_dirs
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
            --structural-reference-project=*)
                g_structural_reference_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --structural-reference-session=*)
                g_structural_reference_session=${argument/*=/""}
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
            --phase-encoding-dirs=*)
                g_phase_encoding_dirs=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --setup-script=*)
                g_setup_script=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            *)
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

    if [ -z "${g_working_dir}" ]; then
        inform "ERROR: working directory (--working-dir=) required"
        error_count=$(( error_count + 1 ))
    else
        inform "g_working_dir: ${g_working_dir}"
    fi

    if [ -z "${g_workflow_id}" ]; then
        inform "ERROR: workflow ID (--workflow-id=) required"
        error_count=$(( error_count + 1 ))
    else
        inform "g_workflow_id: ${g_workflow_id}"
    fi

    if [ -z "${g_phase_encoding_dirs}" ]; then
        echo "ERROR: phase encoding dir specifier (--phase-encoding-dirs=) required"
        error_count=$(( error_count + 1 ))
    else
        if [ "${g_phase_encoding_dirs}" != "RLLR" ] ; then
            if [ "${g_phase_encoding_dirs}" != "PAAP" ] ; then
                echo "ERROR: Unrecognized phase encoding dir specifier: ${g_phase_encoding_dirs}"
                error_count=$(( error_count + 1 ))
            fi
        fi
    fi
	inform "g_phase_encoding_dirs: ${g_phase_encoding_dirs}"
	
	if [ -z "${g_setup_script}" ] ; then
		inform "ERROR: set up script (--setup-script=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_setup_script: ${g_setup_script}"
	fi

    if [ ${error_count} -gt 0 ]; then
        exit 1
    fi
}

die()
{
	xnat_workflow_fail ${g_server} ${g_user} ${g_password} ${g_workflow_id}
	exit 1
}

get_scan_data()
{
    local resource_name="${1}"
    local file_name="${2}"
    local item_name="${3}"

    local result=`${XNAT_UTILS_HOME}/xnat_scan_info -s "${XNAT_PBS_JOBS_XNAT_SERVER}" -u ${g_user} -p ${g_password} -pr ${g_project} -su ${g_subject} -se ${g_session} -r "${resource_name}" get_data -f "${file_name}" -i "${item_name}"`
    echo ${result}
}

main()
{
	get_options $@

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	# Set up step counters
	total_steps=12
	current_step=0

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

	# Step - Link Supplemental Structurally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link Supplemental Structurally preprocessed data from DB" ${step_percent}

	link_hcp_supplemental_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" \
		"${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"

	# Step - Link Structurally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link Struturally preprocessed data from DB" ${step_percent}

	link_hcp_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" \
		"${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"

	# Step - Link unprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link Unprocessed data from DB" ${step_percent}

	link_hcp_struct_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" \
		"${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"

	link_hcp_7T_resting_state_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" \
		"${g_subject}" "${g_session}" "${g_working_dir}"

	link_hcp_7T_diffusion_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" \
		"${g_subject}" "${g_session}" "${g_working_dir}"

	link_hcp_7T_task_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" \
		"${g_subject}" "${g_session}" "${g_working_dir}"

	# Step - Create a start_time file
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Create a start_time file" ${step_percent}

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

    # Step - Set up environment to run scripts
    current_step=$(( current_step + 1 ))
    step_percent=$(( (current_step * 100) / total_steps ))

    xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
        ${current_step} "Set up to run DiffPreprocPipeline_PreEddy.sh script" ${step_percent}

	if [ ! -e "${g_setup_script}" ] ; then
		inform "g_setup_script: ${g_setup_script} DOES NOT EXIST - ABORTING"
		die
	fi

	inform "Sourcing ${g_setup_script} to set up environment"
	source ${g_setup_script}

	inform "Determining what positive and negative DWI files are available"
	
	if [ "${g_phase_encoding_dirs}" = "RLLR" ] ; then
		positive_dir=${RLLR_POSITIVE_DIR}
		negative_dir=${RLLR_NEGATIVE_DIR}
	elif [ "${g_phase_encoding_dirs}" = "PAAP" ] ; then
		positive_dir=${PAAP_POSITIVE_DIR}
		negative_dir=${PAAP_NEGATIVE_DIR}
	else
		inform "ERROR: Unrecognized phase encoding dir specifier: ${g_phase_encoding_dirs} - ABORTING"
		die
	fi

	# build the posData string and the echoSpacing while we're at it
	positive_scans=`find ${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/Diffusion -maxdepth 1 -name "${g_subject}_${TESLA_SPEC}_DWI_dir*_${positive_dir}.nii.gz" | sort`
	posData=""
	for pos_scan in ${positive_scans} ; do
		if [ -z "${posData}" ] ; then
			# get echo spacing from the first DWI scan we encounter
			short_name=${pos_scan##*/}
			echoSpacing=`get_scan_data Diffusion_unproc ${short_name} "parameters/echoSpacing"`
			echoSpacing=`echo "${echoSpacing} 1000.0" | awk '{printf "%.12f", $1 * $2}'`
			inform "echoSpacing: ${echoSpacing}"
		else
			# this is not the first positive DWI scan we've encountered, so add a separator to the posData string we are building
			posData+="@"
		fi
		posData+="${pos_scan}"
	done
	inform "posData: ${posData}"

	# build the negData string
	negative_scans=`find ${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/Diffusion -maxdepth 1 -name "${g_subject}_${TESLA_SPEC}_DWI_dir*_${negative_dir}.nii.gz" | sort`
	negData=""
	for neg_scan in ${negative_scans} ; do
		if [ ! -z "${negData}" ] ; then
			# this is not the first negative DWI scan we've encountered, so add a separator to the negData string we are building
			negData+="@"
		fi
		negData+="${neg_scan}"
	done
	inform "negData: ${negData}"

	# Step - Run the DiffPreprocPipeline_PreEddy.sh script
    current_step=$(( current_step + 1 ))
    step_percent=$(( (current_step * 100) / total_steps ))

    xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
        ${current_step} "Run the DiffPreprocPipeline_PreEddy.sh script" ${step_percent}

	PreEddy_cmd=""
	PreEddy_cmd+="${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_PreEddy.sh"
	PreEddy_cmd+=" --path=${g_working_dir}"
	PreEddy_cmd+=" --subject=${g_subject}"

	if [ "${g_phase_encoding_dirs}" = "RLLR" ] ; then
		PreEddy_cmd+=" --PEdir=1"
	elif [ "${g_phase_encoding_dirs}" = "PAAP" ] ; then
		PreEddy_cmd+=" --PEdir=2"
	else
		inform "ERROR: Unrecognized phase encoding dir specifier: ${g_phase_encoding_dirs} - ABORTING"
		exit 1
	fi

	PreEddy_cmd+=" --posData=${posData}"
	PreEddy_cmd+=" --negData=${negData}"
	PreEddy_cmd+=" --echospacing=${echoSpacing}"
	PreEddy_cmd+=" --b0maxbval=100"
	PreEddy_cmd+=" --dwiname=Diffusion_7T"

	inform ""
	inform "PreEddy_cmd: ${PreEddy_cmd}"
	inform ""

	${PreEddy_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
}

# Invoke the main function to get things started
main $@
