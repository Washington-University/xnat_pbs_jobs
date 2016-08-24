#!/bin/bash

PATCH_NAME_SUFFIX="_S500_to_S900_extension"

usage() {
	echo "Usage information TBW"
}

debug_msg() {
	msg=${1}
	if [ "${g_debug}" = "TRUE" ]; then
		echo "DEBUG: ${msg}"
	fi
}

get_options()
{
    local arguments=($@)

    unset g_script_name
    unset g_archive_root
    unset g_subject
	unset g_output_dir
	unset g_patch_package_must_exist
	unset g_debug

    g_script_name=`basename ${0}`

    # parse arguments                                                                                                                                                                                        
    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --archive-root=*)
                g_archive_root=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --subject=*)
                g_subject=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --output-dir=*)
                g_output_dir=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
			--do-not-check-patch-package)
			    g_patch_package_must_exist="FALSE"
                index=$(( index + 1 ))
                ;;
			--debug)
			    g_debug="TRUE"
                index=$(( index + 1 ))
                ;;
            *)
                echo "Unrecognized Option: ${argument}"
                exit 1
                ;;
        esac
    done

    local error_count=0

    # check required parameters                                                                                                                                                                              

	if [ -z "${g_debug}" ]; then
		g_debug="FALSE"
	fi

    if [ -z "${g_archive_root}" ]; then
        echo "ERROR: --archive-root= required"
        error_count=$(( error_count + 1 ))
    fi
	debug_msg "g_archive_root: ${g_archive_root}"

    if [ -z "${g_subject}" ]; then
        echo "ERROR: --subject= required"
        error_count=$(( error_count + 1 ))
    fi
	debug_msg "g_subject: ${g_subject}"

    if [ -z "${g_output_dir}" ]; then
        echo "ERROR: --output-dir= required"
        error_count=$(( error_count + 1 ))
    fi
	debug_msg "g_output_dir: ${g_output_dir}"

	if [ -z "${g_patch_package_must_exist}" ]; then
		g_patch_package_must_exist="TRUE"
	fi
	debug_msg "g_patch_package_must_exist: ${g_patch_package_must_exist}"
}

get_size() 
{
	local path=${1}
	local __functionResultVar=${2}
	local file_info
	local size

	if [ -e "${path}" ] ; then
		file_info=`ls -lh ${path}`
		size=`echo ${file_info} | cut -d " " -f 5`
	else
		size="DOES NOT EXIST"
	fi

	eval $__functionResultVar="'${size}'"
}


get_date()
{
	local path=${1}
	local __functionResultVar=${2}
	local file_info
	local the_date

	if [ -e "${path}" ] ; then
		file_info=`ls -lh ${path}`
		the_date=`echo ${file_info} | cut -d " " -f 6-8`
	else
		the_date="DOES NOT EXIST"
	fi

	eval $__functionResultVar="'${the_date}'"
}

main() {

	# host=`hostname`
	# if [ "${host}" != "hcpx-fs01.nrg.mir" ] ; then
	# 	echo "ERROR: This script is intended to be run on host: hcpx-fs01.nrg.mir"
	# 	exit 1
	# fi

	get_options $@

	debug_msg "Got Options"

	# determine subject resources directory
	local subject_resources_dir="${g_archive_root}/${g_subject}_3T/RESOURCES"
	debug_msg "subject_resources_dir: ${subject_resources_dir}"

	local resting_state_stats_resources=`find ${subject_resources_dir} -maxdepth 1 -name "*RSS"`
	debug_msg "resting_state_stats_resources: ${resting_state_stats_resources}"

	if [ ! -z "${resting_state_stats_resources}" ]; then
		# Packages should exist
		debug_msg "Packages should exist"
		full_package_name="${g_output_dir}/${g_subject}/fix/${g_subject}_3T_rfMRI_REST_fix.zip"
		full_package_checksum_name="${g_output_dir}/${g_subject}/fix/${g_subject}_3T_rfMRI_REST_fix.zip.md5"
		patch_package_name="${g_output_dir}/${g_subject}/fix/${g_subject}_3T_rfMRI_REST_fix${PATCH_NAME_SUFFIX}.zip"
		patch_package_checksum_name="${g_output_dir}/${g_subject}/fix/${g_subject}_3T_rfMRI_REST_fix${PATCH_NAME_SUFFIX}.zip.md5"

		get_size ${full_package_name} full_package_size
		get_date ${full_package_name} full_package_date

		get_size ${full_package_checksum_name} full_package_checksum_size
		get_date ${full_package_checksum_name} full_package_checksum_date

		if [ "${g_patch_package_must_exist}" = "TRUE" ]; then

			get_size ${patch_package_name} patch_package_size
			get_date ${patch_package_name} patch_package_date

			get_size ${patch_package_checksum_name} patch_package_checksum_size
			get_date ${patch_package_checksum_name} patch_package_checksum_date

		else
			
			patch_package_size="---"
			patch_package_date="---"
			patch_package_checksum_size="---"
			patch_package_checksum_date="---"

		fi

	else
 		# Package does not need to exist
		debug_msg "Package does not need to exist"
		full_package_size="---"
		full_package_date="---"

		full_package_checksum_size="---"
		full_package_checksum_date="---"

		patch_package_size="---"
		patch_package_date="---"

		patch_package_checksum_size="---"
		patch_package_checksum_date="---"
	fi

	debug_msg "About to output status line"
	echo -e "${g_subject}\tFIX Package\t${full_package_size}\t${full_package_date}\t${full_package_checksum_size}\t${full_package_checksum_date}\t${patch_package_size}\t${patch_package_date}\t${patch_package_checksum_size}\t${patch_package_checksum_date}"
}

main $@
