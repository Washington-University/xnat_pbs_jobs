#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject="130114"
shadow_number=2
node="node165"
gpu_node="gpu004" # there is only one gpu node left on this cluster

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Diffusion Preprocessing job for subject: ${subject}"
echo " Using server: ${server}"
echo "--------------------------------------------------------------------------------"

at now <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocesingHCP/RunDiffusionPreprocessingHCP.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--phase-encoding-dir=RLLR \
	--node=${node} \
	--gpu-node=${gpu_node}
EOF
