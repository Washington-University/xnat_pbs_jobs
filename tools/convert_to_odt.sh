#!/bin/bash

if [ -z "${XNAT_PBS_JOBS}" ]; then
	echo "$(basename ${0}): ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

source ${XNAT_PBS_JOBS}/shlib/utils.shlib

#
# See http://docutils.sourceforge.net/docs/user/odt.html#defining-and-using-a-custom-stylesheet
#

docgen_dir=${XNAT_PBS_JOBS}/docgen
output_dir=generated

mkdir -p ${output_dir}
content_files=$(ls *.rst)

set_g_python_environment
source activate ${g_python_environment}

for content_file in ${content_files} ; do

	output_file=${output_dir}/${content_file%.rst}.odt

	echo "Converting ${content_file} to ${output_file}"
	
	rst2odt.py --stylesheet=${docgen_dir}/PackageContent.styles.odt \
		   ${content_file} \
		   ${output_file}

done

source deactivate
