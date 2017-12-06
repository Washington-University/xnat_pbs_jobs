echo ""
echo "----- Begin: MultiRunIcaFixHCP7T.SetUp.sh -----"
echo ""

echo "Setting up FSL"
export FSLDIR=/export/HCP/fsl-5.0.10-custom-20171103

source ${FSLDIR}/etc/fslconf/fsl.sh
# if [[ $LD_LIBRARY_PATH == *"/export/HCP/lib"* ]]; then
# 	echo "No need to add /export/HCP/lib to LD_LIBRARY_PATH because it's already there."
# else
# 	export LD_LIBRARY_PATH=/export/HCP/lib:${LD_LIBRARY_PATH}
# 	echo "Added /export/HCP/lib to LD_LIBRARY_PATH so libblas.so.3 can be found by custom melodic"
# fi

#blas_location=/export/HCP/lib/Matthew_Webster_blas
#export LD_LIBRARY_PATH=${blas_location}:${LD_LIBRARY_PATH}
#echo "Added ${blas_location} to LD_LIBRARY_PATH so libblas.so.3 can be found by custom melodic"

echo "Set up to use FSL at ${FSLDIR}"
echo ""

echo "Setting up FreeSurfer"
export FSL_DIR="${FSLDIR}"
export FREESURFER_HOME=/act/freesurfer-5.3.0-HCP
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh
# modify LD_LIBRARY_PATH to allow access to libnetcdf.so.6 and libhdf5_hl.so.6
# the mris_make_surfaces binary in the v5.3.0-HCP version of FreeSurfer needs these
if [[ $LD_LIBRARY_PATH == *"/export/HCP/lib"* ]]; then
	echo "No need to add /export/HCP/lib to LD_LIBRARY_PATH because it's already there."
else
	export LD_LIBRARY_PATH=/export/HCP/lib:${LD_LIBRARY_PATH}
	echo "Added /export/HCP/lib to LD_LIBRARY_PATH so libnetcdf.so.6 and libhdf5_hl.so.6 can be found by custom mris_make_surfaces"
fi
echo "Set up to use FreeSurfer at ${FREESURFER_HOME}"
echo ""

echo "Setting up Python"
export EPD_PYTHON_HOME=/export/HCP/epd-7.3.2
export PATH=${EPD_PYTHON_HOME}/bin:${PATH}
echo "Set up to use EPD Python at ${EPD_PYTHON_HOME}"
echo ""

echo "Setting up Workbench (a.k.a. CARET7)"
export CARET7DIR=/export/HCP/workbench-v1.2.3/bin_rh_linux64
echo "Set up to use Workbench at ${CARET7DIR}"
echo ""

echo "Setting up HCP Pipelines"
export HCPPIPEDIR=/export/HCP/Pipelines-3.23.0
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
echo "Set up to use HCP Pipelines at ${HCPPIPEDIR}"
echo ""

echo "Setting up MSM"
export MSMBINDIR=/export/HCP/MSM_HOCR_v2/Centos
echo "Set up to use MSM binary at ${MSMBINDIR}"
echo ""

echo "Setting up MSM Configuration Directory"
export MSMCONFIGDIR=${HCPPIPEDIR}/MSMConfig
echo "Set up to use MSM configuration at ${MSMCONFIGDIR}"
echo ""

echo "Setting up ICAFIX Directory"
#export ICAFIX=${HOME}/pipeline_tools/fix1.065
export ICAFIX=/export/HCP/fix1.065
echo "Set up to use ICAFIX directory ${ICAFIX}"
echo ""

echo "Setting up FSL_FIXDIR Directory"
export FSL_FIXDIR=${ICAFIX}
echo "Set up to use FSL_FIXDIR directory ${FSL_FIXDIR}"
echo ""

echo "----- End: MultiRunIcaFixHCP7T.SetUp.sh -----"
echo ""
