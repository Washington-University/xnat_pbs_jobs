#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

#subject="329844"
printf "Subject: "
read subject

#node="node163"
printf "Node: " 
read node

printf "Delay submission for (minutes) [0]: "
read delay

if [ -z "${delay}" ]; then
	delay=0
fi

#shadow_number=2
min_shadow_number=1
max_shadow_number=8
#shadow_number=`shuf -i ${min_shadow_number}-${max_shadow_number} -n 1`
shadow_number=2

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Resting State Stats job for subject: ${subject}"
echo " In project: ${project}"
echo " Using server: ${server}"
echo " Using compute node: ${node}"
echo " Delaying submission for: ${delay} minutes"
echo "--------------------------------------------------------------------------------"

at now + ${delay} minutes <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats/RunRestingStateStats.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats/OneSubjectRuns/${subject}.${node}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats/OneSubjectRuns/${subject}.${node}.stderr
EOF
