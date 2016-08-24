#!/bin/bash

ARCHIVE_ROOT="/HCP/hcpdb/archive"
ARCHIVE_PROJ_SUBDIR="arc001"
TESLA_SPEC="_3T"
HCP_PIPELINES_VERSION="v3.12.1"

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

	get_options $@

	if [ "${g_details}" = "TRUE" ]; then
		echo ""
		echo "Project: ${g_project}"
		echo "Subject: ${g_subject}"
	fi

	presentDir=`pwd`
	archiveDir="${ARCHIVE_ROOT}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"
	#echo "archiveDir: ${archiveDir}"

	# Figure out what preprocessed tfMRI (task) scans the subject has
	pushd ${archiveDir}/RESOURCES > /dev/null
	task_scan_dirs=`find . -maxdepth 1 -name "tfMRI*_preproc"`
	task_scan_dirs=${task_scan_dirs//\.\//}
	popd > /dev/null

	# Figure out what preprocessed rfMRI (resting state) scans the subject has
	pushd ${archiveDir}/RESOURCES > /dev/null
	resting_state_scan_dirs=`find . -maxdepth 1 -name "rfMRI*_preproc"`
	resting_state_scan_dirs=${resting_state_scan_dirs//\.\//}
	popd > /dev/null

	#echo "task_scan_dirs: ${task_scan_dirs}"
	#echo "resting_state_scan_dirs: ${resting_state_scan_dirs}"

	scans=""
	for dir in ${task_scan_dirs} ${resting_state_scan_dirs} ; do
		scan=${dir%_preproc}
		#echo "scan: ${scan}"
		scans+="${scan} "
	done

	#echo "scans: ${scans}"

	resource_exists="FALSE"
	all_files_exist="UNCHECKED"

	# Does the GenerateSpinEchoBiasFieldPrereqs resource exist?
	generate_spin_echo_bias_fields_resource=${archiveDir}/RESOURCES/GenerateSpinEchoBiasFieldPrereqs
	if [ -d "${generate_spin_echo_bias_fields_resource}" ] ; then
		resource_exists="TRUE"

		files=""
	   
		for scan in ${scans} ; do
			files+=" ${generate_spin_echo_bias_fields_resource}/T1w/Results/${scan}/PhaseOne_gdc_dc.nii.gz"
			files+=" ${generate_spin_echo_bias_fields_resource}/T1w/Results/${scan}/PhaseTwo_gdc_dc.nii.gz"
			files+=" ${generate_spin_echo_bias_fields_resource}/T1w/Results/${scan}/SBRef_dc.nii.gz"
			files+=" ${generate_spin_echo_bias_fields_resource}/MNINonLinear/Results/${scan}/PhaseOne_gdc_dc.nii.gz"
			files+=" ${generate_spin_echo_bias_fields_resource}/MNINonLinear/Results/${scan}/PhaseTwo_gdc_dc.nii.gz"
			files+=" ${generate_spin_echo_bias_fields_resource}/MNINonLinear/Results/${scan}/SBRef_dc.nii.gz"
		done

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

	# output results
	echo -e "${g_subject}\t\t${g_project}\t${HCP_PIPELINES_VERSION}\tGenerateSpinEchoBiasFieldPrereqs\t${resource_exists}\t${all_files_exist}"
}

main $@
