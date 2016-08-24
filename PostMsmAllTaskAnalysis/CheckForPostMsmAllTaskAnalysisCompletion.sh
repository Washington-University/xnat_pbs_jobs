#!/bin/bash

ARCHIVE_PROJ_SUBDIR="arc001"
TESLA_SPEC="_3T"
HCP_PIPELINES_VERSION="v3.11.0"

usage() {
	echo "Usage information TBW"
}

get_options() {
    local arguments=($@)

    # initialize global output variables
    unset g_project
	unset g_subject
	unset g_details
	g_details="FALSE"

    # parse arguments
    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --help)
                usage
                exit 1
                ;;
            --project=*)
                g_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --subject=*)
                g_subject=${argument/*=/""}
                index=$(( index + 1 ))
				;;
			--details)
				g_details="TRUE"
				index=$(( index + 1 ))
                ;;
            *)
                echo "Unrecognized Option: ${argument}"
                usage
                exit 1
                ;;
        esac
    done

    # check required parameters
	local error_count=0

    if [ -z ${g_project} ]; then
        echo "ERROR: --project=<project-name> is required."
        error_count=$(( error_count + 1 ))
    fi

    if [ -z ${g_subject} ]; then
        echo "ERROR: --subject=<subject-id> is required."
        error_count=$(( error_count + 1 ))
    fi

	if [ "${error_count}" -gt 0 ]; then
		usage
		exit 1
	fi
}

main() {

	host=`hostname`
	domain=`domainname`
	if [ "${host}" = "hcpx-fs01.nrg.mir" ] ; then
		archive_root="/data/hcpdb/archive"
	elif [[ ${host} == login* ]] ; then
		archive_root="/HCP/hcpdb/archive"
	else
		echo "ERROR: This script is intended to be run either on host: hcpx-fs01.nrg.mir"
		echo "ERROR: or on a CHPC login node"
		exit 1
	fi

	get_options $@

	if [ "${g_details}" = "TRUE" ]; then
		echo ""
		echo "Project: ${g_project}"
		echo "Subject: ${g_subject}"
	fi

	presentDir=`pwd`
	archiveDir="${archive_root}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"
	#echo "archiveDir: ${archiveDir}"

	# Figure out what preprocessed tfMRI (task) scans the subject has
	pushd ${archiveDir}/RESOURCES > /dev/null

	task_scan_dirs=`find . -maxdepth 1 -name "tfMRI*_preproc"`
	task_scan_dirs=${task_scan_dirs//\.\//}

	popd > /dev/null

	#echo "task_scan_dirs: ${task_scan_dirs}"

	preprocessed_tasks=""
	for task_scan_dir in ${task_scan_dirs} ; do
		# take _preproc off the end
		task_scan=${task_scan_dir%%_preproc}
		# take tfMRI_ off the beginning
		task_scan=${task_scan##tfMRI_}
		# take the direction specifier (_RL, _LR, _AP, _PA) off the end
		task_scan=${task_scan%_*}

		# To avoid duplicates being added to the preprocessed tasks list,
		# remove this task if it is already in the preprocessed tasks list,
		# then add it. (A little awkward, but an easy two liner to avoid 
		# duplication.  It also results in extra spaces in the preprocessed
		# tasks list, but who cares?)
#		preprocessed_tasks=${preprocessed_tasks//${task_scan}/}  # removes ${task_scan} from ${preprocessed_tasks}
		preprocessed_tasks+="${task_scan} "
	done

	length_preprocessed_tasks=${#preprocessed_tasks}

	#echo "Preprocessed Tasks found for subject: ${g_subject} are: ${preprocessed_tasks}"

	possible_tasks=""
	possible_tasks+="EMOTION "
	possible_tasks+="GAMBLING "
	possible_tasks+="LANGUAGE "
	possible_tasks+="MOTOR "
	possible_tasks+="RELATIONAL "
	possible_tasks+="SOCIAL "
	possible_tasks+="WM "
	
	for task in ${possible_tasks} ; do
		length_task=${#task}

		# should Post MSM-All Task Analysis exist?
		tmp=${preprocessed_tasks//${task}/} # tmp is ${preprocessed_tasks} less the current ${task}
		length_tmp=${#tmp}

		#echo "preprocessed_tasks: '${preprocessed_tasks}'"
		#echo "length_preprocessed_tasks: ${length_preprocessed_tasks}"

		#echo "task: '${task}'"
		#echo "length_task: ${length_task}"

		#echo "tmp: ${tmp}"
		#echo "length_tmp: ${length_tmp}"

		length_tmp_if_no_matches=${length_preprocessed_tasks}
		let "length_tmp_if_one_match = length_preprocessed_tasks - length_task"
		let "length_tmp_if_two_matches = length_preprocessed_tasks - (2 * length_task)"				

		if [ ${length_tmp} -eq ${length_tmp_if_no_matches} ] ; then
			# Taking ${task} out of ${preprocessed_tasks} didn't take anything out.
			# So this subject didn't have the current ${task} as one of its ${preprocessed_tasks}.
			#echo "NO MATCHES"
			should_resource_exist="---"
			resource_exists="---"
			all_files_exist="---"

		elif [ ${length_tmp} -eq ${length_tmp_if_one_match} ] ; then
			# Taking ${task} out of ${preprocessed_tasks} only took out 1 copy of ${task}.
			# So this subject only had one phase encoding direction of ${task}.  Task Analysis 
			# cannot be completed.
			#echo "ONE MATCH"
			should_resource_exist="---"
			resource_exists="---"
			all_files_exist="---"
			
		elif [ ${length_tmp} -eq ${length_tmp_if_two_matches} ] ; then
			#echo "TWO MATCHES"
			# ${task} IS in the ${preprocessed_tasks},
			# So it should have a corresponding Post MSM-All Task Analysis resource
			should_resource_exist="TRUE"

			# Does the Post MSM-All Task Analysis Resource exist
			post_msm_all_task_analysis_resource=${archiveDir}/RESOURCES/tfMRI_${task}_PostMsmAllTaskAnalysis

			if [ -d "${post_msm_all_task_analysis_resource}" ] ; then
				resource_exists="TRUE"
				all_files_exist="UNCHECKED"

				files=""

				# Level 2 Analysis, smoothing 2
				check_dir="${post_msm_all_task_analysis_resource}/MNINonLinear/Results/tfMRI_${task}/tfMRI_${task}_hp200_s2_level2_MSMAll.feat"
				files+=" ${check_dir}/${g_subject}_tfMRI_${task}_level2_hp200_s2_MSMAll.dscalar.nii"

				# Level 2 Analysis, smoothing 4
				check_dir="${post_msm_all_task_analysis_resource}/MNINonLinear/Results/tfMRI_${task}/tfMRI_${task}_hp200_s4_level2_MSMAll.feat"
				files+=" ${check_dir}/${g_subject}_tfMRI_${task}_level2_hp200_s4_MSMAll.dscalar.nii"
				
				# Level 1 Analysis (LR), smoothing 2
				check_dir="${post_msm_all_task_analysis_resource}/MNINonLinear/Results/tfMRI_${task}_LR"
				files+=" ${check_dir}/tfMRI_${task}_LR_Atlas_hp200_s2_MSMAll.dtseries.nii"
				files+=" ${check_dir}/tfMRI_${task}_LR_Atlas_s2_MSMAll.dtseries.nii"

				# Level 1 Analysis (LR), smoothing 4
				files+=" ${check_dir}/tfMRI_${task}_LR_Atlas_hp200_s4_MSMAll.dtseries.nii"
				files+=" ${check_dir}/tfMRI_${task}_LR_Atlas_s4_MSMAll.dtseries.nii"

				# Level 1 Analysis (RL), smoothing 2
				check_dir="${post_msm_all_task_analysis_resource}/MNINonLinear/Results/tfMRI_${task}_RL"
				files+=" ${check_dir}/tfMRI_${task}_RL_Atlas_hp200_s2_MSMAll.dtseries.nii"
				files+=" ${check_dir}/tfMRI_${task}_RL_Atlas_s2_MSMAll.dtseries.nii"

				# Level 1 Analysis (RL), smoothing 4
				files+=" ${check_dir}/tfMRI_${task}_RL_Atlas_hp200_s4_MSMAll.dtseries.nii"
				files+=" ${check_dir}/tfMRI_${task}_RL_Atlas_s4_MSMAll.dtseries.nii"

				all_files_exist="TRUE"
				for filename in ${files} ; do
					if [ ! -e "${filename}" ] ; then
						all_files_exist="FALSE"
						
						if [ "${g_details}" = "TRUE" ]; then
							echo "Does not exist: ${filename}"
						fi
					fi
				done

			else
				resource_exists="FALSE"
				all_files_exist="FALSE"

			fi

		else
			echo -e "ERROR unrecognized number of matches"

		fi

		# output results
		echo -e "${g_subject}\t\t${g_project}\t${HCP_PIPELINES_VERSION}\ttfMRI_${task}_PostMsmAllTaskAnalysis\t${should_resource_exist}\t${resource_exists}\t${all_files_exist}"

	done
}

main $@
