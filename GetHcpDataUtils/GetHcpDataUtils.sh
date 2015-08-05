
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

get_hcp_postfix_data()
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
    echo "Copying HCP PosFix data from archive"
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

get_hcp_resting_state_stats_data()
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
    copy_from+="/${scan}_RSS/${subject}/MNINonLinear/Results/${scan}"

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
