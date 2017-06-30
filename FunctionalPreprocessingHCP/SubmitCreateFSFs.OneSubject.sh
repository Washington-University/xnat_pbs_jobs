#!/bin/bash

# This pipeline's name 
PIPELINE_NAME="CreateFSFs"

# main build directory
BUILD_HOME="/HCP/hcpdb/build_ssd/chpc/BUILD"
echo "BUILD_HOME: ${BUILD_HOME}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs
echo "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
echo "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

POSITIVE_PHASE_ENCODING_DIR=RL
NEGATIVE_PHASE_ENCODING_DIR=LR

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_project
	unset g_subject
	unset g_session
	unset g_put_server

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
			*)
				echo "ERROR: unrecognized option: ${argument}"
				echo ""
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

	if [ -z "${g_project}" ]; then
		g_project="HCP_Staging"
	fi
    echo "Connectome DB Project: ${g_project}"

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi
	echo "Connectome DB Subject: ${g_subject}"

	if [ -z "${g_session}" ]; then
		g_session=${g_subject}_3T
	fi
	echo "Connectome DB Session: ${g_session}"

	if [ -z "${g_put_server}" ]; then
		g_put_server="${XNAT_PBS_JOBS_XNAT_SERVER}"
	fi
	echo "PUT server: ${g_put_server}"
}

main()
{
	get_options $@

	# Determine what task scans are available for the subject
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES
	
	task_scan_names=""
	task_scan_dirs=`ls -d tfMRI_*_unproc`
	for task_scan_dir in ${task_scan_dirs} ; do
		scan_name=${task_scan_dir%%_unproc}
		scan_name=${scan_name%%_${NEGATIVE_PHASE_ENCODING_DIR}}
		scan_name=${scan_name%%_${POSITIVE_PHASE_ENCODING_DIR}}
		scan_name=${scan_name##tfMRI_}
		task_scan_names=${task_scan_names//$scan_name/}
		task_scan_names+=" ${scan_name}"
	done

	popd

	echo "Task scans available for subject: ${task_scan_names}"

	# Submit jobs for each task scan 

	for scan_name in ${task_scan_names} ; do

		echo "scan_name: ${scan_name}"
		
		prefix="tfMRI"

		# ------------------------------------------------------
		#  Submit job for creating FSFs
		# ------------------------------------------------------

		current_seconds_since_epoch=`date +%s`
		create_fsfs_working_dir="${BUILD_HOME}/${g_project}/CreateFSFs.${g_subject}.${scan_name}.${current_seconds_since_epoch}"
		mkdir -p ${create_fsfs_working_dir}

		# create file to submit
		create_fsfs_file_to_submit=${XNAT_PBS_JOBS_LOG_DIR}/${g_subject}.${prefix}_${scan_name}.CreateFSFs.${g_project}.${g_session}.${current_seconds_since_epoch}.PBS.job.sh
		if [ -e "${create_fsfs_file_to_submit}" ]; then
			rm -f "${create_fsfs_file_to_submit}"
		fi

		put_server_without_port=${g_put_server%:*}
		scan_without_dir=${prefix}_${scan_name}

		touch ${create_fsfs_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=12000mb" >> ${create_fsfs_file_to_submit}
		echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${create_fsfs_file_to_submit}
		echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${create_fsfs_file_to_submit}
		echo "" >> ${create_fsfs_file_to_submit}
		echo "${XNAT_PBS_JOBS_HOME}/FunctionalPreprocessingHCP/CreateFSFs.sh \\" >> ${create_fsfs_file_to_submit}
 		echo "  --user=\"${g_user}\" \\" >> ${create_fsfs_file_to_submit}
 		echo "  --password=\"${g_password}\" \\" >> ${create_fsfs_file_to_submit}
		echo "  --server=\"${put_server_without_port}\" \\" >> ${create_fsfs_file_to_submit}
		echo "  --working-dir=\"${create_fsfs_working_dir}\" \\" >> ${create_fsfs_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${create_fsfs_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${create_fsfs_file_to_submit}
		echo "  --series=\"${scan_without_dir}\" " >> ${create_fsfs_file_to_submit}

		chmod +x ${create_fsfs_file_to_submit}

		create_fsfs_submit_cmd="qsub ${create_fsfs_file_to_submit}"
		echo "create_fsfs_submit_cmd: ${create_fsfs_submit_cmd}"

		create_fsfs_job_no=`${create_fsfs_submit_cmd}`
		echo "create_fsfs_job_no: ${create_fsfs_job_no}"

	done # scan_name 
}

# Invoke the main function to get things started
main $@
