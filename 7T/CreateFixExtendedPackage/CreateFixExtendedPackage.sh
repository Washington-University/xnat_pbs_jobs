#!/bin/bash
set -e

inform()
{
	echo "${g_script_name}: ${1}"
}

get_options()
{
	local arguments=($@)

	g_script_name="CreateFixExtendedPackage.sh"
	unset g_archive_root
	unset g_tmp_dir
	unset g_subject
	unset g_seven_t_project
	unset g_release_notes_template_file
	unset g_output_dir
	unset g_create_checksum

	unset g_xnat_pbs_jobs

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

	# check required option values

	if [ -z "${g_archive_root}" ]; then
		inform "ERROR: --archive-root= required"
		error_count=$(( error_count + 1 ))
	else
		inform "archive root: ${g_archive_root}"
	fi

	if [ -z "${g_tmp_dir}" ]; then
		inform "ERROR: --tmp-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "tmp dir: ${g_tmp_dir}"
	fi

	if [ -z "${g_subject}" ]; then
		inform "ERROR: --subject= required"
		error_count=$(( error_count + 1 ))
	else
		inform "subject: ${g_subject}"
	fi
	
	if [ -z "${g_seven_t_project}" ]; then
		inform "ERROR: --seven-t-project= required"
		error_count=$(( error_count + 1 ))
	else
		inform "7T project: ${g_seven_t_project}"
	fi

	if [ -z "${g_release_notes_template_file}" ]; then
		inform "ERROR: --release-notes-template-file= required"
		error_count=$(( error_count + 1 ))
	else
		inform "release notes template file: ${g_release_notes_template_file}"
	fi

	if [ -z "${g_output_dir}" ]; then
		inform "ERROR: --output-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "output dir: ${g_output_dir}"
	fi
	
	# set default option values
	if [ -z "${g_create_checksum}" ]; then
		g_create_checksum="NO"
	fi
	inform "create checksum: ${g_create_checksum}"

	# set option values from environment variables

	if [ -z "${XNAT_PBS_JOBS}" ]; then
		inform "ERROR: XNAT_PBS_JOBS environment variable must be set"
		error_count=$(( error_count + 1 ))
	else
		g_xnat_pbs_jobs="${XNAT_PBS_JOBS}"
		inform "XNAT_PBS_JOBS: ${g_xnat_pbs_jobs}"
	fi
	
	if [ ${error_count} -gt 0 ]; then
		inform "Option errors detected: EXITING"
		exit 1
	fi
}

clean_db_archive_artifacts()
{
	pushd ${g_script_tmp_dir}
	find . -name "*job.sh*" -delete
	find . -name "*catalog.xml" -delete
	find . -name "*Provenance.xml" -delete
	find . -name "*matlab.log" -delete
	find . -name "StructuralHCP.err" -delete
	find . -name "StructuralHCP.log" -delete
	find . -name "*.starttime" -delete
	popd
}

get_data_from_resources()
{
	local scan_dirs
	local scan_dir
	local short_scan_dir
	local scan
	
	# DeDriftAndResample HighRes
	link_hcp_resampled_and_dedrifted_highres_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_script_tmp_dir}"

	# DeDriftAndResample
	link_hcp_resampled_and_dedrifted_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_script_tmp_dir}"

	# Resting State Stats data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_RSS`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		inform "Getting Resting State Stats data from: ${short_scan_dir}"
		scan=${short_scan_dir%_RSS}
		link_hcp_7T_resting_state_stats_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_script_tmp_dir}"
	done

	# PostFix data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_PostFix`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		inform "Getting ICA+FIX data from: ${short_scan_dir}"
		scan=${short_scan_dir%_PostFix}

		link_hcp_postfix_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_script_tmp_dir}"
	done

	# FIX processed data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_FIX`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		inform "Getting ICA+FIX data from: ${short_scan_dir}"
		scan=${short_scan_dir%_FIX}
		link_hcp_fix_proc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_script_tmp_dir}" 
	done

	# Functional preproc
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*fMRI*preproc`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		inform "Getting Functionally Preprocessed data from: ${short_scan_dir}"
		scan=${short_scan_dir%_preproc}
		link_hcp_func_preproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_script_tmp_dir}"
	done

	clean_db_archive_artifacts
}


main()
{
	# get options 
	get_options $@

	# source function libraries
	source ${g_xnat_pbs_jobs}/GetHcpDataUtils/GetHcpDataUtils.sh

	# determine name of and create temporary directory for this script's work
	local short_script_name=${g_script_name%.sh}
	local secs_since_epoch=`date +%s%3N`
	g_script_tmp_dir="${g_tmp_dir}/${g_subject}-${short_script_name}-${secs_since_epoch}"
	inform "Creating ${g_script_tmp_dir}"
	mkdir -p ${g_script_tmp_dir}

	# determine the subject's 7T resources directory
	g_subject_7T_resources_dir="${g_archive_root}/${g_seven_t_project}/arc001/${g_subject}_7T/RESOURCES"
	inform "Subject's 7T Resources Directory: ${g_subject_7T_resources_dir}"

	# start with a clean temporary directory for this subject
	rm -rf ${g_script_tmp_dir}/${g_subject}

	# get data from database resources
	get_data_from_resources

	# move all retrieved data to "full" directory
	inform ""
	inform "Move all retrieved data to _full directory"
	inform ""
	local full_directory_path=${g_script_tmp_dir}/${g_subject}_full
	mv ${g_script_tmp_dir}/${g_subject} ${full_directory_path}

	# For each modality generate a fixextended package

	for modality in REST MOVIE ; do

		inform ""
		inform "Generate fixextended package for modality: ${modality}"
		inform ""
		rm -rf ${g_script_tmp_dir}/${g_subject}
		mkdir -p ${g_script_tmp_dir}/${g_subject}
		
		file_list=""
		
		local fix_scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*${modality}*_FIX`
		for scan_dir in ${fix_scan_dirs} ; do
			inform ""
			inform "Working on scan_dir: ${scan_dir}"
			inform ""
			
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
			
			# Include in package: some specific files
			file_list+=" MNINonLinear/Results/${long_name}/${g_subject}_${long_name}_ICA_Classification_dualscreen.scene"
			file_list+=" MNINonLinear/Results/${long_name}/${g_subject}_${long_name}_ICA_Classification_singlescreen.scene"
			file_list+=" MNINonLinear/Results/${long_name}/ReclassifyAsNoise.txt "
			file_list+=" MNINonLinear/Results/${long_name}/ReclassifyAsSignal.txt "
			#file_list+=" MNINonLinear/Results/${long_name}/${long_name}_Atlas_hp2000_clean.dtseries.nii "
			#file_list+=" MNINonLinear/Results/${long_name}/${long_name}_Atlas_1.6mm_hp2000_clean.dtseries.nii "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_Atlas_stats.dscalar.nii "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_Atlas_stats.txt "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_CSF.txt "
			#file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000_clean.nii.gz " # Already in the _Volume_fix package
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_WM.txt "
			
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/Noise.txt "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/Signal.txt "
			#file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/Atlas_hp_preclean.dtseries.nii "			

			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/eigenvalues_percent "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/log.txt "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_FTmix "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_FTmix.sdseries.nii "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_IC.nii.gz "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_ICstats "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_mix "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_mix.sdseries.nii "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_oIC.dscalar.nii "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_oIC.nii.gz "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_oIC_vol.dscalar.nii "
			file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/melodic_Tmodes "
			
			# Include in package: entire MNINonLinear/Results/${long_name}/RestingStateStats directory
			pushd ${full_directory_path}/MNINonLinear/Results/${long_name}
			rss_files=`ls -1 RestingStateStats`
			for rss_file in ${rss_files} ; do
				file_list+=" MNINonLinear/Results/${long_name}/RestingStateStats/${rss_file} "
			done
			popd

			# Include in package: entire MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/report directory
			pushd ${full_directory_path}/MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica
			report_files=`ls -1 report`
			for report_file in ${report_files} ; do
				file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/filtered_func_data.ica/report/${report_file} "
			done
			popd

			# Include in package: entire MNINonLinear/ROIs directory 
			pushd ${full_directory_path}/MNINonLinear
			roi_files=`ls -1 ROIs`
			for roi_file in ${roi_files} ; do
				file_list+=" MNINonLinear/ROIs/${roi_file} "
			done
			popd

		done # FIX scan dirs loop

		# copy all the listed files over to the directory that will be zipped
		inform ""
		inform "Copying listed files to directory for zipping"
		inform ""
		for file in ${file_list} ; do
			to_dir=${g_script_tmp_dir}/${g_subject}/${file}
			to_dir=${to_dir%/*}
			mkdir -p ${to_dir}
			
			from_file=${g_script_tmp_dir}/${g_subject}_full/${file} 
			if [ -e "${from_file}" ] ; then
				to_file=${g_script_tmp_dir}/${g_subject}/${file}
				#cp -aLv --recursive ${from_file} ${to_file}
				cp -aL --recursive ${from_file} ${to_file}
			else
				inform "ERROR: FILE ${from_file} DOES NOT EXIST!"
				exit 1
			fi
		done # All listed files copied loop
		
		# create a release notes file
		inform ""
		inform "Create Release Notes"
		inform ""
		release_notes_file=${g_script_tmp_dir}/${g_subject}/release-notes/release-notes.txt
		
		mkdir -p ${g_script_tmp_dir}/${g_subject}/release-notes
		touch ${release_notes_file}
		echo `date` >> ${release_notes_file}
		echo "" >> ${release_notes_file}
		cat ${g_release_notes_template_file} >> ${release_notes_file}
		echo "" >> ${release_notes_file}
		
		# create the package		
		new_package_dir="${g_output_dir}/${g_subject}/fixextended"
		new_package_name="${g_subject}_7T_${modality}_fixextended.zip"
		new_package_path="${new_package_dir}/${new_package_name}"
		inform ""
		inform "Create Package: ${new_package_path}"
		inform ""
		
		# start with a clean slate
		rm -rf ${new_package_path}
		rm -rf ${new_package_path}.md5
		mkdir -p ${new_package_dir}
		
		# go create the zip file
		pushd ${g_script_tmp_dir}
		#zip_cmd="zip -r ${new_package_path} ${g_subject}"
		zip_cmd="zip -rq ${new_package_path} ${g_subject}"
		inform "zip_cmd: ${zip_cmd}"
		${zip_cmd}
		
		# make sure it's readable
		chmod u=rw,g=rw,o=r ${new_package_path}
		
		# create a checksum file if requested
		if [ "${g_create_checksum}" = "YES" ]; then
			inform ""
			inform " Create MD5 Checksum "
			inform ""
			
			pushd ${new_package_dir}
			md5sum ${new_package_name} > ${new_package_name}.md5
			chmod u=rw,g=rw,o=r ${new_package_name}.md5
			popd
		fi
		
		popd
		
	done # modality_list loop

	inform ""
	inform " Remove temporary directory "
	inform ""

	rm -rf ${g_script_tmp_dir}
}

#
# Invoke the main function to get things started
#
main $@
