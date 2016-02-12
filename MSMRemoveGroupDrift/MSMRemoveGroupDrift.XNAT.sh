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

create_input_data_dir()
{
	# VERY IMPORTANT NOTE:
	# 
	# Since ConnectomeDB resources contain overlapping files (e.g. the functionally preprocessed 
	# data resource may contain some of the exact same files as the structurally preprocessed
	# data resource), extra care must be taken with the order in which data is linked in to the
	# working directory.  
	#
	# If, for example, a file named ${subject}/subdir1/subdir2/this_file.nii.gz exists in both
	# the structurally preprocessed data resource and in the functionally preprocessed data 
	# resource, whichever resource we link in to the working directory _first_ will take 
	# precedence.  (This is due to the behavior of the lndir command used by the link_hcp...
	# functions, and is unlike the behavior of the rsync command used by the get_hcp...
	# functions. The rsync command will copy/update the newer version of the file from its
	# source.) 
	#
	# The lndir command will report to stderr any links that it could not (would not) create 
	# because they already exist in the destination directories.
	# 
	# So, if we link in the structurally preprocessed data first and then link in the functionally
	# preprocessed data second, the file ${subject}/subdir1/subdir2/this_file.nii.gz in the 
	# working directory will be linked back to the structurally preprocessed version of the file.
	#
	# Since functional preprocessing comes _after_ structural preprocessing, this is not likely
	# to be what we want.  Instead, we want the file as it exists after functional preprocessing
	# to be the one that is linked in to the working directory.
	#
	# Therefore, it is important to consider the order in which we call the link_hcp... functions
	# below.  We should call them in order from the results of the latest prerequisite pipelines 
	# to the earliest prerequisite pipelines.

	local subject=""
	local session=""
	local project=""

	mkdir -p ${g_working_dir}

	for subject_info in ${g_subjects_info} ; do 
		echo "subject_info: ${subject_info}"

		project=`get_project ${subject_info}`
		subject=`get_subject ${subject_info}`
		session=`get_session ${subject_info}`
		echo "Linking data from project: ${project} for subject: ${subject} from session ${session}"

		# link MSM All registration data from DB
		link_hcp_msm_all_registration_data "${DATABASE_ARCHIVE_ROOT}" "${project}" "${subject}" "${session}" "${g_working_dir}"

		# link structurally preprocessed data from DB
		link_hcp_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${project}" "${subject}" "${session}" "${g_working_dir}"
	done
}

create_start_time_file()
{
	local file_name=${1}
	
	# remove old file if it exists
	if [ -e "${file_name}" ]; then
		echo "Removing old ${file_name}"
		rm -f ${file_name}
	fi

	# sleep for 1 minute prior to creating file
	# this is to make sure file is create at least a minute after any 
	# input data files copied or linked prior to calling this function
	echo "Sleep for 1 minute prior to creating ${file_name}"
	sleep 1m

	echo "Creating file: ${file_name}"
	touch ${file_name}
	ls -l ${file_name}
	
	# sleep for 1 minute after creating file
	# this is to make sure any files created by processing 
	# are created at least 1 minute after the created start time file
	echo "Sleep for 1 minute after creating ${file_name}"
	sleep 1m
}

create_subject_list()
{
	g_subject_list=""
	local subject_info
	local subject

	for subject_info in ${g_subjects_info} ; do
		subject=`get_subject ${subject_info}`
		echo "subject: ${subject}"
		if [ ! -z "${g_subject_list}" ]; then
			g_subject_list+="@"
		fi
		g_subject_list+="${subject}"
	done
}

#
# Main processing
#
main() 
{
	# get user specified command line options
	get_options $@

	echo "----- Platform Information: Begin -----"
	uname -a
	echo "----- Platform Information: End -----"

	# get list of subjects
	get_subject_info_list ${g_subject_info_file}

	# build linked tree of all necessary data
	create_input_data_dir

	# create a start time file
	start_time_file=${g_working_dir}/MSMRemoveGroupDrift.starttime
	create_start_time_file ${start_time_file}

	# convert subject info for passing as a single argument subject list
	create_subject_list
	echo "g_subject_list: ${g_subject_list}"

	study_folder="${g_working_dir}"
	group_average_name="DeDriftingGroup"

	# do the actual work by running the MSMRemoveGroupDrift.sh script
	source ${SCRIPTS_HOME}/SetUpHCPPipeline_MSMRemoveGroupDrift.sh
	${HCPPIPEDIR}/MSMRemoveGroupDrift/MSMRemoveGroupDrift.sh \
		--path=${study_folder} \
		--subject-list=${g_subject_list} \
		--common-folder=${study_folder}/${group_average_name} \
		--group-average-name=${group_average_name} \
		--input-registration-name="MSMAll_InitalReg_2_d40_WRN" \
		--target-registration-name="MSMSulc" \
		--registration-name="DeDriftMSMAll" \
		--high-res-mesh=164 \
		--low-res-mesh=32

	# show any newly created or modified files
	echo "Newly created/modified files:"
	find ${g_working_dir} -type f -newer ${start_time_file}

	# remove any files that are not newly created or modified
	find ${g_working_dir} -not -name "*.XNAT_PBS_job.sh" -not -newer ${start_time_file} -delete
}

# Invoke the main function to get things started
main $@