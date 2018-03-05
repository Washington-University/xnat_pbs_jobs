#!/bin/bash

pushd ${XNAT_PBS_JOBS_PACKAGES_ROOT}/prerelease/zip/HCP_1200/126426

files=$(find . -name "*.rst")

for file in ${files} ; do
	echo "file: ${file}"
	cp --verbose ${file} ${XNAT_PBS_JOBS}/7T/PackageDocs
done

popd
