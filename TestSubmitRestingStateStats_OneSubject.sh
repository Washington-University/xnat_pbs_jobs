#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

XNAT_UTILS_HOME=/home/HCPpipeline/pipeline_tools/xnat_utilities

# Get token user id and password
source ${SCRIPTS_HOME}/epd-python_setup.sh

echo "Getting token user id and password"
new_tokens=`${XNAT_UTILS_HOME}/xnat_get_tokens --username=${userid} --password=${password}`
token_username=${new_tokens% *}
token_password=${new_tokens#* }

server="db.humanconnectome.org"
project="HCP_500"
subject="100307"
session="100307_3T"

scans="rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL"

for scan in ${scans} ; do

	current_seconds_since_epoch=`date +%s`
	working_directory_name="/HCP/hcpdb/build_ssd/chpc/BUILD/${project}/${current_seconds_since_epoch}_${subject}"

	# Make the working directory
	echo "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Create script file to submit
	script_file_to_submit=${working_directory_name}/${subject}.RestingStateStats.${project}.${session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh

	if [ -e "${script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	# Get JSESSION ID
	jsession=`curl -u ${userid}:${password} https://${server}/data/JSESSION`
	echo "jsession: ${jsession}"

	touch ${script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=10:00:00,vmem=16000mb" >> ${script_file_to_submit}
	echo "#PBS -q dque" >> ${script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
	#echo "#PBS -o /HCP/hcpdb/build_hds/chpc/logs_mpp/pbs" >> ${script_file_to_submit}
	#echo "#PBS -e /HCP/hcpdb/build_hds/chpc/logs_mpp/pbs" >> ${script_file_to_submit}
	echo ""
	echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats.XNAT_PBS_job.sh \\" >> ${script_file_to_submit}
	echo "  --user=\"${token_username}\" \\" >> ${script_file_to_submit}
	echo "  --password=\"${token_password}\" \\" >> ${script_file_to_submit}
	echo "  --host=\"${server}\" \\" >> ${script_file_to_submit}
	echo "  --project=\"${project}\" \\" >> ${script_file_to_submit}
	echo "  --subject=\"${subject}\" \\" >> ${script_file_to_submit}
	echo "  --session=\"${session}\" \\" >> ${script_file_to_submit}
	echo "  --scan=\"${scan}\" \\" >> ${script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
	echo "  --jsession=\"${jsession}\" " >> ${script_file_to_submit}

	qsub ${script_file_to_submit}

done