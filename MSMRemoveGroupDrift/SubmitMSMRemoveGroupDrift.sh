#!/bin/bash

# home directory for XNAT utilities
XNAT_UTILS_HOME=/home/HCPpipeline/pipeline_tools/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# set up to run Python
echo "Setting up to run Python"
source ${SCRIPTS_HOME}/epd-python_setup.sh

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

server="db-shadow1.nrg.mir:8080"
subject_info_file_name="/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MSMRemoveGroupDrift/group_drift_subjects.txt"

# Get token user id and password
echo "Getting token user id and password"
get_token_cmd="${XNAT_UTILS_HOME}/xnat_get_tokens --server=${server} --username=${userid}"
echo "get_token_cmd: ${get_token_cmd}"
get_token_cmd+=" --password=${password}"
new_tokens=`${get_token_cmd}`
token_username=${new_tokens% *}
token_password=${new_tokens#* }
echo "token_username: ${token_username}"
echo "token_password: ${token_password}"

BUILD_HOME="/HCP/hcpdb/build_ssd/chpc/BUILD"
echo "BUILD_HOME: ${BUILD_HOME}"

current_seconds_since_epoch=`date +%s`
working_directory_name="${BUILD_HOME}/CrossProject/MSMRemoveGroupDrift_${current_seconds_since_epoch}"

echo "Making working directory: ${working_directory_name}"
mkdir -p ${working_directory_name}

echo "Creating script file to actually do the work"
script_file_to_submit=${working_directory_name}/MSMRemoveGroupDrift.XNAT_PBS_job.sh
if [ -e "${script_file_to_submit}" ]; then
	rm -f "${script_file_to_submit}"
fi

touch ${script_file_to_submit}
echo "#PBS -l nodes=1:ppn=1,walltime=8:00:00,vmem=32000mb" >> ${script_file_to_submit}
echo "#PBS -q dque" >> ${script_file_to_submit}
echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
echo ""
echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MSMRemoveGroupDrift/MSMRemoveGroupDrift.XNAT.sh \\" >> ${script_file_to_submit}
echo "  --subject-info-file=${subject_info_file_name} \\" >> ${script_file_to_submit}
echo "  --working-dir=\"${working_directory_name}\" " >> ${script_file_to_submit}

submit_cmd="qsub ${script_file_to_submit}"
echo "submit_cmd: ${submit_cmd}"

processing_job_no=`${submit_cmd}`
echo "processing_job_no: ${processing_job_no}"

echo "Creating script file to do the putting of the data in the database"
put_script_file_to_submit=${working_directory_name}/MSMRemoveGroupDrift.PUT.XNAT_PBS_job.sh
if [ -e "${put_script_file_to_submit}" ]; then
	rm -f "${put_script_file_to_submit}"
fi

touch ${put_script_file_to_submit}
echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
echo ""
echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MSMRemoveGroupDrift/PutGroupDriftData.sh \\" >> ${put_script_file_to_submit}
echo "  --user=\"${token_username}\" \\" >> ${put_script_file_to_submit}
echo "  --password=\"${token_password}\" \\" >> ${put_script_file_to_submit}
echo "  --server=\"${server}\" \\" >> ${put_script_file_to_submit}
echo "  --project=HCP_Staging \\" >> ${put_script_file_to_submit}
echo "  --working-dir=\"${working_directory_name}\" " >> ${put_script_file_to_submit}

submit_cmd="qsub -W depend=afterok:${processing_job_no} ${put_script_file_to_submit}"
echo "submit_cmd: ${submit_cmd}"
${submit_cmd}

