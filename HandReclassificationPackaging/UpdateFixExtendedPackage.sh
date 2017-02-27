#!/bin/bash

#set -e

inform() 
{
	local msg=${1}
	echo "${g_script_name}: ${msg}"
}

get_options()
{
	local arguments=($@)

	unset g_script_name
	unset g_current_packages_root	# e.g. /HCP/hcpdb/packages/live
	unset g_archive_root			# e.g. /HCP/hcpdb/archive
	unset g_output_dir
	unset g_tmp_dir					# e.g. /HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp
	unset g_subject
	unset g_project
	unset g_scan_no

	g_script_name=`basename ${0}`

    # parse arguments
    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --current-packages-root=*)
                g_current_packages_root=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --archive-root=*)
                g_archive_root=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --output-dir=*)
                g_output_dir=${argument/*=/""}
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
            --project=*)
                g_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --scan-no=*)
                g_scan_no=${argument/*=/""}
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

	if [ -z "${g_current_packages_root}" ] ; then
		inform "ERROR: --current-packages-root= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_current_packages_root: ${g_current_packages_root}"
	fi

	if [ -z "${g_archive_root}" ] ; then
		inform "ERROR: --archive-root= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_archive_root: ${g_archive_root}"
	fi

	if [ -z "${g_output_dir}" ] ; then
		inform "ERROR: --output-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_output_dir: ${g_output_dir}"
	fi

	if [ -z "${g_tmp_dir}" ] ; then
		inform "ERROR: --tmp-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_tmp_dir: ${g_tmp_dir}"
	fi

	if [ -z "${g_subject}" ] ; then
		inform "ERROR: --subject= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_project}" ] ; then
		inform "ERROR: --project= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_project: ${g_project}"
	fi

	if [ "${g_scan_no}" != "1" -a "${g_scan_no}" != "2" ] ; then
		inform "ERROR: --scan-no=[1|2] required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_scan_no: ${g_scan_no}"
	fi

    if [ ${error_count} -gt 0 ]; then
        inform "ERRORS DETECTED: EXITING"
        exit 1
    fi
}

main()
{
	# get command line options
	get_options $@

	mkdir -p ${g_tmp_dir}

	# copy current package to tmp space
	package_name=${g_subject}_3T_rfMRI_REST${g_scan_no}_fixextended.zip

	current_package_path=""
	current_package_path+="${g_current_packages_root}/HCP_1200/${g_subject}/fixextended"
	current_package_path+="/${package_name}"

	cp -a ${current_package_path} ${g_tmp_dir}

	# unzip current package contents
	pushd ${g_tmp_dir}
	unzip ${package_name}
	rm ${package_name}

	# figure out what HandReclassification directories exist
	subject_resources_dir=${g_archive_root}/${g_project}/arc001/${g_subject}_3T/RESOURCES
	handreclassification_resources=`ls -d ${subject_resources_dir}/rfMRI_REST${g_scan_no}*_HandReclassification`

	# get files from hand reclassification directories
	for handreclassification_resource in ${handreclassification_resources} ; do
		inform "handreclassification_resource: ${handreclassification_resource}"

		scan=${handreclassification_resource##*/}
		scan=${scan%_HandReclassification}
		inform "scan: ${scan}"

		file=${g_subject}/MNINonLinear/Results/${scan}/ReclassifyAsNoise.txt
		cp -va ${handreclassification_resource}/${file} ${g_tmp_dir}/${file}

		file=${g_subject}/MNINonLinear/Results/${scan}/ReclassifyAsSignal.txt
		cp -va ${handreclassification_resource}/${file} ${g_tmp_dir}/${file}
	done

	# figure out what ApplyHandReClassification directories exist
	subject_resources_dir=${g_archive_root}/${g_project}/arc001/${g_subject}_3T/RESOURCES
	resources=`ls -d ${subject_resources_dir}/rfMRI_REST${g_scan_no}*_ApplyHandReClassification`

	# get files
	for resource in ${resources} ; do
		inform "resource: ${resource}"

		scan=${resource##*/}
		scan=${scan%_ApplyHandReClassification}
		inform "scan: ${scan}"

		file=${g_subject}/MNINonLinear/Results/${scan}/${scan}_hp2000.ica/hand_labels_noise.txt
		cp -va ${resource}/${file} ${g_tmp_dir}/${file}

		file=${g_subject}/MNINonLinear/Results/${scan}/${scan}_hp2000.ica/HandNoise.txt
		cp -va ${resource}/${file} ${g_tmp_dir}/${file}

		file=${g_subject}/MNINonLinear/Results/${scan}/${scan}_hp2000.ica/HandSignal.txt
		cp -va ${resource}/${file} ${g_tmp_dir}/${file}
	done

	# figure out what ReApplyFix directories exist
	subject_resources_dir=${g_archive_root}/${g_project}/arc001/${g_subject}_3T/RESOURCES
	reapply_fix_resources=`ls -d ${subject_resources_dir}/rfMRI_REST${g_scan_no}*_ReApplyFix`

	# get files from ReApplyFix directories
	for reapply_fix_resource in ${reapply_fix_resources} ; do
		inform "reapply_fix_resource: ${reapply_fix_resource}"

		scan=${reapply_fix_resource##*/}
		scan=${scan%_ReApplyFix}
		inform "scan: ${scan}"

		# *_Atlas_hp2000_clean.dtseries.nii
		file=${g_subject}/MNINonLinear/Results/${scan}/${scan}_Atlas_hp2000_clean.dtseries.nii
		cp -va ${reapply_fix_resource}/${file} ${g_tmp_dir}/${file}

		file=${g_subject}/MNINonLinear/Results/${scan}/${scan}_hp2000_clean.nii.gz
		cp -va ${reapply_fix_resource}/${file} ${g_tmp_dir}/${file}
	done

	# # figure out what ReApplyFixMsmAll directories exist
	# subject_resources_dir=${g_archive_root}/${g_project}/arc001/${g_subject}_3T/RESOURCES
	# reapply_fix_msmall_resources=`ls -d ${subject_resources_dir}/rfMRI_REST${g_scan_no}*_ReApplyFixMsmAll`

	# # get files from ReApplyFixMsmAll directories
	# for reapply_fix_msmall_resource in ${reapply_fix_msmall_resources} ; do
	# 	inform "reapply_fix_msmall_resource: ${reapply_fix_msmall_resource}"

	# 	scan=${reapply_fix_msmall_resource##*/}
	# 	scan=${scan%_ReApplyFixMsmAll}
	# 	inform "scan: ${scan}"
	# done

	# figure out what RSS directories exist
	subject_resources_dir=${g_archive_root}/${g_project}/arc001/${g_subject}_3T/RESOURCES
	rss_resources=`ls -d ${subject_resources_dir}/rfMRI_REST${g_scan_no}*_RSS`

	# get files from Resting State Stats (RSS) directories
	for rss_resource in ${rss_resources} ; do
		inform "rss_resource: ${rss_resource}"

		scan=${rss_resource##*/}
		scan=${scan%_RSS}
		inform "scan: ${scan}"

		file=MNINonLinear/Results/${scan}/${scan}_Atlas_stats.dscalar.nii
		cp -va ${rss_resource}/${file} ${g_tmp_dir}/${g_subject}/${file}

		file=MNINonLinear/Results/${scan}/${scan}_Atlas_stats.txt
		cp -va ${rss_resource}/${file} ${g_tmp_dir}/${g_subject}/${file}

		file=MNINonLinear/Results/${scan}/${scan}_CSF.txt
		cp -va ${rss_resource}/${file} ${g_tmp_dir}/${g_subject}/${file}

		file=MNINonLinear/Results/${scan}/${scan}_WM.txt
		cp -va ${rss_resource}/${file} ${g_tmp_dir}/${g_subject}/${file}

		cp -va ${rss_resource}/MNINonLinear/Results/${scan}/RestingStateStats/* ${g_tmp_dir}/${g_subject}/MNINonLinear/Results/${scan}/RestingStateStats

		file=MNINonLinear/ROIs/CSFReg.2.nii.gz
		cp -va ${rss_resource}/${file} ${g_tmp_dir}/${g_subject}/${file}

		file=MNINonLinear/ROIs/WMReg.2.nii.gz
		cp -va ${rss_resource}/${file} ${g_tmp_dir}/${g_subject}/${file}
	done
	
	# Make new zip file
	zip -r ${package_name} ${g_subject}
	chmod u=rw,g=rw,o=r ${package_name}
	md5sum ${package_name} > ${package_name}.md5
	chmod u=rw,g=rw,o=r ${package_name}.md5

	mkdir -p ${g_output_dir}
	mv ${package_name} ${g_output_dir}
	mv ${package_name}.md5 ${g_output_dir}

	popd

	rm -rf ${g_tmp_dir}
}

# Invoke main to get things started
main $@