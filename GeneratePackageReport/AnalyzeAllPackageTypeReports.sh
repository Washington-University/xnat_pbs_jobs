#!/bin/bash
set -e

source ${SCRIPTS_HOME}/epd-python_setup.sh

ANALYZE_APPLICATION=${HOME}/pipeline_tools/xnat_pbs_jobs/GeneratePackageReport/AnalyzePackageTypeReport.py

echo -e "package\t# subjects\t# exist\t# should not exist\tshould exist but do not\tshould have checksum but do not\tincorrect checksum\tunexplained small"
files=`ls -1 *.tsv`
for file in ${files} ; do
	${ANALYZE_APPLICATION} -i ${file} -c
done
