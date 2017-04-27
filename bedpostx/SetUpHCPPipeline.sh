
echo ""
echo "Setting up FSL"
export FSLDIR=/export/HCP/export/fsl-5.0.9-custom-bedpostx-20161206
source ${FSLDIR}/etc/fslconf/fsl.sh
echo "Set up to use FSL at ${FSLDIR}"

# LD_LIBRARY_PATH
# bet2 binary in FSL-5.0.9 needs newer version of libstdc++.so.6
# found in /act/gcc-4.7.2/lib64
echo ""
echo "Setting up LD_LIBRARY_PATH"
if [ -z "${LD_LIBRARY_PATH}" ] ; then
	export LD_LIBRARY_PATH=/act/gcc-4.7.2/lib64
else
	export LD_LIBRARY_PATH=/act/gcc-4.7.2/lib64:${LD_LIBRARY_PATH}
fi
echo "Added /act/gcc-4.7.2/lib64 to LD_LIBRARY_PATH"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"

