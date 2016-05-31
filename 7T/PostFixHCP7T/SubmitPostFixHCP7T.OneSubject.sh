#!/bin/bash

# This pipeline's name 
PIPELINE_NAME="PostFixHCP7T"
SCRIPT_NAME="SubmitPostFixHCP7T.OneSubject.sh"

# echo a message with the script name as a prefix
inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${HOME}/pipeline_tools/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=${HOME}/pipeline
inform "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# Root directory for HCP data
HCP_DATA_ROOT="/HCP"
inform "HCP_DATA_ROOT: ${HCP_DATA_ROOT}"

# main build directory
BUILD_HOME="${HCP_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD"
echo "BUILD_HOME: ${BUILD_HOME}"

# set up to run Python
echo "Setting up to run Python"
source ${SCRIPTS_HOME}/epd-python_setup.sh

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="${HCP_DATA_ROOT}/hcpdb/archive"
echo "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

RESTING_STATE_FMRI_PREFIX="rfMRI"
TASK_FMRI_PREFIX="tfMRI"

UNPROCESSED_SUFFIX="unproc"

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
	unset g_put_server
	unset g_clean_output_resource_first
	unset g_setup_script
	unset g_scan

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
			--put-server=*)
				g_put_server=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--do-not-clean-first)
				g_clean_output_resource_first="FALSE"
				index=$(( index + 1 ))
				;;
			--setup-script=*)
				g_setup_script=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--scan=*)
				g_scan=${argument/*=/""}
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
		g_server="db.humanconnectome.org"
	fi
	inform "Connectome DB Server: ${g_server}"

	if [ -z "${g_project}" ]; then
		g_project="HCP_Staging_7T"
	fi
    inform "Connectome DB Project: ${g_project}"

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi
	inform "Connectome DB Subject: ${g_subject}"

	if [ -z "${g_session}" ]; then
		g_session=${g_subject}_7T
	fi
	inform "Connectome DB Session: ${g_session}"

	if [ -z "${g_put_server}" ]; then
		g_put_server="db.humanconnectome.org"
	fi
	inform "PUT server: ${g_put_server}"

	if [ -z "${g_clean_output_resource_first}" ]; then
		g_clean_output_resource_first="TRUE"
	fi
	inform "clean output resource first: ${g_clean_output_resource_first}"

	if [ -z "${g_setup_script}" ]; then
		inform "ERROR: set up script (--setup-script=) required"
		exit 1
	else
		inform "set up script: ${g_setup_script}"
	fi
}

main()
{
	get_options $@

	# Determine what FIX processed scans are available for the subject
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES

    resting_state_scan_names=""
    resting_state_scan_dirs=`ls -d ${RESTING_STATE_FMRI_PREFIX}_*_${UNPROCESSED_SUFFIX}`
    for resting_state_scan_dir in ${resting_state_scan_dirs} ; do
        scan_name=${resting_state_scan_dir%%_${UNPROCESSED_SUFFIX}}
        scan_name=${scan_name##${RESTING_STATE_FMRI_PREFIX}_}
        resting_state_scan_names=${resting_state_scan_names//$scan_name/}
        resting_state_scan_names+=" ${scan_name}"
    done

	popd

	inform "Resting state scans available for subject: ${resting_state_scan_names}"

    # Determine what task scans are available for the subject                                                                                        
    pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES

    task_scan_names=""
    task_scan_dirs=`ls -d ${TASK_FMRI_PREFIX}_*_${UNPROCESSED_SUFFIX}`
    for task_scan_dir in ${task_scan_dirs} ; do
        scan_name=${task_scan_dir%%_${UNPROCESSED_SUFFIX}}
        scan_name=${scan_name##${TASK_FMRI_PREFIX}_}
        task_scan_names=${task_scan_names//$scan_name/}
        task_scan_names+=" ${scan_name}"
    done

    popd

    inform "Task scans available for subject: ${task_scan_names}"

	# Determine what FIX processed scans are available for the subject
    pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES

	fix_processed_scan_names=""
	fix_processed_scan_dirs=`ls -d *_FIX`

	for fix_processed_scan_dir in ${fix_processed_scan_dirs} ; do
		scan_name=${fix_processed_scan_dir%%_FIX}
		scan_name=${scan_name##${RESTING_STATE_FMRI_PREFIX}_}
		scan_name=${scan_name##${TASK_FMRI_PREFIX}_}
		fix_processed_scan_names+=" ${scan_name}"
	done
	popd

	inform "FIX processed scans available for subject: ${fix_processed_scan_names}"

	if [ -z "${g_scan}" ]; then
		# user did not specify a particular scan, so do 'em all
		scan_list="${fix_processed_scan_names}"
	else
		# user specified a particular scan, e.g REST1_PA, REST2_AP, MOVIE1_AP, MOVIE2_PA, etc.
		scan_list="${g_scan}"
	fi

	# Submit jobs

	for scan_name in ${scan_list} ; do
		inform "scan_name: ${scan_name}"

		resting_match_check=${resting_state_scan_names#*${scan_name}}
        task_match_check=${task_scan_names#*${scan_name}}

        if [ "${resting_match_check}" != "${resting_state_scan_names}" ] ; then
            inform "${scan_name} is a resting state scan"
            prefix="${RESTING_STATE_FMRI_PREFIX}"
        elif [ "${task_match_check}" != "${task_scan_names}" ] ; then
            inform "${scan_name} is a task scan"
            prefix="${TASK_FMRI_PREFIX}"
        else
            inform "Unable to determine whether ${scan_name} is a resting state or task scan"
            inform "ABORTING"
            exit 1
        fi

		scan="${prefix}_${scan_name}" # e.g. tfMRI_MOVIE4_AP

		# e.g. ${scan_name} = MOVIE4_AP
		scan_without_pe_dir=${scan_name%_*} # scan_without_pe_dir = MOVIE4
		inform "scan_without_pe_dir: ${scan_without_pe_dir}"
		pe_dir=${scan_name##*_} # pe_dir = AP
		inform "pe_dir: ${pe_dir}"

		scan="${prefix}_${scan_without_pe_dir}_7T_${pe_dir}"
		inform "scan: ${scan}" # tfMRI_MOVIE4_7T_AP

		output_resource="${prefix}_${scan_without_pe_dir}_${pe_dir}_PostFix"
		inform "output_resource: ${output_resource}"

		inform "--------------------------------------------------"
		inform "Submitting jobs for scan: ${scan}"
		inform "--------------------------------------------------"

		# make sure working directories don't have the same name based on the 
		# same start time by sleeping a few seconds
		sleep 5s

		current_seconds_since_epoch=`date +%s`
		working_directory_name="${BUILD_HOME}/${g_project}/${PIPELINE_NAME}.${g_subject}.${scan}.${current_seconds_since_epoch}"

		# Make the working directory
		inform "Making working directory: ${working_directory_name}"
		mkdir -p ${working_directory_name}

		# Get JSESSION ID
		inform "Getting JSESSION ID"
		jsession=`curl -u ${g_user}:${g_password} https://db.humanconnectome.org/data/JSESSION`
		inform "jsession: ${jsession}"

		# Get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
		inform "Getting XNAT Session ID"
		get_session_id_cmd=""
		get_session_id_cmd+="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py "
		get_session_id_cmd+=" --server=db.humanconnectome.org "
		get_session_id_cmd+=" --username=${g_user} "
		get_session_id_cmd+=" --project=${g_project} "
		get_session_id_cmd+=" --subject=${g_subject} "
		get_session_id_cmd+=" --session=${g_session} "
		get_session_id_cmd+=" --password=${g_password}"

		sessionID=`${get_session_id_cmd}`
		inform "XNAT session ID: ${sessionID}"

		# Get XNAT Workflow ID
		server="https://db.humanconnectome.org/"
		echo "Getting XNAT workflow ID for this job from server: ${server}"
		get_workflow_id_cmd=""
		get_workflow_id_cmd+="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py"
		get_workflow_id_cmd+=" -User ${g_user} "
		get_workflow_id_cmd+=" -Server ${server} "
		get_workflow_id_cmd+=" -ExperimentID ${sessionID} "
		get_workflow_id_cmd+=" -ProjectID ${g_project} "
		get_workflow_id_cmd+=" -Pipeline ${PIPELINE_NAME}_${scan} "
		get_workflow_id_cmd+=" -Status Queued "
		get_workflow_id_cmd+=" -JSESSION ${jsession} "
		get_workflow_id_cmd+=" -Password ${g_password} "

		workflowID=`${get_workflow_id_cmd}`
		if [ $? -ne 0 ]; then
			inform "Fetching workflow failed. Aborting"
			inform "workflowID: ${workflowID}"
			exit 1
		elif [[ ${workflowID} == HTTP* ]]; then
			inform "Fetching workflow failed. Aborting"
			inform "worflowID: ${workflowID}"
			exit 1
		fi
		inform "XNAT workflow ID: ${workflowID}"

		# Clean the output resource (unless told not to)
		if [ "${g_clean_output_resource_first}" = "TRUE" ] ; then
			inform "Deleting resource: ${output_resource} for:"
			inform "  project: ${g_project}"
			inform "  subject: ${g_subject}"
			inform "  session: ${g_session}"

			${HOME}/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/DeleteResource.sh \
				--user=${g_user} \
				--password=${g_password} \
				--server=${g_server} \
				--project=${g_project} \
				--subject=${g_subject} \
				--session=${g_session} \
				--resource=${output_resource} \
				--force
		fi

		# Submit job to actually do the work
		script_file_to_submit=${working_directory_name}/${g_subject}.${scan}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=12:00:00,vmem=16gb" >> ${script_file_to_submit}
		echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
		echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
		echo "" >> ${script_file_to_submit}
		echo "${XNAT_PBS_JOBS_HOME}/7T/PostFixHCP7T/PostFixHCP7T.XNAT.sh \\" >> ${script_file_to_submit}
		echo "  --user=\"${g_user}\" \\" >> ${script_file_to_submit}
		echo "  --password=\"${g_password}\" \\" >> ${script_file_to_submit}
		echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${script_file_to_submit}
		echo "  --scan=\"${scan}\" \\" >> ${script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
		echo "  --workflow-id=\"${workflowID}\" \\" >> ${script_file_to_submit} 
		echo "  --setup-script=${g_setup_script}"   >> ${script_file_to_submit}

		chmod +x ${script_file_to_submit}

		submit_cmd="qsub ${script_file_to_submit}"
		inform "submit_cmd: ${submit_cmd}"

		processing_job_no=`${submit_cmd}`
		inform "processing_job_no: ${processing_job_no}"

		if [ -z "${processing_job_no}" ] ; then
			inform "ERROR SUBMITTING PROCESSING JOB - ABORTING"
			exit 1
		fi

		# Submit job to put the results in the DB
		put_script_file_to_submit=${working_directory_name}/${g_subject}.${scan}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
		if [ -e "${put_script_file_to_submit}" ]; then
			rm -f "${put_script_file_to_submit}"
		fi

		touch ${put_script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=12000mb" >> ${put_script_file_to_submit}
		echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
		echo "#PBS -o ${LOG_DIR}" >> ${put_script_file_to_submit}
		echo "#PBS -e ${LOG_DIR}" >> ${put_script_file_to_submit}
		echo "" >> ${put_script_file_to_submit}
		echo "${XNAT_PBS_JOBS_HOME}/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
		echo "  --user=\"${g_user}\" \\" >> ${put_script_file_to_submit}
		echo "  --password=\"${g_password}\" \\" >> ${put_script_file_to_submit}
		echo "  --server=\"${g_put_server}\" \\" >> ${put_script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
		echo "  --scan=\"${g_scan}\" \\" >> ${put_script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
		echo "  --resource-suffix=\"${output_resource}\" \\" >> ${put_script_file_to_submit}
		echo "  --reason=\"${scan}_${PIPELINE_NAME}\" " >> ${put_script_file_to_submit}

		chmod +x ${put_script_file_to_submit}
		
		put_submit_cmd="qsub -W depend=afterok:${processing_job_no} ${put_script_file_to_submit}"
		inform "put_submit_cmd: ${put_submit_cmd}"

		put_job_no=`${put_submit_cmd}`
		inform "put_job_no: ${put_job_no}"

	done
}

# Invoke the main function to get things started
main $@
