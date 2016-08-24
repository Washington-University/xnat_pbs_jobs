#!/bin/bash

PATCH_NAME_SUFFIX="_S500_to_S900_extension"

usage() {
	echo "Usage information TBW"
}

get_options()
{
    local arguments=($@)

    unset g_script_name
    unset g_archive_root
    unset g_subject
	unset g_output_dir
	unset g_patch_package_must_exist

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
            *)
                echo "Unrecognized Option: ${argument}"
                exit 1
                ;;
        esac
    done

    local error_count=0

    # check required parameters                                                                                                                                                                              

    if [ -z "${g_archive_root}" ]; then
        echo "ERROR: --archive-root= required"
        error_count=$(( error_count + 1 ))
    fi

    if [ -z "${g_subject}" ]; then
        echo "ERROR: --subject= required"
        error_count=$(( error_count + 1 ))
    fi

    if [ -z "${g_output_dir}" ]; then
        echo "ERROR: --output-dir= required"
        error_count=$(( error_count + 1 ))
    fi

	if [ -z "${g_patch_package_must_exist}" ]; then
		g_patch_package_must_exist="TRUE"
	fi
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

	get_options $@

	# determine subject resources directory
	local subject_resources_dir="${g_archive_root}/${g_subject}_3T/RESOURCES"
	local structural_resource=`find ${subject_resources_dir} -maxdepth 1 -name "Structural_preproc"`

	if [ ! -z "${structural_resource}" ]; then
		# Packages should exist
		full_package_name="${g_output_dir}/${g_subject}/preproc/${g_subject}_3T_Structural_preproc.zip"
		full_package_checksum_name="${full_package_name}.md5"
		patch_package_name="${g_output_dir}/${g_subject}/preproc/${g_subject}_3T_Structural_preproc${PATCH_NAME_SUFFIX}.zip"
		patch_package_checksum_name="${patch_package_name}.md5"

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
		full_package_size="---"
		full_package_date="---"

		full_package_checksum_size="---"
		full_package_checksum_date="---"

		patch_package_size="---"
		patch_package_date="---"

		patch_package_checksum_size="---"
		patch_package_checksum_date="---"
	fi
	   
	echo -e "${g_subject}\tStructural Preproc Package\t${full_package_size}\t${full_package_date}\t${full_package_checksum_size}\t${full_package_checksum_date}\t${patch_package_size}\t${patch_package_date}\t${patch_package_checksum_size}\t${patch_package_checksum_date}"
}

main $@
