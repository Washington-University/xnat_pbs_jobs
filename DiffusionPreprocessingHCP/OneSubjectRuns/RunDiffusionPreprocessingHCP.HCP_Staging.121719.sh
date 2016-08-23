#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject="121719"
shadow_number=1
node="node167"
gpu_node="gpu005" # there is only one gpu node left on this cluster

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Diffusion Preprocessing job for subject: ${subject}"
echo " Using server: ${server}"
echo "--------------------------------------------------------------------------------"

at now + 1 day <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/RunDiffusionPreprocessingHCP.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--phase-encoding-dir=RLLR \
	--node=${node} \
	--gpu-node=${gpu_node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/OneSubjectRuns/${subject}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/OneSubjectRuns/${subject}.stderr
EOF