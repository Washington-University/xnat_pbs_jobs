#!/bin/bash

# This pipeline's name
PIPELINE_NAME="AddResolutionPatchHCP7T"
SCRIPT_NAME="SubmitAddResolutionPatchHCP7T.OneSubject.sh"
DEFAULT_RESOURCE_NAME="Structural_preproc_supplemental"

# echo a message with the script name as a prefix
inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=${HOME}/pipeline
inform "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# home directory for XNAT utilities
XNAT_UTILS_HOME=${HOME}/pipeline_tools/xnat_utilities
inform "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# Root directory for HCP data
HCP_ROOT="/HCP"
inform "HCP_ROOT: ${HCP_ROOT}"

# main build directory
BUILD_HOME="${HCP_ROOT}/hcpdb/build_ssd/chpc/BUILD"
inform "BUILD_HOME: ${BUILD_HOME}"

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
	unset g_output_resource
	unset g_setup_script

	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
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
			--output-resource=*)
				g_output_resource=${argument/*=/""}
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

	# set defaults and prompt for some unspecified parameters
	if [ -z "${g_user}" ]; then
		printf "Enter Connectome DB Username: "
		read g_user
	fi

	if [ -z "${g_password}" ]; then
		stty -echo
		printf "Enter Connectome DB Password: "
		read g_password
		echo ""
		stty echo
	fi

	if [ -z "${g_server}" ]; then
		g_server="${XNAT_PBS_JOBS_XNAT_SERVER}"
	fi
	inform "Connectome DB Server: ${g_server}"

	if [ -z "${g_project}" ]; then
		g_project="HCP_Staging"
	fi
    inform "Connectome DB Project: ${g_project}"

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi
	inform "Connectome DB Subject: ${g_subject}"

	if [ -z "${g_session}" ]; then
		g_session=${g_subject}_3T
	fi
	inform "Connectome DB Session: ${g_session}"

	if [ -z "${g_output_resource}" ]; then
		g_output_resource="${DEFAULT_RESOURCE_NAME}"
	fi
	inform "output resource: ${g_output_resource}"

	if [ -z "${g_setup_script}" ]; then
		inform "ERROR: set up script (--setup-script=) required"
		exit 1
	else
		inform "setup script: ${g_setup_script}"
	fi
}

main()
{
	get_options $@

	inform "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	current_seconds_since_epoch=`date +%s`
	working_directory_name="${BUILD_HOME}/${g_project}/AddResolutionPatchHCP7T.${g_subject}.${current_seconds_since_epoch}"

	# Make the working directory
	inform "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Submit job to actually do the work
	script_file_to_submit=${working_directory_name}/${g_subject}.AddResolutionPatchHCP7T.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
	if [ -e "${script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	touch ${script_file_to_submit}
	chmod 700 ${script_file_to_submit}

	echo "#PBS -l nodes=1:ppn=1,walltime=1:00:00,vmem=4000mb" >> ${script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
	echo "" >> ${script_file_to_submit}
	echo "${HOME}/pipeline_tools/xnat_pbs_jobs/7T/AddResolutionPatchHCP7T/AddResolutionPatchHCP7T.XNAT.sh \\" >> ${script_file_to_submit}
	echo "  --user=\"${g_user}\" \\" >> ${script_file_to_submit}
	echo "  --password=\"${g_password}\" \\" >> ${script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
	echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
	echo "  --session=\"${g_session}\" \\" >> ${script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
	echo "  --setup-script=${g_setup_script}" >> ${script_file_to_submit}

	submit_cmd="qsub ${script_file_to_submit}"
	inform "submit_cmd: ${submit_cmd}"

	processing_job_no=`${submit_cmd}`
	inform "processing_job_no: ${processing_job_no}"

	# Submit job to put the results in the DB
	put_script_file_to_submit=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
	if [ -e "${put_script_file_to_submit}" ]; then
		rm -f "${put_script_file_to_submit}"
	fi

	touch ${put_script_file_to_submit}
	chmod 700 ${put_script_file_to_submit}

	echo "#PBS -l nodes=1:ppn=1,walltime=2:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
	echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
	echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
	echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
	echo "" >> ${put_script_file_to_submit}
	echo "${HOME}/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/XNAT_working_dir_files_put.sh \\" >> ${put_script_file_to_submit}
	echo "  --user=\"${g_user}\" \\" >> ${put_script_file_to_submit}
	echo "  --password=\"${g_password}\" \\" >> ${put_script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${put_script_file_to_submit}
	echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
	echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
	echo "  --resource-suffix=\"${g_output_resource}\" \\" >> ${put_script_file_to_submit}
	echo "  --reason=\"${PIPELINE_NAME}\" " >> ${put_script_file_to_submit}

	submit_cmd="qsub -W depend=afterok:${processing_job_no} ${put_script_file_to_submit}"
	inform "submit_cmd: ${submit_cmd}"
	${submit_cmd}
}

# Invoke the main function to get things started
main $@
