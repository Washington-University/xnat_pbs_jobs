#!/bin/bash

inform() 
{
	echo "Create1p6mmFixPackage.sh: ${1}"
}

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
inform "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

get_options()
{
	local arguments=($@)

	unset g_script_name
	unset g_archive_root
	unset g_tmp_dir
	unset g_subject
	unset g_three_t_project
	unset g_seven_t_project
	unset g_release_notes_template_file
	unset g_output_dir
	unset g_create_checksum

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
            --tmp-dir=*)
                g_tmp_dir=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --subject=*)
            	g_subject=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --three-t-project=*)
				g_three_t_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --seven-t-project=*)
				g_seven_t_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --release-notes-template-file=*)
                g_release_notes_template_file=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --output-dir=*)
                g_output_dir=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --create-checksum)
                g_create_checksum="YES"
                index=$(( index + 1 ))
                ;;
            *)
            	inform "Unrecognized Option: ${argument}"
                exit 1
                ;;
        esac
	done

    local error_count=0
    
    # check required parameters

    echo "script name: ${g_script_name}"

    if [ -z "${g_archive_root}" ]; then
        echo "ERROR: --archive-root= required"
        error_count=$(( error_count + 1 ))
    else
        echo "archive root: ${g_archive_root}"
    fi

    if [ -z "${g_subject}" ]; then
        echo "ERROR: --subject= required"
        error_count=$(( error_count + 1 ))
    else
        echo "subject: ${g_subject}"
    fi

	if [ -z "${g_three_t_project}" ]; then
		echo "ERROR: --three-t-project= required"
		error_count=$(( error_count + 1 ))
	else
		echo "3T project: ${g_three_t_project}"
	fi

	if [ -z "${g_seven_t_project}" ]; then
		echo "ERROR: --seven-t-project= required"		
		error_count=$(( error_count + 1 ))
	else
		echo "7T project: ${g_seven_t_project}"
	fi

    if [ -z "${g_tmp_dir}" ]; then
        echo "ERROR: --tmp-dir= required"
        error_count=$(( error_count + 1 ))
    else
        echo "tmp dir: ${g_tmp_dir}"
    fi

    if [ -z "${g_release_notes_template_file}" ]; then
        echo "ERROR: --release-notes-template-file= required"
        error_count=$(( error_count + 1 ))
    else
        echo "release notes template file: ${g_release_notes_template_file}"
    fi

    if [ -z "${g_output_dir}" ]; then
        echo "ERROR: --output-dir= required"
        error_count=$(( error_count + 1 ))
    else
        echo "output dir: ${g_output_dir}"
    fi

    if [ -z "${g_create_checksum}" ]; then
        g_create_checksum="NO"
    fi
    echo "create checksum: ${g_create_checksum}"

    if [ ${error_count} -gt 0 ]; then
        echo "ERRORS DETECTED: EXITING"
        exit 1
    fi
}

build_standard_structure()
{
	# DeDriftAndResample HighRes
	link_hcp_resampled_and_dedrifted_highres_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}" 

	# DeDriftAndResample
	link_hcp_resampled_and_dedrifted_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}" 

	# Resting State Stats data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_RSS`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_RSS}
		link_hcp_resting_state_stats_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${script_tmp_dir}"
	done

	# PostFix data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_PostFix`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		inform "Getting ICA+FIX data from: ${short_scan_dir}"
		scan=${short_scan_dir%_PostFix}

		link_hcp_postfix_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${script_tmp_dir}"
	done

	# FIX processed data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_FIX`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_FIX}
		link_hcp_fix_proc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${script_tmp_dir}" 
	done

	# Functional preproc
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*fMRI*preproc`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_preproc}
		link_hcp_func_preproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${script_tmp_dir}" 
	done

	# Supplemental struc preproc	
	link_hcp_supplemental_struct_preproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${script_tmp_dir}" 

	# Structurally preproc
	link_hcp_struct_preproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${script_tmp_dir}"

	# unproc

	link_hcp_struct_unproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${script_tmp_dir}"
	link_hcp_7T_resting_state_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}"
	link_hcp_7T_diffusion_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}"
	link_hcp_7T_task_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}"

	# remove db archive artifacts

	pushd ${script_tmp_dir}
	find . -name "*job.sh*" -delete
	find . -name "*catalog.xml" -delete
	find . -name "*Provenance.xml" -delete
	find . -name "*matlab.log" -delete
	find . -name "StructuralHCP.err" -delete
	find . -name "StructuralHCP.log" -delete
	popd
}

main()
{
	# get command line options
	get_options $@

	# determine name of and create temporary directory for this script's work
	short_script_name=${g_script_name%.sh}
	secs_since_epoch=`date +%s%3N`
	script_tmp_dir="${g_tmp_dir}/${g_subject}.${short_script_name}.${secs_since_epoch}"
	mkdir -p ${script_tmp_dir}

	# determine subject's 3T resources directory
	g_subject_3T_resources_dir="${g_archive_root}/${g_three_t_project}/arc001/${g_subject}_3T/RESOURCES"

	# determine subject's 7T resources directory
	g_subject_7T_resources_dir="${g_archive_root}/${g_seven_t_project}/arc001/${g_subject}_7T/RESOURCES"

	# start with a clean temporary directory for this subject
	rm -rf ${script_tmp_dir}/${g_subject}

	build_standard_structure

	mv ${script_tmp_dir}/${g_subject} ${script_tmp_dir}/${g_subject}_full


	for modality in REST MOVIE ; do

		rm -rf ${script_tmp_dir}/${g_subject}

		mkdir -p ${script_tmp_dir}/${g_subject}

		file_list=""

		fix_scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*${modality}*_FIX`
		for scan_dir in ${fix_scan_dirs} ; do
			short_scan_dir=${scan_dir##*/}
			scan=${short_scan_dir%_FIX}

			parsing_str=${scan_dir##*/}
		
			prefix=${parsing_str%%_*}
			parsing_str=${parsing_str#*_}
			inform "prefix: ${prefix}"

			scan=${parsing_str%%_*}
			parsing_str=${parsing_str#*_}
			inform "scan: ${scan}"
			
			pe_dir=${parsing_str%%_*}
			parsing_str=${parsing_str#*_}
			inform "pe_dir: ${pe_dir}"
			
			short_name=${prefix}_${scan}_${pe_dir}
			inform "short_name: ${short_name}"
			
			long_name=${prefix}_${scan}_7T_${pe_dir}
			inform "long_name: ${long_name}"
			
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_Atlas_1.6mm_hp2000_clean.dtseries.nii "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_Atlas_1.6mm_MSMAll_hp2000_clean.dtseries.nii "
		done
	
		inform ""
		inform "Copying listed files to directory for zipping"
		inform ""
		for file in ${file_list} ; do
			to_dir=${script_tmp_dir}/${g_subject}/${file}
			to_dir=${to_dir%/*}
			echo "to_dir: ${to_dir}"
			mkdir -p ${to_dir}
			from_file=${script_tmp_dir}/${g_subject}_full/${file}
			to_file=${script_tmp_dir}/${g_subject}/${file}
			echo "from_file = ${from_file}"
			echo "  to_file = ${to_file}"
			if [ -e "${from_file}" ]; then
				cp -aLv ${from_file} ${to_file}
			else
				inform "ERROR FILE ${from_file} DOES NOT EXIST!"
				exit 1
			fi
		done # All listed files copied loop

		echo ""
		echo " Create Release Notes"
		echo ""
		release_notes_file=${script_tmp_dir}/${g_subject}/release-notes/release-notes.txt

		mkdir -p ${script_tmp_dir}/${g_subject}/release-notes
		touch ${release_notes_file}
		echo `date` >> ${release_notes_file}
		echo "" >> ${release_notes_file}
		cat ${g_release_notes_template_file} >> ${release_notes_file}
		echo "" >> ${release_notes_file}
		
		echo ""
		echo " Create Package"
		echo ""
		
		new_package_dir="${g_output_dir}/${g_subject}/fix"
		new_package_name="${g_subject}_7T_${modality}_1.6mm_fix.zip"
		new_package_path="${new_package_dir}/${new_package_name}"

		# start with a clean slate
		rm -rf ${new_package_path}
		rm -rf ${new_package_path}.md5
		mkdir -p ${new_package_dir}
		
		# go create the zip file
		pushd ${script_tmp_dir}
		zip_cmd="zip -r ${new_package_path} ${g_subject}"
		echo "zip_cmd: ${zip_cmd}"
		${zip_cmd}

		# make sure it's readable
		chmod u=rw,g=rw,o=r ${new_package_path}

		# create the checksum file if requested
		if [ "${g_create_checksum}" = "YES" ]; then
			echo ""
			echo " Create MD5 Checksum"
			echo ""

			pushd ${new_package_dir}
			md5sum ${new_package_name} > ${new_package_name}.md5
			chmod u=rw,g=rw,o=r ${new_package_name}.md5
			popd
		fi

		popd

	done

	echo ""
	echo " Remove temporary directory"
	echo ""
	
	rm -rf ${script_tmp_dir}
}

#
# Invoke the main function to get things started
#
main $@

