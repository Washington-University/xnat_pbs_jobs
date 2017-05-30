#!/bin/bash 

if [ -z "${XNAT_PBS_JOBS}" ]; then
	echo "$(basename ${0}): ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

if ! type -t log_Msg | grep -q 'function' ; then
	source ${XNAT_PBS_JOBS}/shlib/log.shlib
fi

log_Msg "Setting up for running DeDriftAndResample pipeline"
log_Msg "The setup script must be SOURCED to correctly set up the environment"

if [ -z "${COMPUTE}" ] ; then
    log_Msg "COMPUTE value unset.  Setting to the default of CHPC"
    export COMPUTE="CHPC"
fi

if [ "${COMPUTE}" = "CHPC" ] ; then
    log_Msg "Setting up for processing on ${COMPUTE}"
    
	if [ "${CLUSTER}" = "2.0" ] ; then
		log_Msg "Setting up for CHPC cluster ${CLUSTER}"

		# FSL
		export FSLDIR=/export/HCP/fsl-5.0.9-custom-20170410
		source ${FSLDIR}/etc/fslconf/fsl.sh
		log_Msg "Set up to use FSL at ${FSLDIR}"
		
		# bet2 binary in FSL-5.0.9 needs newer version of libstdc++.so.6
		# found in /act/gcc-4.7.2/lib64
		if [ -z "${LD_LIBRARY_PATH}" ] ; then
		 	export LD_LIBRARY_PATH=/act/gcc-4.7.2/lib64
		else
		 	export LD_LIBRARY_PATH=/act/gcc-4.7.2/lib64:${LD_LIBRARY_PATH}
		fi
		log_Msg "Added /act/gcc-4.7.2/lib64 to LD_LIBRARY_PATH"
		log_Msg "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"

		# FreeSurfer
		export FSL_DIR="${FSLDIR}"
		export FREESURFER_HOME=/act/freesurfer-5.3.0-HCP
		source ${FREESURFER_HOME}/SetUpFreeSurfer.sh
		log_Msg "Set up to use FreeSurfer at ${FREESURFER_HOME}"

		# EPD Python
		export EPD_PYTHON_HOME=/export/HCP/epd-7.3.2
		export PATH=${EPD_PYTHON_HOME}/bin:${PATH}
		log_Msg "Set up to use EPD Python at ${EPD_PYTHON_HOME}"

		# Connectome Workbench
		export CARET7DIR=/export/HCP/workbench-v1.2.3/bin_rh_linux64
		log_Msg "Set up to use Workbench at ${CARET7DIR}"
		
		# HCP Pipeline Scripts
		export HCPPIPEDIR=${HOME}/pipeline_tools/Pipelines_dev
		export HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config
		export HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
		export HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates
		export HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
		export HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts
		export HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts
		export HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts
		export HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts
		export HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
		export HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts
		log_Msg "Set up to use HCP Pipelines at ${HCPPIPEDIR}"

		# ICAFIX
		export ICAFIX=${HOME}/pipeline_tools/fix1.064
		log_Msg "Set up to use ICAFIX at ${ICAFIX}"

		# MATLAB
		export MATLAB_COMPILER_RUNTIME=/export/matlab/MCR/R2016b/v91
		log_Msg "MATLAB_COMPILER_RUNTIME: ${MATLAB_COMPILER_RUNTIME}"

		# MSM
		export MSMBINDIR=${HOME}/pipeline_tools/MSM_HOCR_v2/Centos
		log_Msg "Set up to  use MSM binary at ${MSMBINDIR}"

		export MSMCONFIGDIR=${HCPPIPEDIR}/MSMConfig
		log_Msg "Set MSM Configuration files directory to ${MSMCONFIGDIR}"

	else # unhandled value for ${CLUSTER}
		log_Err_Abort "Processing set up for cluster ${CLUSTER} is currently not supported."

	fi

else # unhandled value for ${COMPUTE}
	log_Err_Abort "Processing set up for ${COMPUTE} is currently not supported."

fi
