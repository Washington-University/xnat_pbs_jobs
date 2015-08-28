#!/bin/bash

g_project=HCP_500

BUILD_HOME="/HCP/hcpdb/build_ssd/chpc/BUILD"
echo "BUILD_HOME: ${BUILD_HOME}"

current_seconds_since_epoch=`date +%s`
working_directory_name="${BUILD_HOME}/${g_project}/MSMRemoveGroupDrift_${current_seconds_since_epoch}"

echo "Making working directory: ${working_directory_name}"
mkdir -p ${working_directory_name}

echo "Creating script file to actually do the work"
script_file_to_submit=${working_directory_name}/MSMRemoveGroupDrift.XNAT_PBS_job.sh
if [ -e "${script_file_to_submit}" ]; then
	rm -f "${script_file_to_submit}"
fi

touch ${script_file_to_submit}
echo "#PBS -l nodes=1:ppn=1,walltime=96:00:00,vmem=16000mb" >> ${script_file_to_submit}
echo "#PBS -q dque" >> ${script_file_to_submit}
echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
echo ""
echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MSMRemoveGroupDrift/MSMRemoveGroupDrift.XNAT.sh \\" >> ${script_file_to_submit}
echo "  --subject-list-file=/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MSMRemoveGroupDrift/sample_hcp500_subjects.txt \\" >> ${script_file_to_submit}
echo "  --project=HCP_500 \\" >> ${script_file_to_submit}
echo "  --working-dir=\"${working_directory_name}\" " >> ${script_file_to_submit}

submit_cmd="qsub ${script_file_to_submit}"
echo "submit_cmd: ${submit_cmd}"

processing_job_no=`${submit_cmd}`
echo "processing_job_no: ${processing_job_no}"

# still need to submit job to put results
