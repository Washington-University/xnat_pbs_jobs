#!/bin/bash

local_log()
{
	local msg="$*"
	local date_time
	date_time=$(date)
	local tool_name="freesurfer53_setup.sh"
	echo "${date_time} - ${tool_name} - ${msg}"
}

if [[ "${CLUSTER}" == "2.0" ]]; then
	local_log "Setting up FreeSurfer 5.3.0-HCP for CLUSTER: ${CLUSTER}"
	
	export FSL_DIR="${FSLDIR}"
	export FREESURFER_HOME=/act/freesurfer-5.3.0-HCP
	source ${FREESURFER_HOME}/SetUpFreeSurfer.sh

else
    local_log "Unable to use CLUSTER: '${CLUSTER}' value to determine location of FreeSurfer 5.3.0-HCP"
	local_log "EXITING WITH NON-ZERO EXIT STATUS (UNSUCCESSFUL EXECUTION)"
	exit 1
	
fi

unset -f local_log
