#!/bin/bash

SCRIPT_NAME="CheckPackageExistence.sh"

PRE_RELEASE_PACKAGES_ROOT="/HCP/hcpdb/packages/prerelease/zip"
LIVE_PACKAGES_ROOT="/HCP/hcpdb/packages/live"
POST_MSM_ALL_PACKAGES_ROOT="/HCP/hcpdb/packages/PostMsmAll"

ARCHIVE_ROOT="/HCP/hcpdb/archive"

UNPROC_PACKAGE_DIR="unproc"

UNPROC_PACKAGE_TYPES=""
UNPROC_PACKAGE_TYPES+=" Structural_unproc "
UNPROC_PACKAGE_TYPES+=" rfMRI_REST1_unproc "
UNPROC_PACKAGE_TYPES+=" rfMRI_REST2_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_EMOTION_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_GAMBLING_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_LANGUAGE_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_MOTOR_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_RELATIONAL_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_SOCIAL_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_WM_unproc "
UNPROC_PACKAGE_TYPES+=" Diffusion_unproc "

PREPROCESSING_PACKAGE_DIR="preproc"

PREPROC_PACKAGE_TYPES=""
PREPROC_PACKAGE_TYPES+=" Structural_preproc "
PREPROC_PACKAGE_TYPES+=" Structural_preproc_extended "
PREPROC_PACKAGE_TYPES+=" rfMRI_REST1_preproc "
PREPROC_PACKAGE_TYPES+=" rfMRI_REST2_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_EMOTION_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_GAMBLING_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_LANGUAGE_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_MOTOR_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_RELATIONAL_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_SOCIAL_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_WM_preproc "
PREPROC_PACKAGE_TYPES+=" Diffusion_preproc "

FIX_PACKAGE_DIR="fix"

FIX_PACKAGE_TYPES=""
FIX_PACKAGE_TYPES+=" rfMRI_REST_fix "

FIX_EXTENDED_PACKAGE_DIR="fixextended"

FIX_EXTENDED_PACKAGE_TYPES=""
FIX_EXTENDED_PACKAGE_TYPES+=" rfMRI_REST1_fixextended "
FIX_EXTENDED_PACKAGE_TYPES+=" rfMRI_REST2_fixextended "

TASK_ANALYSIS_SMOOTHING_LEVELS=""
TASK_ANALYSIS_SMOOTHING_LEVELS+=" 2 "
TASK_ANALYSIS_SMOOTHING_LEVELS+=" 4 "
TASK_ANALYSIS_SMOOTHING_LEVELS+=" 8 "
TASK_ANALYSIS_SMOOTHING_LEVELS+=" 12 "

TASK_ANALYSIS_PACKAGE_TYPES=""
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_EMOTION "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_GAMBLING "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_LANGUAGE "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_MOTOR "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_RELATIONAL "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_SOCIAL "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_WM "

VOLUME_TASK_ANALYSIS_SMOOTHING_LEVELS=""
VOLUME_TASK_ANALYSIS_SMOOTHING_LEVELS+=" 4 "

VOLUME_TASK_ANALYSIS_PACKAGE_TYPES=""
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_EMOTION "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_GAMBLING "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_LANGUAGE "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_MOTOR "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_RELATIONAL "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_SOCIAL "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_WM "

debugEcho()
{
	if [ "${g_debug}" = "TRUE" ] ; then
		echo "DEBUG: $@" 1>&2
	fi
}

usage() 
{
	echo "TBW"
}

get_options() 
{
    local arguments=($@)

    # initialize global output variables                                                                                                             
    g_debug="FALSE"
    unset g_subject
	unset g_package_project
	unset g_archive_project
	g_package_root="${LIVE_PACKAGES_ROOT}"
	g_suppress_checksum_regen="FALSE"

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
            --debug)
                g_debug="TRUE"
                index=$(( index + 1 ))
                ;;
            --subject=*)
                g_subject=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --package-project=*)
                g_package_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --archive-project=*)
                g_archive_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;	
            --package-root=*)
                g_package_root=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --suppress-checksum-regen)
                g_suppress_checksum_regen="TRUE"
                index=$(( index + 1 ))
                ;;
            *)
                echo "Unrecognized Option: ${argument}"
                usage
                exit 1
                ;;
        esac
    done

	# check options
	if [ -z "${g_subject}" ] ; then
		usage
		echo ""
		echo "ERROR: --subject= required"
		echo ""
		exit 1
	fi

	if [ -z "${g_package_project}" ] ; then
		usage
		echo ""
		echo "ERROR: --package-project= required"
		echo ""
		exit 1
	fi

	if [ -z "${g_package_root}" ] ; then
		usage
		echo ""
		echo "ERROR: --package-root= required"
		echo ""
		exit 1
	fi

	if [ -z "${g_archive_project}" ] ; then
		usage
		echo ""
		echo "ERROR: --archive-project= required"
		echo ""
		exit 1
	fi

	# report options
	debugEcho "${SCRIPT_NAME}: g_subject: ${g_subject}"
	debugEcho "${SCRIPT_NAME}: g_package_project: ${g_package_project}"
	debugEcho "${SCRIPT_NAME}: g_archive_project: ${g_archive_project}"
	debugEcho "${SCRIPT_NAME}: g_package_root: ${g_package_root}"
	debugEcho "${SCRIPT_NAME}: g_debug: ${g_debug}"
	debugEcho "${SCRIPT_NAME}: g_suppress_checksum_regen: ${g_suppress_checksum_regen}"
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

get_size()
{
	local path=${1}
	local __functionResultVar=${2}
	local file_info
	local the_size

	if [ -e "${path}" ] ; then
		file_info=`ls -lh ${path}`
		the_size=`echo ${file_info} | cut -d " " -f 5`
	else
		the_size="DOES NOT EXIST"
	fi

	eval $__functionResultVar="'${the_size}'"
}

check_package_file()
{
	local arguments=($@)
	local package_file_name=${arguments[0]}

	local checksum_file_name="${package_file_name}.md5"
	local package_file_exists="FALSE"
	local package_file_size="UNKNOWN"
	local package_file_date="UNKNOWN"
	local checksum_file_exists="FALSE"
	local checksums_equivalent="UNCHECKED"

	# check for package file existence
	test_description="${package_file_name##*/}"

	if [ -e "${package_file_name}" ] ; then

		package_file_exists="TRUE"
		get_size ${package_file_name} package_file_size
		get_date ${package_file_name} package_file_date

		if [ -e "${checksum_file_name}" ] ; then
			checksum_file_exists="TRUE"

			if [ ! "${g_suppress_checksum_regen}" = "TRUE" ] ; then

				test_directory="${package_file_name%/*}"
				pushd ${test_directory} > /dev/null
				md5sum --check --status ${checksum_file_name}
				if [ $? -ne 0 ]; then
					checksums_equivalent="FALSE"
				else
					checksums_equivalent="TRUE"
				fi
				popd > /dev/null

			fi

		fi

	fi

	# output information
	echo -e "${g_subject}\t${test_description}\t${package_file_exists}\t${package_file_size}\t${package_file_date}\t${checksum_file_exists}\t${checksums_equivalent}"
}


check_main_and_upgrade_files()
{
	local main_package_file=${1}
	local upgrade_package_file=${2}

	check_package_file ${main_package_file}

	if [ "${g_archive_project}" == "HCP_500" ] ; then
		check_package_file ${upgrade_package_file}
	else
		local test_description="${upgrade_package_file##*/}"
		echo -e "${g_subject}\t${test_description}\t---\t---\t---\t---\t---"
	fi
}

show_unchecked_file()
{
	local package_file=${1}
	local test_description
	test_description="${package_file##*/}"
	echo -e "${g_subject}\t${test_description}\t---\t---\t---\t---\t---"
}

show_unchecked_main_and_upgrade_files()
{
	local main_package_file=${1}
	local upgrade_package_file=${2}

	show_unchecked_file ${main_package_file}
	show_unchecked_file ${upgrade_package_file}
}

main()
{
	get_options $@

	subject_unproc_package_dir="${g_package_root}/${g_package_project}/${g_subject}/${UNPROC_PACKAGE_DIR}"
	subject_preproc_package_dir="${g_package_root}/${g_package_project}/${g_subject}/${PREPROCESSING_PACKAGE_DIR}"
	subject_fix_package_dir="${g_package_root}/${g_package_project}/${g_subject}/${FIX_PACKAGE_DIR}"
	subject_fix_extended_package_dir="${g_package_root}/${g_package_project}/${g_subject}/${FIX_EXTENDED_PACKAGE_DIR}"

	# check unproc packages
	for package_type in ${UNPROC_PACKAGE_TYPES} ; do
		local package_file_name="${subject_unproc_package_dir}/${g_subject}_3T_${package_type}.zip"

		if [[ ${package_type} == *Structural* ]] ; then
			# The Structural unproc packages should only be checked for if some Structural unproc resources exist
			files=`ls -d ${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/T[12]w_*_unproc`
			if [ ! -z "${files}" ] ; then
				check_package_file ${package_file_name}
			else
				show_unchecked_file ${package_file_name}
			fi

		elif [[ ${package_type} == rfMRI_REST*unproc ]] ; then
			# The Resting state functional unproc packages should only be checked for if at least one of the 
			# the corresponding resting state unproc resources exists
			prefix=${package_type%%_unproc}
			files=`ls -d ${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${prefix}*_unproc`
			if [ ! -z "${files}" ] ; then
				check_package_file ${package_file_name}
			else
				show_unchecked_file ${package_file_name}
			fi
			
		elif [[ ${package_type} == tfMRI*unproc ]] ; then
			# The task functional unproc packages should only be checked for if at least one of the
			# corresponding task unproc resources exists
			prefix=${package_type%%_unproc}
			files=`ls -d ${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${prefix}*_unproc`
			if [ ! -z "${files}" ] ; then
				check_package_file ${package_file_name}
			else
				show_unchecked_file ${package_file_name}
			fi

		elif [[ ${package_type} == Diffusion_unproc ]] ; then
			# The Diffusion unproc package should only be checked for if the Diffusion_unproc 
			# resource exists
			if [ -e "${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/Diffusion_unproc" ] ; then
				check_package_file ${package_file_name}
			else
				show_unchecked_file ${package_file_name}
			fi
		else
			check_package_file ${package_file_name}
		fi

	done
		
	# check preproc packages
	for package_type in ${PREPROC_PACKAGE_TYPES} ; do

		local package_file_name="${subject_preproc_package_dir}/${g_subject}_3T_${package_type}.zip"
		local upgrade_package_file_name="${package_file_name%\.zip}_S500_to_S900_extension.zip"

		if [[ ${package_type} == Structural_preproc ]] ; then
			# The Structural preproc packages should only be checked for if the Structural_preproc resource exists
			if [ -e "${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/Structural_preproc" ] ; then
				check_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
			else
				show_unchecked_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
			fi
		
		elif [[ ${package_type} == Structural_preproc_extended ]] ; then
			# The Structural preproc extended packages should only be checked for if the Structural_preproc resource exists
			# Note: there is not upgrade package for the Structural Preproc Extended package
			if [ -e "${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/Structural_preproc" ] ; then
				check_package_file ${package_file_name}
			else
				show_unchecked_file ${package_file_name}
			fi

		elif [[ ${package_type} == rfMRI_REST*preproc ]] ; then
			# The Resting state functional preproc packages should only be checked for if at least one of the 
			# the corresponding resting state preproc resources exists
			prefix=${package_type%%_preproc}
			files=`ls -d ${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${prefix}*_preproc`
			if [ ! -z "${files}" ] ; then
				check_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
			else
				show_unchecked_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
			fi
			
		elif [[ ${package_type} == tfMRI*preproc ]] ; then
			# The task functional preproc packages should only be checked for if at least one of the
			# corresponding task preproc resources exists
			prefix=${package_type%%_preproc}
			files=`ls -d ${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${prefix}*_preproc`
			if [ ! -z "${files}" ] ; then
				check_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
			else
				show_unchecked_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
			fi

		elif [[ ${package_type} == Diffusion_preproc ]] ; then
			# The Diffusion preproc package should only be checked for if the Diffusion_preproc 
			# resource exists
			if [ -e "${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/Diffusion_preproc" ] ; then
				check_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
			else
				show_unchecked_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
			fi
		else
			check_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
		fi
	done

	# check fix packages
	for package_type in ${FIX_PACKAGE_TYPES} ; do
		local package_file_name="${subject_fix_package_dir}/${g_subject}_3T_${package_type}.zip"
		local upgrade_package_file_name="${package_file_name%\.zip}_S500_to_S900_extension.zip"

		# The FIX packages should only be checked for if at least one *FIX resource exists
		files=`ls -d ${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/*_FIX`

		if [ ! -z "${files}" ] ; then
			check_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
		else
			show_unchecked_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
		fi
	done

	# check fix extended packages
	for package_type in ${FIX_EXTENDED_PACKAGE_TYPES} ; do
		local package_file_name="${subject_fix_extended_package_dir}/${g_subject}_3T_${package_type}.zip"
		local upgrade_package_file_name="${package_file_name%\.zip}_S500_to_S900_extension.zip"

		# The FIX extended packages should only be checked for if at least one *FIX resource exists
		prefix=${package_type%%_fixextended}
		files=`ls -d ${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${prefix}*_FIX`
		if [ ! -z "${files}" ] ; then
			check_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
		else
			show_unchecked_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
		fi
	done

	# check task analysis packages
	for smoothing_level in ${TASK_ANALYSIS_SMOOTHING_LEVELS} ; do
		subject_task_analysis_dir="${g_package_root}/${g_package_project}/${g_subject}/analysis_s${smoothing_level}"
		for package_type in ${TASK_ANALYSIS_PACKAGE_TYPES} ; do
			local package_file_name="${subject_task_analysis_dir}/${g_subject}_3T_${package_type}_analysis_s${smoothing_level}.zip"
			local upgrade_package_file_name="${package_file_name%\.zip}_S500_to_S900_extension.zip"

			if [ "${smoothing_level}" -gt 2 ] ; then
				# no upgrade packages are supplied for the smoothing levels > 2 
				if [ -e "${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${package_type}" ] ; then
					check_package_file ${package_file_name}
				else
					show_unchecked_file ${upgrade_package_file_name}
				fi
			else
				if [ -e "${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${package_type}" ] ; then
					check_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
				else
					show_unchecked_main_and_upgrade_files ${package_file_name} ${upgrade_package_file_name}
				fi
			fi
		done
	done

	# check volume task analysis packages
	for smoothing_level in ${VOLUME_TASK_ANALYSIS_SMOOTHING_LEVELS} ; do
		subject_volume_task_analysis_dir="${g_package_root}/${g_package_project}/${g_subject}/volume_s${smoothing_level}"
		for package_type in ${VOLUME_TASK_ANALYSIS_PACKAGE_TYPES} ; do
			local package_file_name="${subject_volume_task_analysis_dir}/${g_subject}_3T_${package_type}_volume_s${smoothing_level}.zip"
			local upgrade_package_file_name="${package_file_name%\.zip}_S500_to_S900_extension.zip"

			if [ -e "${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${package_type}" ] ; then
				# upgrade packages are not supplied for the volume data
				check_package_file ${package_file_name}
			else
				show_unchecked_file ${package_file_name} 
			fi
		done
	done

}

main $@

