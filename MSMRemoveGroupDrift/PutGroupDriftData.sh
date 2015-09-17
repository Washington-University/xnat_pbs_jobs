#!/bin/bash
set -e

echo "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to set up the environment 
SCRIPTS_HOME=/home/HCPpipeline/SCRIPTS
echo "SCRIPTS_HOME: ${SCRIPTS_HOME}"

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
echo "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs
echo "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# Load Function Libraries
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

# Database Resource names and suffixes
echo "Defining Database Resource Names and Suffixes"
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/ResourceNamesAndSuffixes.sh

# Show script usage information
usage()
{
	echo ""
	echo "  Compute Group Registration Drift"
	echo ""
	echo "  Usage: MSMRemoveGroupDrift.XNAT.sh <options>"
	echo ""
	echo "  To Be Written"
	echo ""
}

# Parse specified command line options and verify that required options are
# specified. "Return" the options to use in global variables.
get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_server
	unset g_subject_info_file
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
			--subject-info-file=*)
				g_subject_info_file=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument/*=/""}
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

	if [ -z "${g_subject_info_file}" ]; then
		echo "ERROR: subject info file (--subject-info-file=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_subject_info_file: ${g_subject_info_file}"
	fi

	if [ -z "${g_working_dir}" ]; then
		echo "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_working_dir: ${g_working_dir}"
	fi

	# exit if errors occurred

	if [ ${error_count} -gt 0 ]; then
		echo "For usage information, use --help"
		exit 1
	fi
}

get_subject_info_list()
{
	local file_name="${1}"
	echo "Retrieving subject info list from: ${file_name}"
	local subject_info_from_file=( $( cat ${file_name} ) )
	g_subjects_info="`echo "${subject_info_from_file[@]}"`"
	if [ -z "${g_subjects_info}" ]; then
		echo "ERROR: No Subjects Specified" 
		exit 1
	fi
}

get_project()
{
	local subject_info="${1}"
	local project=`echo ${subject_info} | cut -d ":" -f 1`
	echo ${project}
}

get_subject()
{
	local subject_info="${1}"
	local subject=`echo ${subject_info} | cut -d ":" -f 2`
	echo ${subject}
}

get_session()
{
	local subject_info="${1}"
	local session=`echo ${subject_info} | cut -d ":" -f 3`
	echo ${session}
}

push_subject_files_to_db()
{
	local project
	local subject
	local session
	local db_working_dir

	for subject_info in ${g_subjects_info} ; do
		project=`get_project ${subject_info}`
		subject=`get_subject ${subject_info}`
		session=`get_session ${subject_info}`
		echo "Pushing data to project: ${project} for subject: ${subject} in session ${session}"

		echo "-------------------------------------------------"
		echo "Deleting previous resource"	
		echo "-------------------------------------------------"
		${XNAT_PBS_JOBS_HOME}/WorkingDirPut/DeleteResource.sh \
			--user="${g_user}" \
			--password="${g_password}" \
			--server="${g_server}" \
			--project="${project}" \
			--subject="${subject}" \
			--session="${session}" \
			--resource="${MSM_ALL_DEDRIFT_RESOURCE_NAME}" \
			--force
		
		db_working_dir=${g_working_dir/HCP/data}/${subject}
		echo "-------------------------------------------------"
		echo "Putting new data into DB from db_working_dir: ${db_working_dir}"
		echo "-------------------------------------------------"
		${XNAT_PBS_JOBS_HOME}/WorkingDirPut/PutDirIntoResource.sh \
			--user="${g_user}" \
			--password="${g_password}" \
			--server="${g_server}" \
			--project="${project}" \
			--subject="${subject}" \
			--session="${session}" \
			--resource="${MSM_ALL_DEDRIFT_RESOURCE_NAME}" \
			--reason="MSMAllRemoveGroupDrift" \
			--dir="${db_working_dir}" \
			--force

		echo "-------------------------------------------------"
		echo "Deleting pushed data"
		echo "-------------------------------------------------"
		rm_cmd="rm -rf ${db_working_dir}"
		echo "rm_cmd: ${rm_cmd}"
		${rm_cmd}
		echo "rm_cmd return code: $?"
	done
}

push_group_files_to_db()
{
	echo "Pushing group stuff - not really, this is just a placeholder"
}

#
# Main processing
#
main() 
{
	# get user specified command line options
	get_options $@

	# get list of subjects
	get_subject_info_list ${g_subject_info_file}

	# push files generated for individual subjects into DB
	push_subject_files_to_db

	# push group files into DB
	push_group_files_to_db
}

# Invoke the main function to get things started
main $@