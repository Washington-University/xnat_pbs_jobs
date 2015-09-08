PATH_TO_LNDIR="/export/lndir-1.0.1/bin/lndir"

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
	mkdir -p ${subject}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/Structural_preproc/"

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
    mkdir -p ${subject}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/Structural_preproc/*"

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
    echo "Linking HCP Functionally Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir -p ${subject}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}_preproc/"

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
    echo "Copying HCP Functionally Preprocessed data from archive"
    echo " Archive: ${archive}"
    echo " Project: ${project}"
    echo " Subject: ${subject}"
    echo " Session: ${session}"
    echo " Scan: ${scan}"
    echo " To Study Directory: ${to_study_dir}"

    pushd ${to_study_dir}
    mkdir -p ${subject}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${scan}_preproc/*"

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
    mkdir -p ${subject}/MNINonLinear/Results

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}_FIX/"

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
    mkdir -p ${subject}/MNINonLinear/Results

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${scan}_FIX/*"

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
    mkdir -p ${subject}/MNINonLinear/Results/${scan}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}_PostFix/${subject}/MNINonLinear/Results/${scan}"

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
    mkdir -p ${subject}/MNINonLinear/Results/${scan}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${scan}_PostFix/${subject}/MNINonLinear/Results/${scan}"

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
    mkdir -p ${subject}/MNINonLinear/Results/${scan}

    local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
    link_from+="/${scan}_RSS/MNINonLinear/Results/${scan}"

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
    mkdir -p ${subject}/MNINonLinear/Results/${scan}

    local copy_from=""
    copy_from+="${archive}"
    copy_from+="/${project}"
    copy_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    copy_from+="/${session}"
    copy_from+="/${DATABASE_RESOURCES_ROOT}"
    copy_from+="/${scan}_RSS/MNINonLinear/Results/${scan}"

    local copy_to=""
    copy_to="${to_study_dir}/${subject}/MNINonLinear/Results/${scan}"

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

	local DATABASE_ARCHIVE_PROJECT_ROOT="arch001"
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
	mkdir -p ${subject}/MNINonLinear

	local link_from=""
    link_from+="${archive}"
    link_from+="/${project}"
    link_from+="/${DATABASE_ARCHIVE_PROJECT_ROOT}"
    link_from+="/${session}"
    link_from+="/${DATABASE_RESOURCES_ROOT}"
	link_from+="/rfMRI_REST_MSMAllReg/MNINonLinear"

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

