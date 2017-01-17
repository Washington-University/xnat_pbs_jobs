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

get_info()
{
	local path=${1}
	local __functionResultVar=${2}

	if [ -e "${path}" ] ; then
		local file_info=`ls -lh ${path}`
		local size=`echo ${file_info} | cut -d " " -f 5`
		local the_date=`echo ${file_info} | cut -d " " -f 6-8`
		#local short_name=${path##*/}
		#echo "short_name: ${short_name}"
		#info="${short_name} : ${size}"
		info="${size}\t${the_date}"
	else
		info="DOES NOT EXIST\tNO DATE"
	fi

	eval $__functionResultVar="'${info}'"
}

main() {

	get_options $@

	# determine subject resources directory
	local subject_resources_dir="${g_archive_root}/${g_subject}_3T/RESOURCES"


	for smoothing_level in 2 4 ; do

		for task in EMOTION GAMBLING LANGUAGE MOTOR RELATIONAL SOCIAL WM ; do
			local resource=`find ${subject_resources_dir} -maxdepth 1 -name "tfMRI_${task}"`
			
			if [ ! -z "${resource}" ]; then
			# packages should exist
				full_package_name="${g_output_dir}/${g_subject}/analysis_s${smoothing_level}/${g_subject}_3T_tfMRI_${task}_analysis_s${smoothing_level}.zip"
				full_package_checksum_name="${full_package_name}.md5"
				patch_package_name="${g_output_dir}/${g_subject}/analysis_s${smoothing_level}/${g_subject}_3T_tfMRI_${task}_analysis_s${smoothing_level}${PATCH_NAME_SUFFIX}.zip"
				patch_package_checksum_name="${patch_package_name}.md5"
				
				get_info ${full_package_name} full_package_info
				get_info ${full_package_checksum_name} full_package_checksum_info

				if [ "${g_patch_package_must_exist}" = "TRUE" ]; then

					get_info ${patch_package_name} patch_package_info
					get_info ${patch_package_checksum_name} patch_package_checksum_info
					
				else
					
					patch_package_info="---"
					patch_package_checksum_info="---"

				fi	
				
			else
			# Package does not need to exist
				full_package_info="---"
				full_package_checksum_info="---"
				patch_package_info="---"
				patch_package_checksum_info="---"
			fi
			
			echo -e "${g_subject}\tTask Analysis ${task} Smoothing Level ${smoothing_level} Package\t${full_package_name}\t${full_package_info}\t${full_package_checksum_info}\t${patch_package_info}\t${patch_package_checksum_info}"
			
		done

	done
}

main $@
