#!/usr/bin/env python3

# import of built-in modules
import os

# import of third-party modules

# import of local modules
import ccf.one_subject_completion_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectCompletionChecker(ccf.one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, subject_info):
        fullpath = archive.dedrift_and_resample_dir_full_path(subject_info)
        return os.path.isdir(fullpath)

    def is_processing_complete(self, archive, subject_info, verbose=False):
        # If the processed resource does not exist, then the process is certainly not complete.
        if not self.does_processed_resource_exist(archive, subject_info):
            return False

        # Build a list of expected files
        file_name_list = []

        # 100307/MNINonLinear
        check_dir = os.sep.join([archive.dedrift_and_resample_dir_full_path(subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear'])

        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.corrThickness_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.curvature_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.inflated_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.midthickness_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.pial_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.very_inflated_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.white_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MSMAll.164k_fs_LR.wb.spec')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap_BC_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.inflated_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.midthickness_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.pial_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.very_inflated_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.white_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap_BC_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SphericalDistortion_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.sulc_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.thickness_MSMAll.164k_fs_LR.dscalar.nii')

        # 100307/MNINonLinear/fsaverage_LR32k
        check_dir = os.sep.join([archive.dedrift_and_resample_dir_full_path(subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'fsaverage_LR32k'])

        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.BiasField_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.corrThickness_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.curvature_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.inflated_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.midthickness_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.pial_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.very_inflated_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.white_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MSMAll.32k_fs_LR.wb.spec')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap_BC_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.inflated_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.midthickness_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.pial_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.very_inflated_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.white_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap_BC_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SphericalDistortion_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.sulc_MSMAll.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.thickness_MSMAll.32k_fs_LR.dscalar.nii')

        # 100307/MNINonLinear/Native
        check_dir = os.sep.join([archive.dedrift_and_resample_dir_full_path(subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'Native'])

        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_MSMAll.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.BiasField_MSMAll.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_MSMAll.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.ArealDistortion_MSMAll.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.EdgeDistortion_MSMAll.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.MSMAll.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap_BC_MSMAll.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.native.wb.spec')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.ArealDistortion_MSMAll.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.EdgeDistortion_MSMAll.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.MSMAll.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap_BC_MSMAll.native.dscalar.nii')

        # For all the preprocessed functional scans that exist for this subject
        for func_name in archive.available_functional_preproc_names(subject_info):

            # 100307/MNINonLinear/Results/tfMRI_EMOTION_LR
            check_dir = os.sep.join([archive.dedrift_and_resample_dir_full_path(subject_info),
                                     str(subject_info.subject_id),
                                     'MNINonLinear',
                                     'Results',
                                     func_name])
            file_name_list.append(check_dir + os.sep + func_name + '_Atlas_MSMAll.dtseries.nii')
            file_name_list.append(check_dir + os.sep + func_name + '_MSMAll.L.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(check_dir + os.sep + func_name + '_MSMAll.R.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(check_dir + os.sep + func_name + '_s2_MSMAll.L.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(check_dir + os.sep + func_name + '_s2_MSMAll.R.atlasroi.32k_fs_LR.func.gii')

            if archive.is_resting_state_scan_name(func_name):
                file_name_list.append(check_dir + os.sep + func_name + '_Atlas_MSMAll_hp2000_clean.dtseries.nii')
                check_dir += os.sep + func_name + '_hp2000.ica'
                file_name_list.append(check_dir + os.sep + 'Atlas.dtseries.nii')
                file_name_list.append(check_dir + os.sep + 'Atlas_hp_preclean.dtseries.nii')
                file_name_list.append(check_dir + os.sep + 'mc' + os.sep + 'prefiltered_func_data_mcf.par')

        # 100307/T1w/fsaverage_LR32k
        check_dir = os.sep.join([archive.dedrift_and_resample_dir_full_path(subject_info),
                                 str(subject_info.subject_id),
                                 'T1w',
                                 'fsaverage_LR32k'
                                 ])

        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.inflated_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.midthickness_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.midthickness_MSMAll_va.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.pial_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.very_inflated_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.white_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.midthickness_MSMAll_va.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.midthickness_MSMAll_va_norm.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MSMAll.32k_fs_LR.wb.spec')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.inflated_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.midthickness_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.midthickness_MSMAll_va.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.pial_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.very_inflated_MSMAll.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.white_MSMAll.32k_fs_LR.surf.gii')

        # 100307/T1w/Native
        check_dir = os.sep.join([archive.dedrift_and_resample_dir_full_path(subject_info),
                                 str(subject_info.subject_id),
                                 'T1w',
                                 'Native'
                                 ])

        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.native.wb.spec')

        return self.do_all_files_exist(file_name_list, verbose)
