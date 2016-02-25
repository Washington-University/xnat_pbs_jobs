#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

seed=4567
project="HCP_Staging"
shadow_number=2
subject="130114"
server="db-shadow${shadow_number}.nrg.mir:8080"
node="node165"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Structural Preprocessing job for subject: ${subject}"
echo " Using server: ${server}"
echo "--------------------------------------------------------------------------------"

at now <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/StructuralPreprocessingHCP/RunStructuralPreprocessingHCP.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--seed=${seed} \
	--node=${node}

EOF

