#!/bin/bash

PIPELINE_NAME="DiffusionPreprocessingHCP7T"
SCRIPT_NAME="DiffusionPreprocessingHCP7T_Eddy.XNAT.sh"

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

# set up to run Python
source ${SCRIPTS_HOME}/epd-python_setup.sh

# Show script usage information
usage()
{
	cat <<EOF

Run the HCP Diffusion Preprocessing pipeline Eddy phase script
(DiffPreprocPipeline_Eddy.sh) in an XNAT-aware and 
XNAT-pipeline-like manner for HCP 7T data.

For this script to work as expected, the corresponding XNAT-aware
PreEddy script (DiffusionPreprocessingHCP7T_PreEddy.XNAT.sh) should
have been run and completed successfully on the working directory.

Usage: ${SCRIPT_NAME} PARAMETER...

PARAMETERs are: [ ] = optional, < > = user-supplied-value
  [--help]              show usage information and exit with a non-zero return code
  --user=<username>     XNAT DB username
  --password=<password> XNAT DB password
  --server=<server>     XNAT server (e.g. db.humanconnectome.org)
  --subject=<subject>   XNAT subject ID (e.g. 100307)
  --working-dir=<dir>   Working directory from which to read data
                        and in which to produce results
  --workflow-id=<id>    XNAT Workflow ID to upate as steps are completed
  --setup-script=<full-path>
                        Script to source to set up environment before 
                        running the DiffPreprocPipeline_Eddy.sh script.

Return Status Value:

  0                     help was not requested, all parameters were properly
                        formed, all required parameters were provided, and
                        no processing failure was detected
  Non-zero              Otherwise - help requested, malformed parameters,
                        some required parameters not provided, or a processing
                        failure was detected

EOF
}

# Parse command line options, verify that required options are specified.
# "Return" the options to use in global variables
get_options()
{
	local arguments=($@)

	# initialize global output variables
    unset g_user
    unset g_password
    unset g_server
    unset g_subject
    unset g_working_dir
    unset g_workflow_id
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
            --subject=*)
                g_subject=${argument/*=/""}
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
            --setup-script=*)
                g_setup_script=${argument/*=/""}
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

    if [ -z "${g_workflow_id}" ]; then
        inform "ERROR: workflow ID (--workflow-id=) required"
        error_count=$(( error_count + 1 ))
    else
        inform "g_workflow_id: ${g_workflow_id}"
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
	xnat_workflow_fail ${g_server} ${g_user} ${g_password} ${g_workflow_id}
	exit 1
}

main()
{
	get_options $@
	
	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	# Set up step counters
	total_steps=12
	current_step=6

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

    # Step - Set up environment to run scripts
    current_step=$(( current_step + 1 ))
    step_percent=$(( (current_step * 100) / total_steps ))

    xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
        ${current_step} "Set up to run DiffPreprocPipeline_Eddy.sh script" ${step_percent}

	if [ ! -e "${g_setup_script}" ] ; then
		inform "g_setup_script: ${g_setup_script} DOES NOT EXIST - ABORTING"
		die
	fi

	inform "Sourcing ${g_setup_script} to set up environment"
	source ${g_setup_script}

	# Step - Run the DiffPreprocPipeline_Eddy.sh script
    current_step=$(( current_step + 1 ))
    step_percent=$(( (current_step * 100) / total_steps ))

    xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
        ${current_step} "Run the DiffPreprocPipeline_Eddy.sh script" ${step_percent}
	
	Eddy_cmd=""
	Eddy_cmd+="${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_Eddy.sh"
	Eddy_cmd+=" --path=${g_working_dir}"
	Eddy_cmd+=" --subject=${g_subject}"
	Eddy_cmd+=" --dwiname=Diffusion_7T"
	Eddy_cmd+=" --detailed-outlier-stats=True"
	Eddy_cmd+=" --replace-outliers=True"
	Eddy_cmd+=" --nvoxhp=2000"
	Eddy_cmd+=" --sep_offs_move=True"
	Eddy_cmd+=" --rms=True"
	Eddy_cmd+=" --ff=10"
	Eddy_cmd+=" --dont_peas"
	Eddy_cmd+=" --fwhm=10,0,0,0,0"
	Eddy_cmd+=" --ol_nstd=5"
	Eddy_cmd+=" --extra-eddy-arg=--with_outliers"
	Eddy_cmd+=" --extra-eddy-arg=--initrand"
	Eddy_cmd+=" --extra-eddy-arg=--very_verbose"
	Eddy_cmd+=" --extra-eddy-arg=--b0_flm=quadratic"
	Eddy_cmd+=" --extra-eddy-arg=--b0_slm=linear"

	inform ""
	inform "Eddy_cmd: ${Eddy_cmd}"
	inform ""

	${Eddy_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
}

# Invoke the main function to get things started
main $@
