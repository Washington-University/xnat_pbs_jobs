#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject="116423"
node="node157"
shadow_number=2

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Post MSM-All Task Analysis HCP job for subject: ${subject}"
echo " In project: ${project}"
echo " Using server: ${server}"
echo " Using compute node: ${node}"
echo "--------------------------------------------------------------------------------"


at now <<EOF

${HOME}/pipeline_tools/xnat_pbs_jobs/PostMsmAllTaskAnalysis/RunPostMsmAllTaskAnalysis.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> ${HOME}/pipeline_tools/xnat_pbs_jobs/PostMsmAllTaskAnalysis/OneSubjectRuns/${subject}.${node}.stdout \
	2>${HOME}/pipeline_tools/xnat_pbs_jobs/PostMsmAllTaskAnalysis/OneSubjectRuns/${subject}.${node}.stderr
EOF
