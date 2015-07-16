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

server="db-shadow1.nrg.mir:8080"
project="HCP_500"
subject="100307"
session="100307_3T"
scan="rfMRI_REST1_LR"

current_seconds_since_epoch=`date +%s`
working_directory_name="/HCP/hcpdb/build_ssd/chpc/BUILD/${project}/${current_seconds_since_epoch}_${subject}"

# Make the working directory
echo "Making working directory: ${working_directory_name}"
mkdir -p ${working_directory_name}

# Create script file to run
script_file_to_run=${working_directory_name}/${subject}.RestingStateStats.${project}.${session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh

if [ -e "${script_file_to_run}" ]; then
	rm -f "${script_file_to_run}"
fi

# Get JSESSION ID
jsession=`curl -u ${userid}:${password} https://db.humanconnectome.org/data/JSESSION`
echo "jsession: ${jsession}"

touch ${script_file_to_run}
echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats.XNAT.sh \\" >> ${script_file_to_run}
echo "  --user=\"${token_username}\" \\" >> ${script_file_to_run}
echo "  --password=\"${token_password}\" \\" >> ${script_file_to_run}
echo "  --server=\"${server}\" \\" >> ${script_file_to_run}
echo "  --project=\"${project}\" \\" >> ${script_file_to_run}
echo "  --subject=\"${subject}\" \\" >> ${script_file_to_run}
echo "  --session=\"${session}\" \\" >> ${script_file_to_run}
echo "  --scan=\"${scan}\" \\" >> ${script_file_to_run}
echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_run}
echo "  --jsession=\"${jsession}\" " >> ${script_file_to_run}

chmod +x ${script_file_to_run}
${script_file_to_run}
