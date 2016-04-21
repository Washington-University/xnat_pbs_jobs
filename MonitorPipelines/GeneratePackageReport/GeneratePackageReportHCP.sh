#!/bin/bash


# Note: 2016.04.21  Timothy B. Brown (tbbrown@wustl.edu)
#
# There are still some "bugs" in this script.  
#
# For example, it doesn't seem to handle all conditions correctly for when 
# the S500_to_S900_extension package is not needed (When there are noe
# Resting State scans and when the subject is a subject initially released
# as part of the S900 release.)  
# 
# Running this script on all subjects by submitting it to a cluster job 
# scheduler means that each such "bug" that needs to be analyzed and 
# fixed causes a test run that lasts for at least 12 hours.
#
# So I've just hand edited some of the resulting *.PackageReport.tsv 
# files to replace their FALSE entries indicating that a package should
# exist but doesn't exist to --- entries indicating that the package 
# should not exist.
#
# This was initially developed to be a quick "one-off" shell script to 
# verify the existence and size of various package files.
# 
# With a number of special conditions added it got a bit unweildy.
# I think the whole process needs to be re-written, problem as 
# a Python program.
#

SCRIPT_NAME="GeneratePackageReport.sh"

if [ "${COMPUTE}" = "CHPC" ] ; then
	HCP_ROOT="/HCP"
elif [ "${COMPUTE}" = "NRG" ] ; then
	HCP_ROOT="/data"
elif [ "${COMPUTE}" = "" ] ; then
	HCP_ROOT="/data"
else
	echo "${SCRIPT_NAME}: Unhandled value for COMPUTE environment variable"
	echo "${SCRIPT_NAME}: '${COMPUTE}' is currently not supported."
	echo "${SCRIPT_NAME}: Exiting with non-zero status."
	exit 1
fi

if [ ! -d "${HCP_ROOT}" ] ; then
	echo "${SCRIPT_NAME}: Expected HCP_ROOT: ${HCP_ROOT} does not exist"
	echo "${SCRIPT_NAME}: as a directory."
	echo "${SCRIPT_NAME}: Exiting with non-zero status."
	exit 1
fi

PRE_RELEASE_PACKAGES_ROOT="${HCP_ROOT}/hcpdb/packages/prerelease/zip"
LIVE_PACKAGES_ROOT="${HCP_ROOT}/hcpdb/packages/live"
POST_MSM_ALL_PACKAGES_ROOT="${HCP_ROOT}/hcpdb/packages/PostMsmAll"
ARCHIVE_ROOT="${HCP_ROOT}/hcpdb/archive"

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


MEG2_HCP500_SUBJECT_LIST=""
MEG2_HCP500_SUBJECT_LIST+=" 104012 " #  1
MEG2_HCP500_SUBJECT_LIST+=" 105923 " #  2
MEG2_HCP500_SUBJECT_LIST+=" 111514 " #  3
MEG2_HCP500_SUBJECT_LIST+=" 146129 " #  4
MEG2_HCP500_SUBJECT_LIST+=" 153732 " #  5
MEG2_HCP500_SUBJECT_LIST+=" 156334 " #  6
MEG2_HCP500_SUBJECT_LIST+=" 175540 " #  7
MEG2_HCP500_SUBJECT_LIST+=" 192641 " #  8
MEG2_HCP500_SUBJECT_LIST+=" 287248 " #  9
MEG2_HCP500_SUBJECT_LIST+=" 512835 " # 10
MEG2_HCP500_SUBJECT_LIST+=" 660951 " # 11
MEG2_HCP500_SUBJECT_LIST+=" 662551 " # 12
MEG2_HCP500_SUBJECT_LIST+=" 715950 " # 13
MEG2_HCP500_SUBJECT_LIST+=" 783462 " # 14
MEG2_HCP500_SUBJECT_LIST+=" 825048 " # 15

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

	note=""
	package_type=${package_file_name%.zip} # get the part before the .zip
	package_type=${package_type##*3T_}


	subject_resources=${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES

	t1w_count=`ls -1d ${subject_resources}/T1w*_unproc | wc -l`
	t2w_count=`ls -1d ${subject_resources}/T2w*_unproc | wc -l`
	
	REST1_count=`ls -1d ${subject_resources}/rfMRI_REST1*_unproc | wc -l`
	REST2_count=`ls -1d ${subject_resources}/rfMRI_REST2*_unproc | wc -l`

	Diffusion_LR_count=`ls -1d ${subject_resources}/Diffusion_unproc/${g_subject}_3T_DWI_dir*LR.nii.gz | wc -l`
	Diffusion_RL_count=`ls -1d ${subject_resources}/Diffusion_unproc/${g_subject}_3T_DWI_dir*RL.nii.gz | wc -l`

	EMOTION_count=`ls -1d ${subject_resources}/tfMRI_EMOTION_*_unproc | wc -l`
	GAMBLING_count=`ls -1d ${subject_resources}/tfMRI_GAMBLING_*_unproc | wc -l`
	LANGUAGE_count=`ls -1d ${subject_resources}/tfMRI_LANGUAGE_*_unproc | wc -l`
	MOTOR_count=`ls -1d ${subject_resources}/tfMRI_MOTOR_*_unproc | wc -l`
	RELATIONAL_count=`ls -1d ${subject_resources}/tfMRI_RELATIONAL_*_unproc | wc -l`
	SOCIAL_count=`ls -1d ${subject_resources}/tfMRI_SOCIAL_*_unproc | wc -l`
	WM_count=`ls -1d ${subject_resources}/tfMRI_WM_*_unproc | wc -l`

	if [ "${package_type}" == "Structural_unproc" ] ; then
		if [ "${t1w_count}" -lt "2" -a "${t1w_count}" -lt "2" ] ; then
			note+=" T1w and T2w count less than 2 "
		elif [ "${t1w_count}" -lt "2" ] ; then
			note+=" T1w count less than 2 "
		elif [ "${t2w_count}" -lt "2" ] ; then
			note+=" T2w count less than 2 "
		fi

	elif [[ ${package_type} == Diffusion_* ]] ; then
		if [ "${Diffusion_LR_count}" -lt "3" -o "${Diffusion_RL_count}" -lt "3" ] ; then
			note+=" Missing some Diffusion Scans "
		fi

	elif [[ ${package_type} == rfMRI_REST_fix* ]] ; then
		if [ "${REST1_count}" -lt "2" ] ; then
			note+=" Missing some REST1 scans "
		fi
		if [ "${REST2_count}" -lt "2" ] ; then
			note+=" Missing some REST2 scans "
		fi

	elif [[ ${package_type} == rfMRI_REST1* ]] ; then
		if [ "${REST1_count}" -lt "2" ] ; then
			note+=" Missing some REST1 scans "
		fi

	elif [[ ${package_type} == rfMRI_REST2* ]] ; then
		if [ "${REST2_count}" -lt "2" ] ; then
			note+=" Missing some REST2 scans "
		fi

	elif [[ ${package_type} == tfMRI_EMOTION* ]] ; then
		if [ "${EMOTION_count}" -lt "2" ] ; then
			note+=" Missing some EMOTION scans "
		fi

	elif [[ ${package_type} == tfMRI_GAMBLING* ]] ; then
		if [ "${GAMBLING_count}" -lt "2" ] ; then
			note+=" Missing some GAMBLING scans "
		fi

	elif [[ ${package_type} == tfMRI_LANGUAGE* ]] ; then
		if [ "${LANGUAGE_count}" -lt "2" ] ; then
			note+=" Missing some LANGUAGE scans "
		fi

	elif [[ ${package_type} == tfMRI_MOTOR* ]] ; then
		if [ "${MOTOR_count}" -lt "2" ] ; then
			note+=" Missing some MOTOR scans "
		fi

	elif [[ ${package_type} == tfMRI_RELATIONAL* ]] ; then
		if [ "${RELATIONAL_count}" -lt "2" ] ; then
			note+=" Missing some RELATIONAL scans "
		fi

	elif [[ ${package_type} == tfMRI_SOCIAL* ]] ; then
		if [ "${SOCIAL_count}" -lt "2" ] ; then
			note+=" Missing some SOCIAL scans "
		fi

	elif [[ ${package_type} == tfMRI_WM* ]] ; then
		if [ "${WM_count}" -lt "2" ] ; then
			note+=" Missing some WM scans "
		fi

	fi

	if [ "${REST1_count}" -lt "1" -a "${REST2_count}" -lt "1" ] ; then
		# No resting state scans ==> no MSM All additions to packages

		if [[ ${package_type} == *analysis* ]] ; then
			note+="No resting state scans, No MSM-All additions to packages"
		elif [[ ${package_type} == tfMRI_*_preproc ]] ; then
			note+="No resting state scans, No MSM-All additions to packages"
		elif [[ ${package_type} == *S500_to_S900_extension ]] ; then
			# No MSM All additions to packages ==> no need for any S500_to_S900_extension packages for this subject
			package_file_exists="---"
			package_file_size="---"
			package_file_date="---"
			checksum_file_exists="---"
			checksums_equivalent="---"
			note=""
		fi

	fi

	if [ ! -z "${note}" ] ; then
		note="SMALL_OK: ${note}"
	fi
	
	# output information
	echo -e "${g_subject}\t${test_description}\t${package_file_exists}\t${package_file_size}\t${package_file_date}\t${checksum_file_exists}\t${checksums_equivalent}\t${note}"
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

			if [ "${g_archive_project}" == "HCP_900" ] ; then
				# volume task analysis packages are not supplied for HCP_900 only subjects
				show_unchecked_file ${package_file_name}
				show_unchecked_file ${upgrade_package_file_name}
			
			elif [[ ${MEG2_HCP500_SUBJECT_LIST} =~ .*${g_subject}.* ]] ; then
				# subjects released as part of the MEG2 HCP_500 release are like HCP_900 subjects in that they do not
				# have volume task analysis packages supplied for them
				show_unchecked_file ${package_file_name}
				show_unchecked_file ${upgrade_package_file_name}
				
			else
				if [ -e "${ARCHIVE_ROOT}/${g_archive_project}/arc001/${g_subject}_3T/RESOURCES/${package_type}" ] ; then
					# upgrade packages are not supplied for the volume data
					check_package_file ${package_file_name}
					show_unchecked_file ${upgrade_package_file_name}
				else
					show_unchecked_file ${package_file_name} 
					show_unchecked_file ${upgrade_package_file_name}
				fi
			fi
		done
	done

}

main $@

