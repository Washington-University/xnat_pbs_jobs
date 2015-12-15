#!/bin/bash

# home directory for XNAT utilities
XNAT_UTILS_HOME=/home/HCPpipeline/pipeline_tools/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# set up to run Python
#echo "Setting up to run Python"
#source ${SCRIPTS_HOME}/epd-python_setup.sh

subject_info_file_name="/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MakeAverageDataset/subjects.txt"

BUILD_HOME="/HCP/hcpdb/build_ssd/chpc/BUILD"
echo "BUILD_HOME: ${BUILD_HOME}"

current_seconds_since_epoch=`date +%s`
working_directory_name="${BUILD_HOME}/CrossProject/MakeGroupAverageDataset_${current_seconds_since_epoch}"

echo "Making working directory: ${working_directory_name}"
mkdir -p ${working_directory_name}

echo "Creating script file to actually do the work"
script_file_to_submit=${working_directory_name}/MakeAverageDataset.XNAT_PBS_job.sh
if [ -e "${script_file_to_submit}" ]; then
	rm -f "${script_file_to_submit}"
fi

touch ${script_file_to_submit}
echo "#PBS -l nodes=1:ppn=1,walltime=120:00:00,vmem=256000mb" >> ${script_file_to_submit}
#echo "#PBS -q dque" >> ${script_file_to_submit}
# max memory for dque nodes is 48GB
# dque_smp submits to nodes that have 64 cores and 256GB RAM
# qstat | grep SMP
# maxing out the RAM just to try to make sure I don't have to submit it again
echo "#PBS -q dque_smp" >> ${script_file_to_submit}
echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
echo ""
echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/MakeAverageDataset/MakeAverageDataset.XNAT.sh \\" >> ${script_file_to_submit}
echo "  --subject-info-file=${subject_info_file_name} \\" >> ${script_file_to_submit}
echo "  --working-dir=\"${working_directory_name}\" " >> ${script_file_to_submit}

submit_cmd="qsub ${script_file_to_submit}"
echo "submit_cmd: ${submit_cmd}"

processing_job_no=`${submit_cmd}`
echo "processing_job_no: ${processing_job_no}"
