#!/usr/bin/env python3

# import of built-in modules
import os
import sys

# import of third-party modules

# import of local modules
import ccf.archive as ccf_archive
import ccf.functional_preprocessing.one_subject_job_submitter as one_subject_job_submitter
import ccf.one_subject_completion_checker as one_subject_completion_checker
import ccf.subject as ccf_subject
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectCompletionChecker(one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()

    @property
    def PIPELINE_NAME(self):
        return one_subject_job_submitter.OneSubjectJobSubmitter.MY_PIPELINE_NAME()

    def my_resource(self, archive, subject_info):
        return archive.functional_preproc_dir_full_path(subject_info)
    
    def my_prerequisite_dir_full_paths(self, archive, subject_info):
        dirs = []
        dirs.append(archive.structural_preproc_dir_full_path(subject_info))
        return dirs
    
    def list_of_expected_files(self, archive, subject_info):

        l = []

        scan = subject_info.extra
        
        root_dir = os.sep.join([self.my_resource(archive, subject_info), subject_info.subject_id])

        l.append(os.sep.join([root_dir, 'MNINonLinear']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan]))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'brainmask_fs.2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'Movement_AbsoluteRMS_mean.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'Movement_AbsoluteRMS.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'Movement_Regressors_dt.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'Movement_Regressors.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'Movement_RelativeRMS_mean.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'Movement_RelativeRMS.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_Atlas.dtseries.nii']))

        # On or about 01 Apr 2018, the HCP Pipeline Scripts were modified to clean out this file
        # l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_AtlasSubcortical_s2.nii.gz']))

        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_dropouts.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_Jacobian.nii.gz']))

        # On or about 01 Apr 2018, the HCP Pipeline Scripts were modified to clean out this file
        # l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '.L.atlasroi.32k_fs_LR.func.gii']))

        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '.L.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_PhaseOne_gdc_dc.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_PhaseTwo_gdc_dc.nii.gz']))

        # On or about 01 Apr 2018, the HCP Pipeline Scripts were modified to clean out this file
        # l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '.R.atlasroi.32k_fs_LR.func.gii']))

        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '.R.native.func.gii']))

        # On or about 01 Apr 2018, the HCP Pipeline Scripts were modified to clean out these 2 files
        # l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_s2.atlasroi.L.32k_fs_LR.func.gii']))
        # l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_s2.atlasroi.R.32k_fs_LR.func.gii']))

        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_SBRef.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_sebased_bias.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_sebased_reference.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'cov.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'cov_norm_modulate.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'cov_norm_modulate_ribbon.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'cov_ribbon.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'cov_ribbon_norm.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'cov_ribbon_norm_s5.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'goodvoxels.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.cov.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.cov_all.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.cov_all.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.cov.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.goodvoxels.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.goodvoxels.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.mean.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.mean_all.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.mean_all.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'L.mean.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'mask.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'mean.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.cov.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.cov_all.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.cov_all.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.cov.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.goodvoxels.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.goodvoxels.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'ribbon_only.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.mean.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.mean_all.32k_fs_LR.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.mean_all.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'R.mean.native.func.gii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'SmoothNorm.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'RibbonVolumeToSurfaceMapping', 'std.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'xfms']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'xfms', scan + '2standard.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'xfms', 'standard2' + scan + '.nii.gz']))
        l.append(os.sep.join([root_dir, scan]))
        l.append(os.sep.join([root_dir, scan, 'BiasField.2.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'brainmask_fs.2.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'AllGreyMatter.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'CorticalGreyMatter.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'Dropouts_inv.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'Dropouts.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE_bias.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE_bias_raw.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE_bias_raw_s5.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE_bias_roi.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE_bias_roi_s5.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE_greyroi.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE_greyroi_s5.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE_grey_s5.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'GRE.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', scan + '_dropouts.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', scan + '_sebased_bias.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', scan + '_sebased_reference.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'sebased_bias_dil.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'sebased_reference_dil.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SE_BCdivGRE_brain.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SEdivGRE_brain_bias.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SEdivGRE_brain.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SEdivGRE_brain_thr.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SEdivGRE_brain_thr_roi.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SEdivGRE_brain_thr_roi_s5.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SEdivGRE_brain_thr_s5.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SEdivGRE.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SpinEchoMean_brain_BC.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SpinEchoMean.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'ComputeSpinEchoBiasField', 'SubcorticalGreyMatter.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'EPItoT1w.dat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'EPItoT1w.dat~']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'EPItoT1w.dat.log']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'EPItoT1w.dat.mincost']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'EPItoT1w.dat.param']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'EPItoT1w.dat.sum']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'acqparams.txt']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'BothPhases.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'BothPhases.topup_log']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Coefficents_fieldcoef.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Coefficents_movpar.txt']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'fullWarp_abs.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Jacobian_01.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Jacobian_02.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Jacobian.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'log.txt']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Magnitude_brain_mask.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Magnitude_brain.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Magnitude.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Magnitudes.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'Mask.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'MotionMatrix_01.mat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'MotionMatrix_02.mat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne_gdc_dc_jac.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne_gdc_dc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne_gdc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne_gdc_warp_jacobian.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne_gdc_warp.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne_mask_gdc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne_mask.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseOne_vol1.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo_gdc_dc_jac.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo_gdc_dc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo_gdc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo_gdc_warp_jacobian.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo_gdc_warp.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo_mask_gdc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo_mask.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'PhaseTwo_vol1.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'qa.txt']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'SBRef2PhaseOne_gdc.mat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'SBRef2PhaseOne_gdc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'SBRef2WarpField.mat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'SBRef_dc_jac.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'SBRef_dc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'SBRef.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'TopupField.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'trilinear.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'WarpField_01.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'WarpField_02.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'FieldMap', 'WarpField.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'fMRI2str.mat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'fMRI2str.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'fMRI2str_refinement.mat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Jacobian2T1w.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Jacobian.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'log.txt']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'PhaseOne_gdc_dc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'PhaseOne_gdc_dc_unbias.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'PhaseTwo_gdc_dc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'PhaseTwo_gdc_dc_unbias.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'qa.txt']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'SBRef_dc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Scout_gdc_undistorted2T1w_init_fast_wmedge.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Scout_gdc_undistorted2T1w_init_fast_wmseg.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Scout_gdc_undistorted2T1w_init_init.mat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Scout_gdc_undistorted2T1w_init.mat']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Scout_gdc_undistorted2T1w_init.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Scout_gdc_undistorted2T1w_init_warp.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Scout_gdc_undistorted2T1w.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'Scout_gdc_undistorted.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'T1w_acpc_dc_restore_brain.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased', 'WarpField.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'GradientDistortionUnwarp']))
        l.append(os.sep.join([root_dir, scan, 'GradientDistortionUnwarp', 'fullWarp_abs.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'GradientDistortionUnwarp', 'log.txt']))
        l.append(os.sep.join([root_dir, scan, 'GradientDistortionUnwarp', 'qa.txt']))
        l.append(os.sep.join([root_dir, scan, 'GradientDistortionUnwarp', scan + '_orig_vol1.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'GradientDistortionUnwarp', 'trilinear.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Jacobian_MNI.2.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Jacobian.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'MotionCorrection']))
        l.append(os.sep.join([root_dir, scan, 'MotionCorrection', scan + '_mc']))
        l.append(os.sep.join([root_dir, scan, 'MotionCorrection', scan + '_mc.ecclog']))
        l.append(os.sep.join([root_dir, scan, 'MotionCorrection', scan + '_mc_mask.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'MotionCorrection', scan + '_mc.par']))

        # Not checking all MotionMatrices/MAT* files because we don't know how many there will be.
        # On or about 01 Apr 2018, the HCP Pipeline Scripts were modified to clean out these MAT* 
        # files anyhow.
        # l.append(os.sep.join([root_dir, scan, 'MotionMatrices']))

        l.append(os.sep.join([root_dir, scan, 'Movement_AbsoluteRMS_mean.txt']))
        l.append(os.sep.join([root_dir, scan, 'Movement_AbsoluteRMS.txt']))
        l.append(os.sep.join([root_dir, scan, 'Movement_Regressors_dt.txt']))
        l.append(os.sep.join([root_dir, scan, 'Movement_Regressors.txt']))
        l.append(os.sep.join([root_dir, scan, 'Movement_RelativeRMS_mean.txt']))
        l.append(os.sep.join([root_dir, scan, 'Movement_RelativeRMS.txt']))
        l.append(os.sep.join([root_dir, scan, 'OneStepResampling']))
        l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'BiasField.2.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'brainmask_fs.2.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'gdc_dc_jacobian.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'gdc_dc_warp.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'log.txt']))

        # Not checking all postvols/* files because we don't know how many there will be.
        # On or about 01 Apr 2018, the HCP Pipeline Scripts were modified to clean out these files
        # anyhow.
        # l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'postvols']))

        # Not checking all prevols/* files because we don't know how many there will be.
        # ON or about 01 Apr 2018, the HCP Pipeline Scripts were modified to clean out these files
        # anyhow.
        # l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'prevols']))

        l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'qa.txt']))
        l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'Scout_gdc_MNI_warp.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'OneStepResampling', 'T1w_restore.2.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_gdc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_gdc_warp_jacobian.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_gdc_warp.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_mc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_nonlin_mask.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_nonlin.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_nonlin_norm.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_nonlin_norm.wdir']))
        l.append(os.sep.join([root_dir, scan, scan + '_nonlin_norm.wdir', 'log.txt']))
        l.append(os.sep.join([root_dir, scan, scan + '_nonlin_norm.wdir', 'qa.txt']))
        l.append(os.sep.join([root_dir, scan, scan + '_orig.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_SBRef_nonlin.nii.gz']))
        l.append(os.sep.join([root_dir, scan, scan + '_SBRef_nonlin_norm.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout2T1w.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout_gdc_mask.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout_gdc.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout_gdc_warp_jacobian.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout_gdc_warp.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout_GradientDistortionUnwarp']))
        l.append(os.sep.join([root_dir, scan, 'Scout_GradientDistortionUnwarp', 'fullWarp_abs.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout_GradientDistortionUnwarp', 'log.txt']))
        l.append(os.sep.join([root_dir, scan, 'Scout_GradientDistortionUnwarp', 'qa.txt']))
        l.append(os.sep.join([root_dir, scan, 'Scout_GradientDistortionUnwarp', 'Scout_orig_vol1.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout_GradientDistortionUnwarp', 'trilinear.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'Scout_orig.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'T1wMulEPI.nii.gz']))
        l.append(os.sep.join([root_dir, scan, 'T1w_restore.2.nii.gz']))
        l.append(os.sep.join([root_dir, 'T1w']))
        l.append(os.sep.join([root_dir, 'T1w', 'Results']))
        l.append(os.sep.join([root_dir, 'T1w', 'Results', scan]))
        l.append(os.sep.join([root_dir, 'T1w', 'Results', scan, scan+'_dropouts.nii.gz']))
        l.append(os.sep.join([root_dir, 'T1w', 'Results', scan, scan+'_sebased_bias.nii.gz']))
        l.append(os.sep.join([root_dir, 'T1w', 'Results', scan, scan+'_sebased_reference.nii.gz']))
        l.append(os.sep.join([root_dir, 'T1w', 'xfms']))
        l.append(os.sep.join([root_dir, 'T1w', 'xfms', scan + '2str.nii.gz']))
        
        return l

    
if __name__ == "__main__":

    parser = my_argparse.MyArgumentParser(
        description="Program to check for completion of Functional Preprocessing.")

    # mandatory arguments
    parser.add_argument('-p', '--project', dest='project', required=True, type=str)
    parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)
    parser.add_argument('-c', '--classifier', dest='classifier', required=True, type=str)
    parser.add_argument('-n', '--scan', dest='scan', required=True, type=str)

    # optional arguments
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true',
                        required=False, default=False)
    parser.add_argument('-o', '--output', dest='output', required=False, type=str)
    parser.add_argument('-a', '--check-all', dest='check_all', action='store_true',
                        required=False, default=False)

    # parse the command line arguments
    args = parser.parse_args()

    # check the specified subject and scan for functional preprocessing completion
    archive = ccf_archive.CcfArchive()
    subject_info = ccf_subject.SubjectInfo(
        project=args.project,
        subject_id=args.subject,
        classifier=args.classifier,
        extra=args.scan)
    completion_checker = OneSubjectCompletionChecker()

    if args.output:
        processing_output = open(args.output, 'w')
    else:
        processing_output = sys.stdout

    if completion_checker.is_processing_complete(
            archive=archive,
            subject_info=subject_info,
            verbose=args.verbose,
            output=processing_output,
            short_circuit=not args.check_all):
        print("Exiting with 0 code - Completion Check Successful")
        exit(0)
    else:
        print("Existing wih 1 code - Completion Check Unsuccessful")
        exit(1)


        
        
        
