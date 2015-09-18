#!/bin/bash
set -e

echo "Job started on `hostname` at `date`"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs
echo "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# Database Resource names and suffixes
echo "Defining Database Resource Names and Suffixes"
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/ResourceNamesAndSuffixes.sh

# Show script usage information
usage()
{
	echo ""
	echo "  Put Group Drift Data in XNAT DB"
	echo ""
	echo "  Usage: PutGroupDriftData.sh <options>"
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
	unset g_project
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

	if [ -z "${g_project}" ]; then
		echo "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_project: ${g_project}"
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

push_group_files_to_db()
{
	echo "Pushing data to project ${g_project}"

	echo "-------------------------------------------------"
	echo "Deleting previous resource"	
	echo "-------------------------------------------------"
	${XNAT_PBS_JOBS_HOME}/WorkingDirPut/DeleteProjectLevelResource.sh \
		--user="${g_user}" \
		--password="${g_password}" \
		--server="${g_server}" \
		--project="${g_project}" \
		--resource="${MSM_ALL_DEDRIFT_RESOURCE_NAME}" \
		--force

	# Make processing job log files readable so they can be pushed into the database
	chmod a+r ${g_working_dir}/*

	db_working_dir=${g_working_dir/HCP/data}
	echo "-------------------------------------------------"
	echo "Putting new data into DB from db_working_dir: ${db_working_dir}"
	echo "-------------------------------------------------"
	${XNAT_PBS_JOBS_HOME}/WorkingDirPut/PutDirIntoProjectLevelResource.sh \
		--user="${g_user}" \
		--password="${g_password}" \
		--server="${g_server}" \
		--project="${g_project}" \
		--resource="${MSM_ALL_DEDRIFT_RESOURCE_NAME}" \
		--reason="MSMAllRemoveGroupDrift" \
		--dir="${db_working_dir}" \
		--force

	echo "-------------------------------------------------"
	echo "Cleanup"
	echo "-------------------------------------------------"
	echo "Removing g_working_dir: ${g_working_dir}"
	rm -rf ${g_working_dir}
}

#
# Main processing
#
main() 
{
	# get user specified command line options
	get_options $@

	# push group files into DB
	push_group_files_to_db
}

# Invoke the main function to get things started
main $@
