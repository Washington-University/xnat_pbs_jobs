#!/bin/bash
set -e

inform()
{
	echo "${g_script_name}: ${1}"
}

# home directory for these XNAT PBS job scripts
if [ -z "${XNAT_PBS_JOBS}" ] ; then
	inform "XNAT_PBS_JOBS environment variable must be set!"
	exit 1
else
	inform "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"
fi

source ${XNAT_PBS_JOBS}/GetHcpDataUtils/GetHcpDataUtils.sh

get_options()
{
	local arguments=($@)

	g_script_name="CreateFixExtendedPackage.sh"
	unset g_archive_root
	unset g_tmp_dir
	unset g_subject
	unset g_three_t_project
	unset g_seven_t_project
	unset g_release_notes_template_file
	unset g_output_dir
	unset g_create_checksum
	unset g_create_contentlist
	unset g_overwrite
	unset g_ignore_missing_files
	
	# parse arguments
	local index=0
	local numArgs=${#arguments[@]}
	local argument

	while [ ${index} -lt ${numArgs} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--archive-root=*)
				g_archive_root=${argument/*=/""}
				;;
			--tmp-dir=*)
				g_tmp_dir=${argument/*=/""}
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				;;
            --three-t-project=*)
				g_three_t_project=${argument/*=/""}
                ;;
			--seven-t-project=*)
				g_seven_t_project=${argument/*=/""}
				;;
			--release-notes-template-file=*)
				g_release_notes_template_file=${argument/*=/""}
				;;
			--output-dir=*)
				g_output_dir=${argument/*=/""}
				;;
			--create-checksum)
				g_create_checksum="YES"
				;;
			--create-contentlist)
				g_create_contentlist="YES"
				;;
			--dont-overwrite)
				g_overwrite="NO"
				;;
			--overwrite)
				g_overwrite="YES"
				;;
			--ignore-missing-files)
				g_ignore_missing_files="YES"
				;;
			*)
				inform "Unrecognized Option: ${argument}"
				exit 1
				;;
		esac
		
		index=$(( index + 1 ))

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
	
	if [ -z "${g_three_t_project}" ]; then
		inform "ERROR: --three-t-project= required"
		error_count=$(( error_count + 1 ))
	else
		inform "3T project: ${g_three_t_project}"
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

	if [ -z "${g_create_contentlist}" ]; then
		g_create_contentlist="NO"
	fi
	inform "create contentlist: ${g_create_contentlist}"

	if [ -z "${g_overwrite}" ]; then
		g_overwrite="YES"
	fi
	inform "overwrite: ${g_overwrite}"

	if [ -z "${g_ignore_missing_files}" ]; then
		g_ignore_missing_files="NO"
	fi
	inform "ignore missing files: ${g_ignore_missing_files}"
	
	if [ ${error_count} -gt 0 ]; then
		inform "Option errors detected: EXITING"
		exit 1
	fi
}

main()
{
	# get options 
	get_options $@

	# determine name of and create temporary directory for this script's work
	local short_script_name=${g_script_name%.sh}
	local secs_since_epoch=`date +%s%3N`
	script_tmp_dir="${g_tmp_dir}/${g_subject}-${short_script_name}-${secs_since_epoch}"
	inform "Creating ${script_tmp_dir}"
	${XNAT_PBS_JOBS}/shlib/try_mkdir ${script_tmp_dir}
	if [ $? -ne 0 ]; then
		exit 1
	fi
	
	# determine subject's 3T resources directory
	g_subject_3T_resources_dir="${g_archive_root}/${g_three_t_project}/arc001/${g_subject}_3T/RESOURCES"

	# determine the subject's 7T resources directory
	g_subject_7T_resources_dir="${g_archive_root}/${g_seven_t_project}/arc001/${g_subject}_7T/RESOURCES"

	# start with a clean temporary directory for this subject
	rm -rf ${script_tmp_dir}/${g_subject}

	# build a standard CinaB style data directory
	${XNAT_PBS_JOBS}/7T/PackageUtils/build_standard_structure.sh \
					--archive-root="${g_archive_root}" \
					--dest-dir="${script_tmp_dir}" \
					--subject="${g_subject}" \
					--three-t-project="${g_three_t_project}" \
					--seven-t-project="${g_seven_t_project}"

	# move all retrieved data to "full" directory
	inform ""
	inform "Move all retrieved data to _full directory"
	inform ""
	local full_directory_path=${script_tmp_dir}/${g_subject}_full
	mv ${script_tmp_dir}/${g_subject} ${full_directory_path}

	# For each modality generate a fixextended package

	for modality in MOVIE REST RET ; do

		inform ""
		inform " Determine Package Name and Path"
		inform ""
		new_package_dir="${g_output_dir}/${g_subject}/fixextended"
		new_package_name="${g_subject}_7T_${modality}_fixextended.zip"
		new_package_path="${new_package_dir}/${new_package_name}"

		if [ -e "${new_package_path}" ] ; then
			if [ "${g_overwrite}" = "NO" ]; then
				inform "Package: ${new_package_path} exists and I've been told not to overwrite."
				inform "So, I'm moving on without creating that package."
				continue
			fi
		fi

		# if we get here, then we want to create the package
		inform ""
		inform "Generate fixextended package for modality: ${modality}"
		inform ""
		rm -rf ${script_tmp_dir}/${g_subject}
		mkdir -p ${script_tmp_dir}/${g_subject}
		
		file_list=""

		if [ "${modality}" = "RET" ]; then

			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/${g_subject}_tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_ICA_Classification_dualscreen.scene "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/${g_subject}_tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_ICA_Classification_singlescreen.scene "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/Movement_Regressors_demean.txt "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/ReclassifyAsNoise.txt "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/ReclassifyAsSignal.txt "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_1.6mm.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_1.6mm_hp2000_clean.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_1.6mm_hp2000.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_1.6mm_MSMAll.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_1.6mm_MSMAll_hp2000_clean.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_1.6mm_MSMAll_hp2000.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_hp2000_clean.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_hp2000.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_MSMAll.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_MSMAll_hp2000_clean.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_Atlas_MSMAll_hp2000.dtseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000_clean.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/eigenvalues_percent "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/log.txt "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_FTmix "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_FTmix.sdseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_IC.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_ICstats "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_mix "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_mix.sdseries.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_oIC.dscalar.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_oIC.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_oIC_vol.dscalar.nii "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/melodic_Tmodes "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/mc/prefiltered_func_data_mcf_conf_hp.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/mc/prefiltered_func_data_mcf_conf.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/Noise.txt "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/Signal.txt "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_SBRef.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_RETBAR1_7T_AP/tfMRI_RETBAR1_7T_AP_hp2000_clean.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_RETBAR2_7T_PA/tfMRI_RETBAR2_7T_PA_hp2000_clean.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_RETCCW_7T_AP/tfMRI_RETCCW_7T_AP_hp2000_clean.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_RETCON_7T_PA/tfMRI_RETCON_7T_PA_hp2000_clean.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_RETCW_7T_PA/tfMRI_RETCW_7T_PA_hp2000_clean.nii.gz "
			file_list+=" MNINonLinear/Results/tfMRI_RETEXP_7T_AP/tfMRI_RETEXP_7T_AP_hp2000_clean.nii.gz "
			file_list+=" MNINonLinear/ROIs/CSFReg.1.60.nii.gz "
			file_list+=" MNINonLinear/ROIs/WMReg.1.60.nii.gz "

			pushd ${full_directory_path}/MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica
			report_files=$(ls -1 report)
			for report_file in ${report_files} ; do
				file_list+=" MNINonLinear/Results/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA/tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA_hp2000.ica/filtered_func_data.ica/report/${report_file} "
			done
			popd

		else  # MOVIE or REST
		
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

				file_list+=" MNINonLinear/Results/${long_name}/${g_subject}_${long_name}_ICA_Classification_dualscreen.scene "
				file_list+=" MNINonLinear/Results/${long_name}/${g_subject}_${long_name}_ICA_Classification_singlescreen.scene "
				file_list+=" MNINonLinear/Results/${long_name}/ReclassifyAsNoise.txt "
				file_list+=" MNINonLinear/Results/${long_name}/ReclassifyAsSignal.txt "

				file_list+=" MNINonLinear/Results/${long_name}/${long_name}_Atlas_stats.dscalar.nii "
				file_list+=" MNINonLinear/Results/${long_name}/${long_name}_Atlas_stats.txt "
				file_list+=" MNINonLinear/Results/${long_name}/${long_name}_CSF.txt "
				file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000_clean.nii.gz "
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

				file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/Noise.txt "
				file_list+=" MNINonLinear/Results/${long_name}/${long_name}_hp2000.ica/Signal.txt "
				file_list+=" MNINonLinear/Results/${long_name}/${long_name}_WM.txt "

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
								
			done

			file_list+=" MNINonLinear/ROIs/CSFReg.1.60.nii.gz "
			file_list+=" MNINonLinear/ROIs/WMReg.1.60.nii.gz "

		fi
		
		# copy all the listed files over to the directory that will be zipped
		inform ""
		inform "Copying listed files to directory for zipping"
		inform ""
		for file in ${file_list} ; do
			to_dir=${script_tmp_dir}/${g_subject}/${file}
			to_dir=${to_dir%/*}
			mkdir -p ${to_dir}
			
			from_file=${script_tmp_dir}/${g_subject}_full/${file} 
			to_file=${script_tmp_dir}/${g_subject}/${file}
			inform "from_file = ${from_file}"
			inform "  to_file = ${to_file}"
			if [ -e "${from_file}" ] ; then
				# cp -aLv --recursive ${from_file} ${to_file}
				# cp -aL --recursive ${from_file} ${to_file}
				ln -s ${from_file} ${to_file}
			else
				inform "FILE ${from_file} DOES NOT EXIST!"
				if [ "${g_ignore_missing_files}" = "YES" ]; then
					inform "Ignoring missing file as instructed"
				else
					inform "ABORTING BECAUSE OF MISSING FILE"
					exit 1
				fi
			fi
		done # All listed files copied loop
		
		# create a release notes file
		inform ""
		inform "Create Release Notes"
		inform ""
		release_notes_file=${script_tmp_dir}/${g_subject}/release-notes/${g_subject}_7T_${modality}_fixextended.txt
		
		mkdir -p ${script_tmp_dir}/${g_subject}/release-notes
		touch ${release_notes_file}
		echo `date` >> ${release_notes_file}
		echo "" >> ${release_notes_file}
		cat ${g_release_notes_template_file} >> ${release_notes_file}
		echo "" >> ${release_notes_file}
		
		# create the package		
		inform ""
		inform "Create Package: ${new_package_path}"
		inform ""
		
		# start with a clean slate
		rm -rf ${new_package_path}
		rm -rf ${new_package_path}.md5
		mkdir -p ${new_package_dir}
		
		# go create the zip file
		pushd ${script_tmp_dir}
		#zip_cmd="zip -r ${new_package_path} ${g_subject}"
		zip_cmd="zip -rq ${new_package_path} ${g_subject}"
		inform "zip_cmd: ${zip_cmd}"
		${zip_cmd}
		
		# make sure it's readable
		chmod u=rw,g=rw,o=r ${new_package_path}
		
		# create a checksum file if requested
		if [ "${g_create_checksum}" = "YES" ]; then
			${XNAT_PBS_JOBS}/PackageUtils/create_checksum.sh \
							--package-dir="${new_package_dir}" \
							--package-name="${new_package_name}"
		fi

		# create contentlist file if requested
		if [ "${g_create_contentlist}" = "YES" ]; then
			${XNAT_PBS_JOBS}/PackageUtils/build_content_list.sh \
							--package-dir="${new_package_dir}" \
							--package-name="${new_package_name}"
		fi
		
		popd
		
	done # modality_list loop

	inform ""
	inform " Remove temporary directory "
	inform ""

	rm -rf ${script_tmp_dir}
}

#
# Invoke the main function to get things started
#
main $@
