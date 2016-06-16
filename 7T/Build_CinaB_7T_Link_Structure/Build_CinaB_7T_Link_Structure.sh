#!/bin/bash

g_script_name=`basename ${0}`

inform()
{
	echo "${g_script_name}: ${1}"
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

	unset g_archive_root
	unset g_subject
	unset g_three_t_project
	unset g_seven_t_project
	unset g_output_dir

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
            --three-t-project=*)
				g_three_t_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --seven-t-project=*)
				g_seven_t_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --output-dir=*)
                g_output_dir=${argument/*=/""}
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
        inform "ERROR: --archive-root= required (e.g. --archive-root=/HCP/hcpdb/archive)"
        error_count=$(( error_count + 1 ))
    else
        inform "archive root: ${g_archive_root}"
    fi

    if [ -z "${g_subject}" ]; then
        inform "ERROR: --subject= required (e.g. --subject=100307)"
        error_count=$(( error_count + 1 ))
    else
        inform "subject: ${g_subject}"
    fi

	if [ -z "${g_three_t_project}" ]; then
		inform "ERROR: --three-t-project= required (e.g. --three-t-project=HCP_500)"
		error_count=$(( error_count + 1 ))
	else
		inform "3T project: ${g_three_t_project}"
	fi

	if [ -z "${g_seven_t_project}" ]; then
		inform "ERROR: --seven-t-project= required (e.g. --seven-t-project=HCP_Staging_7T)"		
		error_count=$(( error_count + 1 ))
	else
		inform "7T project: ${g_seven_t_project}"
	fi

    if [ -z "${g_output_dir}" ]; then
        inform "ERROR: --output-dir= required (e.g. --output-dir=/tmp)"
        error_count=$(( error_count + 1 ))
    else
        inform "output dir: ${g_output_dir}"
    fi

    if [ ${error_count} -gt 0 ]; then
        echo "ERRORS DETECTED: EXITING"
        exit 1
    fi
}

build_standard_structure()
{
	# DeDriftAndResample HighRes
	link_hcp_resampled_and_dedrifted_highres_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_output_dir}" 

	# DeDriftAndResample
	link_hcp_resampled_and_dedrifted_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_output_dir}" 

	# PostFix data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_PostFix`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_PostFix}
		link_hcp_postfix_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_output_dir}"
	done

	# FIX processed data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_FIX`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_FIX}
		link_hcp_fix_proc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_output_dir}" 
	done

	# Functional preproc
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*fMRI*preproc`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_preproc}
		link_hcp_func_preproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_output_dir}" 
	done

	# Supplemental struc preproc	
	link_hcp_supplemental_struct_preproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${g_output_dir}" 

	# Structurally preproc
	link_hcp_struct_preproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${g_output_dir}"

	# unproc

	link_hcp_struct_unproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${g_output_dir}"
	link_hcp_7T_resting_state_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_output_dir}"
	link_hcp_7T_diffusion_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_output_dir}"
	link_hcp_7T_task_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_output_dir}"

	# remove db archive artifacts

	pushd ${g_output_dir}
	find . -name "*job.sh*" -delete
	find . -name "*catalog.xml" -delete
	find . -name "*Provenance.xml" -delete
	find . -name "*matlab.log" -delete
	find . -name "StructuralHCP.err" -delete
	find . -name "StructuralHCP.log" -delete
	find . -name "*starttime" -delete
	popd
}

main()
{
	get_options $@
	
	mkdir -p --verbose ${g_output_dir}

	g_subject_3T_resources_dir="${g_archive_root}/${g_three_t_project}/arc001/${g_subject}_3T/RESOURCES"
	g_subject_7T_resources_dir="${g_archive_root}/${g_seven_t_project}/arc001/${g_subject}_7T/RESOURCES"

	rm -rf --verbose ${g_output_dir}/${g_subject}

	build_standard_structure
}

#
# Invoke the main function to get things started
#
main $@
