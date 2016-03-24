#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

seed=5678
project="HCP_Staging"
shadow_number=1
subject="127226"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Structural Preprocessing job for subject: ${subject}"
echo " Using server: ${server}"
echo "--------------------------------------------------------------------------------"

i="1"
node_no="150"

while [ ${i} -lt 6 ]; do

	sleep 10s

	at now <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/StructuralPreprocessingHCP/RunStructuralPreprocessingHCP.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--seed=${seed} \
	--node=node${node_no} \
	--output-resource="Structural_preproc_test${i}"   

EOF

	i=$[$i+1]
	node_no=$[$node_no+1]
done
