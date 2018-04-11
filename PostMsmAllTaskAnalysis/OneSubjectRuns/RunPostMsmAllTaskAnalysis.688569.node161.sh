#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

if [ -z "${XNAT_PBS_JOBS}" ]; then
	inform "Environment variable XNAT_PBS_JOBS must be set!"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_MAX_SHADOW}" ]; then
	inform "Environment variable XNAT_PBS_JOBS_MAX_SHADOW must be set!"
	exit 1
fi

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject="688569"
node="node161"
shadow_number=${XNAT_PBS_JOBS_MAX_SHADOW}

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

${XNAT_PBS_JOBS}/PostMsmAllTaskAnalysis/RunPostMsmAllTaskAnalysis.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> ${XNAT_PBS_JOBS}/PostMsmAllTaskAnalysis/OneSubjectRuns/${subject}.${node}.stdout \
	2>${XNAT_PBS_JOBS}/PostMsmAllTaskAnalysis/OneSubjectRuns/${subject}.${node}.stderr
EOF
