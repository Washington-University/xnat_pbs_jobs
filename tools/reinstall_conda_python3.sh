#!/bin/bash

# determine previous environment name
echo ""
echo "--------------------------------------------------"
echo "Determining previous Python 3 environment"
echo "--------------------------------------------------"
echo ""

if [ -e "${HOME}/.conda/envs/python3" ] ; then
	previous_environment_name=python3
elif [ -e "${HOME}/.conda/envs/ccfpython3" ]; then
	previous_environment_name=ccfpython3
else
	echo "Cannot determine previous Python 3 environment name"
	exit 1
fi
echo "previous_environment_name: ${previous_environment_name}"

# determine previous python version
echo ""
echo "--------------------------------------------------"
echo "Determining previous Python 3 version"
echo "--------------------------------------------------"
echo ""

pushd ${HOME}/.conda/envs/${previous_environment_name}/lib > /dev/null
previous_python_version=$(ls -d python*)
popd > /dev/null
echo "previous_python_version: ${previous_python_version}"

# make sure XNAT_PBS_JOBS is set
echo ""
echo "--------------------------------------------------"
echo "Making sure XNAT_PBS_JOBS is set"
echo "--------------------------------------------------"
echo ""

if [ -z "${XNAT_PBS_JOBS}" ]; then
	echo "XNAT_PBS_JOBS must be set"
	exit 1
fi
echo "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"

# set new environment name
echo ""
echo "--------------------------------------------------"
echo "Setting new environment name"
echo "--------------------------------------------------"
echo ""
new_environment_name=ccfpython3
echo "new_environment_name: ${new_environment_name}"

# remove previous environment
echo ""
echo "--------------------------------------------------"
echo "Removing previous environment: ${previous_environment_name}"
echo "--------------------------------------------------"
echo ""
source deactivate 2>/dev/null
conda remove --name ${previous_environment_name} --all

# create new environment
echo ""
echo "--------------------------------------------------"
echo "Creating new environment: ${new_environment_name}"
echo "--------------------------------------------------"
echo ""
conda create --name ${new_environment_name} python=3

# install modules in new environment
echo ""
echo "--------------------------------------------------"
echo "Installing modules in new environment"
echo "--------------------------------------------------"
echo ""
source activate ${new_environment_name}

echo "-- installing: requests"
conda install requests

echo "-- installing: pyqt"
conda install pyqt

source deactivate > /dev/null

# determine new python version
echo ""
echo "--------------------------------------------------"
echo "Determining new Python 3 version"
echo "--------------------------------------------------"
echo ""

pushd ${HOME}/.conda/envs/${new_environment_name}/lib > /dev/null
new_python_version=$(ls -d python*)
popd > /dev/null
echo "new_python_version: ${new_python_version}"

# add path file to site packages for new python environment
echo ""
echo "--------------------------------------------------"
echo "Adding pipeline_tools_lib.pth file to site-packages"
echo "--------------------------------------------------"

pushd ${HOME}/.conda/envs/${new_environment_name}/lib/${new_python_version}/site-packages > /dev/null
echo "${XNAT_PBS_JOBS}/lib" > pipeline_tools_lib.pth
echo "Begin contents of pipeline_tools_lib.pth"
cat pipeline_tools_lib.pth
echo "End contents of pipeline_tools_lib.pth"

popd > /dev/null

# report
echo ""
echo "The activate newly installed environment, use:"
echo "  \$ source activate ${new_environment_name}"
echo ""

echo "--------------------------------------------------"
echo "Done"
echo "--------------------------------------------------"



