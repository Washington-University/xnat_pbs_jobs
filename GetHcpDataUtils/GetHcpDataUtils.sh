# Path to tools used
if [ "${COMPUTE}" = "CHPC" ]; then
	if [ "${CLUSTER}" = "1.0" ] ; then
		PATH_TO_LNDIR="/export/lndir-1.0.1/bin/lndir"
	elif [ "${CLUSTER}" = "2.0" ]; then
		PATH_TO_LNDIR="/export/HCP/lndir-1.0.1/bin/lndir"
	else
		echo "GetHcpDataUtils.sh: ERROR - Unable to set PATH_TO_LNDIR value based on CLUSTER: ${CLUSTER}"
		exit 1
	fi
elif [ "${COMPUTE}" = "NRG" ]; then
	PATH_TO_LNDIR="${HOME}/export/lndir-1.0.1/bin/lndir"
else
	echo "GetHcpDataUtils.sh: ERROR - Unable to set PATH_TO_LNDIR value based on COMPUTE: ${COMPUTE}"
	exit 1
fi

# Database Resource names and suffixes
source ${XNAT_PBS_JOBS}/GetHcpDataUtils/ResourceNamesAndSuffixes.sh

link_hcp_struct_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP 3T Structural Unprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local resource_dir=""
	resource_dir+="${archive}"
	resource_dir+="/${project}"
	resource_dir+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	resource_dir+="/${session}"
	resource_dir+="/${DATABASE_RESOURCES_ROOT}"

	T1w_resources=`find ${resource_dir} -maxdepth 1 -name T1w*_unproc`
	for T1w_resource in ${T1w_resources} ; do
		local T1w_resource=${T1w_resource##*/}
		local T1w_dir=${T1w_resource%_unproc}  

		local link_from=""
		link_from+="${archive}"
		link_from+="/${project}"
		link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
		link_from+="/${session}"
		link_from+="/${DATABASE_RESOURCES_ROOT}"
		link_from+="/${T1w_resource}/*"

		local link_to=""
		link_to="${to_study_dir}/${subject}/unprocessed/3T/${T1w_dir}"
		mkdir --parents ${link_to}

		local link_cmd=""
		link_cmd="cp -sR ${link_from} ${link_to}"
		echo "link_cmd: ${link_cmd}"

		echo "----------" `date` "----------"
		echo ""
		${link_cmd}
	done
	
	T2w_resources=`find ${resource_dir} -maxdepth 1 -name T2w*_unproc`
	for T2w_resource in ${T2w_resources} ; do
		local T2w_resource=${T2w_resource##*/}
		local T2w_dir=${T2w_resource%_unproc}

		local link_from=""
		link_from+="${archive}"
		link_from+="/${project}"
		link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
		link_from+="/${session}"
		link_from+="/${DATABASE_RESOURCES_ROOT}"
		link_from+="/${T2w_resource}/*"

		local link_to=""
		link_to="${to_study_dir}/${subject}/unprocessed/3T/${T2w_dir}"
		mkdir --parents ${link_to}

		local link_cmd=""
		link_cmd="cp -sR ${link_from} ${link_to}"
		echo "link_cmd: ${link_cmd}"

		echo "----------" `date` "----------"
		echo ""
		${link_cmd}
	done

	popd
}

internal_link_hcp_resting_state_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}
	local unprocessed_subdir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Resting State Unprocessed data from archive to unprocessed/${unprocessed_subdir}"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local resource_dir=""
	resource_dir+="${archive}"
	resource_dir+="/${project}"
	resource_dir+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	resource_dir+="/${session}"
	resource_dir+="/${DATABASE_RESOURCES_ROOT}"

	resting_state_resources=`find ${resource_dir} -maxdepth 1 -name rfMRI_REST*_unproc`
	for resting_state_resource in ${resting_state_resources} ; do
		local resting_state_resource=${resting_state_resource##*/}
		local resting_state_dir=${resting_state_resource%_unproc}

		local link_from=""
		link_from+="${archive}"
		link_from+="/${project}"
		link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
		link_from+="/${session}"
		link_from+="/${DATABASE_RESOURCES_ROOT}"
		link_from+="/${resting_state_resource}/*"

		local link_to=""
		link_to="${to_study_dir}/${subject}/unprocessed/${unprocessed_subdir}/${resting_state_dir}"
		mkdir --parents ${link_to}

		local link_cmd=""
		link_cmd="cp -sR ${link_from} ${link_to}"
		echo "link_cmd: ${link_cmd}"

		echo "----------" `date` "----------"
		echo ""
		${link_cmd}
	done
	
	popd
}

link_hcp_3T_resting_state_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	internal_link_hcp_resting_state_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}" "3T"
}

link_hcp_7T_resting_state_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_7T
	local to_study_dir=${5}

	internal_link_hcp_resting_state_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}" "7T"
}

link_hcp_resting_state_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	link_hcp_3T_resting_state_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}"
}

internal_link_hcp_diffusion_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}
	local unprocessed_subdir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Diffusion Unprocessed data from archive to unprocessed/${unprocessed_subdir}"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local resource_dir=""
	resource_dir+="${archive}"
	resource_dir+="/${project}"
	resource_dir+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	resource_dir+="/${session}"
	resource_dir+="/${DATABASE_RESOURCES_ROOT}"

	diffusion_resources=`find ${resource_dir} -maxdepth 1 -name Diffusion*_unproc`
	for diffusion_resource in ${diffusion_resources} ; do
		local diffusion_resource=${diffusion_resource##*/}
		local diffusion_dir=${diffusion_resource%_unproc}

		local link_from=""
		link_from+="${archive}"
		link_from+="/${project}"
		link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
		link_from+="/${session}"
		link_from+="/${DATABASE_RESOURCES_ROOT}"
		link_from+="/${diffusion_resource}/*"

		local link_to=""
		link_to="${to_study_dir}/${subject}/unprocessed/${unprocessed_subdir}/${diffusion_dir}"
		mkdir --parents ${link_to}

		local link_cmd=""
		link_cmd="cp -sR ${link_from} ${link_to}"
		echo "link_cmd: ${link_cmd}"

		echo "----------" `date` "----------"
		echo ""
		${link_cmd}
	done
	
	popd
}

link_hcp_3T_diffusion_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	internal_link_hcp_diffusion_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}" "3T"
}

link_hcp_7T_diffusion_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_7T
	local to_study_dir=${5}

	internal_link_hcp_diffusion_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}" "7T"
}

link_hcp_diffusion_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	link_hcp_3T_diffusion_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}"
}

internal_link_hcp_task_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}
	local unprocessed_subdir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Task Unprocessed data from archive to unprocessed/${unprocessed_subdir}"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local resource_dir=""
	resource_dir+="${archive}"
	resource_dir+="/${project}"
	resource_dir+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	resource_dir+="/${session}"
	resource_dir+="/${DATABASE_RESOURCES_ROOT}"

	task_resources=`find ${resource_dir} -maxdepth 1 -name tfMRI*_unproc`
	for task_resource in ${task_resources} ; do
		local task_resource=${task_resource##*/}
		local task_dir=${task_resource%_unproc}

		local link_from=""
		link_from+="${archive}"
		link_from+="/${project}"
		link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
		link_from+="/${session}"
		link_from+="/${DATABASE_RESOURCES_ROOT}"
		link_from+="/${task_resource}/*"

		local link_to=""
		link_to="${to_study_dir}/${subject}/unprocessed/${unprocessed_subdir}/${task_dir}"
		mkdir --parents ${link_to}

		local link_cmd=""
		link_cmd="cp -sR ${link_from} ${link_to}"
		echo "link_cmd: ${link_cmd}"

		echo "----------" `date` "----------"
		echo ""
		${link_cmd}
	done
	
	popd
}

link_hcp_3T_task_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	internal_link_hcp_task_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}" "3T"
}

link_hcp_7T_task_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	internal_link_hcp_task_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}" "7T"
}

link_hcp_task_unproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	link_hcp_3T_task_unproc_data "${archive}" "${project}" "${subject}" "${session}" "${to_study_dir}"
}

link_hcp_struct_preproc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Structurally Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${STRUCTURAL_PREPROC_RESOURCE_NAME}/"

    local link_to=""
    link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

link_hcp_supplemental_struct_preproc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Supplemental Structurally Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${STRUCTURAL_PREPROC_SUPPLEMENTAL_RESOURCE_NAME}/"

    local link_to=""
    link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

get_hcp_struct_preproc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP Structurally Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${STRUCTURAL_PREPROC_RESOURCE_NAME}/*"

    local copy_to=""
    copy_to="${to_study_dir}/${subject}"

    local rsync_cmd=""
    rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
    echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

    popd
}

link_hcp_func_preproc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Functional Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}${FUNCTIONAL_PREPROC_RESOURCE_SUFFIX}/"

    local link_to=""
    link_to="${to_study_dir}/${subject}"

    local lndir_cmd=""
    lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
    echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

get_hcp_func_preproc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP Functional Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${scan}${FUNCTIONAL_PREPROC_RESOURCE_SUFFIX}/*"

    local copy_to=""
    copy_to="${to_study_dir}/${subject}"

    local rsync_cmd=""
    rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
    echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

    popd
}

link_hcp_diffusion_preproc_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5} 

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Diffusion Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
	link_from+="${archive}"
	link_from+="/${project}"
	link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	link_from+="/${session}"
	link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/Diffusion_preproc/"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

get_hcp_diffusion_preproc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP Diffusion Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/Diffusion_preproc/*"

	local copy_to=""
	copy_to="${to_study_dir}/${subject}"

	local rsync_cmd=""
	rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
	echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

    popd
}

link_hcp_reapplyfix_proc_data() 
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hdpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP ReApplyFix Processed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
	link_from+="${archive}"
	link_from+="/${project}"
	link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	link_from+="/${session}"
	link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${scan}_ReApplyFix/${subject}/"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

link_hcp_applyhandreclassification_data() 
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hdpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP ApplyHandReclassification data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
	link_from+="${archive}"
	link_from+="/${project}"
	link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	link_from+="/${session}"
	link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${scan}_ApplyHandReClassification/${subject}/"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

link_hcp_handreclassification_data() 
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hdpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP HandReclassification data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
	link_from+="${archive}"
	link_from+="/${project}"
	link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	link_from+="/${session}"
	link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${scan}_HandReclassification/${subject}/"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

link_hcp_fix_proc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hdpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP FIX Processed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}/MNINonLinear/Results

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}${FIX_PROC_RESOURCE_SUFFIX}/"

    local link_to=""
    link_to="${to_study_dir}/${subject}/MNINonLinear/Results"

    local lndir_cmd=""
    lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
    echo "lndir_cmd: ${lndir_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

link_hcp_concatenated_fix_proc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hdpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP CONCATENATED FIX Processed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}
	
    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}${FIX_PROC_RESOURCE_SUFFIX}/${subject}"

    local link_to=""
    link_to="${to_study_dir}/${subject}"

    local lndir_cmd=""
    lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
    echo "lndir_cmd: ${lndir_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

get_hcp_fix_proc_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hdpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP FIX Processed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}/MNINonLinear/Results

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${scan}${FIX_PROC_RESOURCE_SUFFIX}/*"

    local copy_to=""
    copy_to="${to_study_dir}/${subject}/MNINonLinear/Results"

    local rsync_cmd=""
    rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
    echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

    popd
}

link_hcp_postfix_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hdpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP PostFix data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}/MNINonLinear/Results/${scan}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}${POSTFIX_PROC_RESOURCE_SUFFIX}/MNINonLinear"

    local link_to=""
    link_to="${to_study_dir}/${subject}/MNINonLinear"

    local lndir_cmd=""
    lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
    echo "lndir_cmd: ${lndir_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

get_hcp_postfix_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP PostFix data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}/MNINonLinear/Results/${scan}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${scan}${POSTFIX_PROC_RESOURCE_SUFFIX}/MNINonLinear"

    local copy_to=""
    copy_to="${to_study_dir}/${subject}"

    local rsync_cmd=""
    rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
    echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

    popd
}

link_hcp_7T_resting_state_stats_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_Staging_7T
	local subject=${3} # e.g. 102816
	local session=${4} # e.g. 102816_7T
	local scan=${5}    # e.g. rfMRI_REST1_PA
	local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
	echo "Linking HCP 7T Resting State Stats data from archive"
	echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
	link_from+="${archive}"
	link_from+="/${project}"
	link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	link_from+="/${session}"
	link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${scan}${RESTING_STATE_STATS_PROC_RESOURCE_SUFFIX}"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

link_hcp_resting_state_stats_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Resting State Stats data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}/MNINonLinear/Results/${scan}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}${RESTING_STATE_STATS_PROC_RESOURCE_SUFFIX}/MNINonLinear/Results/${scan}"

    local link_to=""
    link_to="${to_study_dir}/${subject}/MNINonLinear/Results/${scan}"

    local lndir_cmd=""
    lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
    echo "lndir_cmd: ${lndir_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

get_hcp_resting_state_stats_data()
{
    local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
    local project=${2} # e.g. HCP_500
    local subject=${3} # e.g. 100307
    local session=${4} # e.g. 100307_3T
    local scan=${5}    # e.g. rfMRI_REST1_RL
    local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP Resting State Stats data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir --parents ${subject}/MNINonLinear/Results/${scan}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${scan}${RESTING_STATE_STATS_PROC_RESOURCE_SUFFIX}/MNINonLinear/Results/${scan}"

    local copy_to=""
    copy_to="${to_study_dir}/${subject}/MNINonLinear/Results"

    local rsync_cmd=""
    rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
    echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

    popd
}

link_hcp_msm_all_registration_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP MSM All Registration data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${MSM_ALL_REGISTRATION_RESOURCE_NAME}"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

# UNTESTED
#
# get_hcp_msm_all_registration_data()
# {
# 	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
# 	local project=${2} # e.g. HCP_500
# 	local subject=${3} # e.g. 100307
# 	local session=${4} # e.g. 100307_3T
# 	local to_study_dir=${5}

# 	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
# 	local DATABASE_RESOURCES_ROOT="RESOURCES"

# 	echo ""
# 	echo "----------" `date` "----------"
#     echo "Copying HCP MSM All Registration data from archive"
#     echo " Archive: ${archive}"
#     echo " Project: ${project}"
#     echo " Subject: ${subject}"
#     echo " Session: ${session}"
#     echo " To Study Directory: ${to_study_dir}"

# 	pushd ${to_study_dir}

# 	mkdir --parents ${subject}

# 	local copy_from=""
#     copy_from+="${archive}"
#     copy_from+="/${project}"
#     copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
#     copy_from+="/${session}"
#     copy_from+="/${DATABASE_RESOURCES_ROOT}"
#     copy_from+="/${MSM_ALL_REGISTRATION_RESOURCE_NAME}/"

# 	local copy_to=""
# 	copy_to="${to_study_dir}/${subject}"

# 	local rsync_cmd=""
# 	rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
# 	echo "rsync_cmd: ${rsync_cmd}"
# 	echo "----------" `date` "----------"
# 	echo ""
#     ${rsync_cmd}

#     popd
# }

link_hcp_msm_group_average_drift_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_Staging or HCP_500
	local to_study_dir=${3}

	local DATABASE_ARCHIVE_PROJECT_LEVEL_RESOURCES_ROOT="resources"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP MSM Group Average Drift data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " To Study Directory: ${to_study_dir}"

	local link_from=""
	link_from+="${archive}"
	link_from+="/${project}"
	link_from+="/${DATABASE_ARCHIVE_PROJECT_LEVEL_RESOURCES_ROOT}"
	link_from+="/${MSM_ALL_DEDRIFT_RESOURCE_NAME}"

	local link_to=""
	link_to="${to_study_dir}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"
	
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}
}

get_hcp_msm_group_average_drift_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
    local to_study_dir=${3}

	local DATABASE_ARCHIVE_PROJECT_LEVEL_RESOURCES_ROOT="resources"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP MSM Group Average Drift data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " To Study Directory: ${to_study_dir}"
	
	local copy_from=""
	copy_from+="${archive}"
	copy_from+="/${project}"
	copy_from+="/${DATABASE_ARCHIVE_PROJECT_LEVEL_RESOURCES_ROOT}"
	copy_from+="/${MSM_ALL_DEDRIFT_RESOURCE_NAME}/"

	local copy_to=""
	copy_to="${to_study_dir}"

	local rsync_cmd=""
	rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
	echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
	
	${rsync_cmd}
}

link_hcp_resampled_and_dedrifted_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP resampled and dedrifted data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${MSM_ALL_DEDRIFT_RESOURCE_NAME}"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

get_hcp_resampled_and_dedrifted_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP resampled and dedrifted data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
	echo " Subject: ${subject}"
	echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local copy_from=""
	copy_from+="${archive}"
	copy_from+="/${project}"
	copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	copy_from+="/${session}"
	copy_from+="/${DATABASE_RESOURCES_ROOT}"
	copy_from+="/${MSM_ALL_DEDRIFT_RESOURCE_NAME}/*"

	local copy_to=""
	copy_to="${to_study_dir}/${subject}"

	local rsync_cmd=""
	rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
	echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

	popd
}

link_hcp_resampled_and_dedrifted_highres_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP resampled and dedrifted highres data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${MSM_ALL_DEDRIFT_RESOURCE_NAME}_HighRes"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

    popd
}

get_hcp_resampled_and_dedrifted_highres_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local to_study_dir=${5}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP resampled and dedrifted data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
	echo " Subject: ${subject}"
	echo " Session: ${session}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local copy_from=""
	copy_from+="${archive}"
	copy_from+="/${project}"
	copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	copy_from+="/${session}"
	copy_from+="/${DATABASE_RESOURCES_ROOT}"
	copy_from+="/${MSM_ALL_DEDRIFT_RESOURCE_NAME}_HighRes/*"

	local copy_to=""
	copy_to="${to_study_dir}/${subject}"

	local rsync_cmd=""
	rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
	echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

	popd
}

link_hcp_task_analysis_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local task=${5}    # e.g. tfMRI_EMOTION
	local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Task Analysis data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
	echo " Task: ${task}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
	link_from+="${archive}"
	link_from+="/${project}"
	link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	link_from+="/${session}"
	link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${task}/"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

	popd
}

get_hcp_task_analysis_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local task=${5}    # e.g. tfMRI_EMOTION
	local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP Task Analysis data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
	echo " Task: ${task}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local copy_from=""
	copy_from+="${archive}"
	copy_from+="/${project}"
	copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	copy_from+="/${session}"
	copy_from+="/${DATABASE_RESOURCES_ROOT}"
	copy_from+="/${task}"

	local copy_to=""
	copy_to="${to_study_dir}/${subject}"

	local rsync_cmd=""
	rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
	echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

	popd
}

link_hcp_post_msmall_task_analysis_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local task=${5}    # e.g. tfMRI_EMOTION
	local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Linking HCP Task Analysis data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
	echo " Task: ${task}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local link_from=""
	link_from+="${archive}"
	link_from+="/${project}"
	link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	link_from+="/${session}"
	link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/${task}_PostMsmAllTaskAnalysis/"

	local link_to=""
	link_to="${to_study_dir}/${subject}"

	local lndir_cmd=""
	lndir_cmd="${PATH_TO_LNDIR} ${link_from} ${link_to}"
	echo "lndir_cmd: ${lndir_cmd}"

	echo "----------" `date` "----------"
	echo ""
    ${lndir_cmd}

	popd
}

get_hcp_post_msmall_task_analysis_data()
{
	local archive=${1} # e.g. /data/hcpdb/archive or /HCP/hcpdb/archive
	local project=${2} # e.g. HCP_500
	local subject=${3} # e.g. 100307
	local session=${4} # e.g. 100307_3T
	local task=${5}    # e.g. tfMRI_EMOTION
	local to_study_dir=${6}

	local DATABASE_ARCHIVE_PROJECT_ROOT="arc001"
	local DATABASE_RESOURCES_ROOT="RESOURCES"

	echo ""
	echo "----------" `date` "----------"
    echo "Copying HCP Task Analysis data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
	echo " Task: ${task}"
    echo " To Study Directory: ${to_study_dir}"

	pushd ${to_study_dir}
	mkdir --parents ${subject}

	local copy_from=""
	copy_from+="${archive}"
	copy_from+="/${project}"
	copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
	copy_from+="/${session}"
	copy_from+="/${DATABASE_RESOURCES_ROOT}"
	copy_from+="/${task}_PostMsmAllTaskAnalysis/"

	local copy_to=""
	copy_to="${to_study_dir}/${subject}"

	local rsync_cmd=""
	rsync_cmd="rsync -auv ${copy_from} ${copy_to}"
	echo "rsync_cmd: ${rsync_cmd}"
	echo "----------" `date` "----------"
	echo ""
    ${rsync_cmd}

	popd
}

