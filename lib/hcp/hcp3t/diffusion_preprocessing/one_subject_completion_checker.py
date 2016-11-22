#!/usr/bin/env python3

"""
hcp/hcp3t/diffusion_preprocessing/one_subject_completion_checker.py:
Check HCP 3T diffusion preprocessing status for one HCP 3T subject.
"""

# import of built-in modules
import logging
import os
import sys


# import of third party modules
# None


# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.diffusion_preprocessing.output_size_checker
import hcp.hcp3t.subject as hcp3t_subject
import hcp.one_subject_completion_checker


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


# create and configure a module logger
log = logging.getLogger(__file__)
log.setLevel(logging.INFO)
sh = logging.StreamHandler()
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(sh)


class OneSubjectCompletionChecker(hcp.one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, hcp3t_subject_info):
        dir_list = archive.available_diffusion_preproc_dir_fullpaths(hcp3t_subject_info)
        return len(dir_list) > 0

    def is_processing_complete(self, archive, hcp3t_subject_info, verbose=False):
        return self._is_processing_complete(archive, hcp3t_subject_info, '1.25', verbose)

    def _is_processing_complete(self, archive, hcp3t_subject_info, voxel_size_str, verbose=False):

        # If the processed resource does not exist, then the processing has certainly
        # not been done.
        if not self.does_processed_resource_exist(archive, hcp3t_subject_info):
            return False

        # If we reach here, then the processed resource at least exists.
        # Next we need to check to see if the expected files exist.

        # Build a list of expected files
        file_name_list = []

        diffusion_dir = archive.diffusion_preproc_dir_fullpath(hcp3t_subject_info)
        diffusion_dir += os.sep
        diffusion_dir += 'Diffusion'

        diffusion_data_dir = diffusion_dir + os.sep + 'data'

        file_name_list.append(diffusion_data_dir + os.sep + 'avg_data.idxs')
        file_name_list.append(diffusion_data_dir + os.sep + 'bvals')
        file_name_list.append(diffusion_data_dir + os.sep + 'bvals_noRot')
        file_name_list.append(diffusion_data_dir + os.sep + 'bvecs')
        file_name_list.append(diffusion_data_dir + os.sep + 'bvecs_noRot')
        file_name_list.append(diffusion_data_dir + os.sep + 'data.nii.gz')
        file_name_list.append(diffusion_data_dir + os.sep + 'fullWarp_jacobian.nii.gz')
        file_name_list.append(diffusion_data_dir + os.sep + 'grad_dev.nii.gz')
        file_name_list.append(diffusion_data_dir + os.sep + 'log.txt')
        file_name_list.append(diffusion_data_dir + os.sep + 'nodif_brain_mask.nii.gz')
        file_name_list.append(diffusion_data_dir + os.sep + 'nodif_brain.nii.gz')
        file_name_list.append(diffusion_data_dir + os.sep + 'nodif.nii.gz')
        file_name_list.append(diffusion_data_dir + os.sep + 'qa.txt')

        warped_dir = diffusion_data_dir + os.sep + 'warped'

        file_name_list.append(warped_dir + os.sep + 'data_warped.nii.gz')
        file_name_list.append(warped_dir + os.sep + 'fullWarp_abs.nii.gz')
        file_name_list.append(warped_dir + os.sep + 'fullWarp.nii.gz')

        diffusion_eddy_dir = diffusion_dir + os.sep + 'eddy'

        file_name_list.append(diffusion_eddy_dir + os.sep + 'acqparams.txt')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_movement_rms')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_free_data.nii.gz')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_map')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_n_sqr_stdev_map')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_n_stdev_map')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_report')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_parameters')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_post_eddy_shell_alignment_parameters')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_restricted_movement_rms')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_results_with_outliers_retained.nii.gz')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.eddy_rotated_bvecs')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'eddy_unwarped_images.nii.gz')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'index.txt')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Neg.bval')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Neg.bvec')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Neg_rotated.bvec')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Neg_SeriesVolNum.txt')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'nodif_brain_mask.nii.gz')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Pos.bval')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Pos.bvec')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Pos_Neg.bvals')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Pos_Neg.bvecs')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Pos_Neg.nii.gz')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Pos_rotated.bvec')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'Pos_SeriesVolNum.txt')
        file_name_list.append(diffusion_eddy_dir + os.sep + 'series_index.txt')

        diffusion_rawdata_dir = diffusion_dir + os.sep + 'rawdata'

        file_name_list.append(diffusion_rawdata_dir + os.sep + 'LR_SeriesCorrespVolNum.txt')
        file_name_list.append(diffusion_rawdata_dir + os.sep + 'RL_SeriesCorrespVolNum.txt')

        diffusion_reg_dir = diffusion_dir + os.sep + 'reg'

        file_name_list.append(diffusion_reg_dir + os.sep + 'diff2str_fs.mat')
        file_name_list.append(diffusion_reg_dir + os.sep + 'diff2str.mat')
        file_name_list.append(diffusion_reg_dir + os.sep + 'EPItoT1w.dat')
        file_name_list.append(diffusion_reg_dir + os.sep + 'EPItoT1w.dat~')
        file_name_list.append(diffusion_reg_dir + os.sep + 'EPItoT1w.dat.log')
        file_name_list.append(diffusion_reg_dir + os.sep + 'EPItoT1w.dat.mincost')
        file_name_list.append(diffusion_reg_dir + os.sep + 'EPItoT1w.dat.param')
        file_name_list.append(diffusion_reg_dir + os.sep + 'EPItoT1w.dat.sum')
        file_name_list.append(diffusion_reg_dir + os.sep + 'grad_unwarp_diff2str.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w_initII_fast_wmedge.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w_initII_fast_wmseg.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w_initII_init.mat')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w_initII.mat')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w_initII.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w_init.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w_restore_initII.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'nodif2T1w_restore.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'Scout2T1w.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'str2diff.mat')
        file_name_list.append(diffusion_reg_dir + os.sep + 'T1w_acpc_dc_restore_brain.nii.gz')
        file_name_list.append(diffusion_reg_dir + os.sep + 'T1wMulEPI_nodif.nii.gz')

        diffusion_topup_dir = diffusion_dir + os.sep + 'topup'

        file_name_list.append(diffusion_topup_dir + os.sep + 'acqparams.txt')
        file_name_list.append(diffusion_topup_dir + os.sep + 'extractedb0.txt')
        file_name_list.append(diffusion_topup_dir + os.sep + 'hifib0.nii.gz')
        file_name_list.append(diffusion_topup_dir + os.sep + 'nodif_brain_mask.nii.gz')
        file_name_list.append(diffusion_topup_dir + os.sep + 'nodif_brain.nii.gz')
        file_name_list.append(diffusion_topup_dir + os.sep + 'Pos_Neg_b0.nii.gz')
        file_name_list.append(diffusion_topup_dir + os.sep + 'Pos_Neg_b0.topup_log')
        file_name_list.append(diffusion_topup_dir + os.sep + 'topup_Pos_Neg_b0_fieldcoef.nii.gz')
        file_name_list.append(diffusion_topup_dir + os.sep + 'topup_Pos_Neg_b0_movpar.txt')

        T1w_dir = archive.diffusion_preproc_dir_fullpath(hcp3t_subject_info) + os.sep + 'T1w'

        file_name_list.append(T1w_dir + os.sep + 'aparc.a2009s+aseg_1mm.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'aparc.a2009s+aseg.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'aparc+aseg_1mm.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'aparc+aseg.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'BiasField_acpc_dc.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'brainmask_fs_1mm.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'brainmask_fs.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'ribbon.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w1_gdc.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w2_gdc.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_brain_mask.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_brain.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_dc_brain.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_dc.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_dc_restore_' + voxel_size_str + '.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_dc_restore_1mm.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_dc_restore_brain_1mm.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_dc_restore_brain.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc_dc_restore.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w_acpc.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1wDividedByT2w.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1wDividedByT2w_ribbon.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T1w.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T2w_acpc_dc.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T2w_acpc_dc_restore_brain.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'T2w_acpc_dc_restore.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'wmparc_1mm.nii.gz')
        file_name_list.append(T1w_dir + os.sep + 'wmparc.nii.gz')

        T1w_Diffusion_dir = T1w_dir + os.sep + 'Diffusion'

        file_name_list.append(T1w_Diffusion_dir + os.sep + 'bvals')
        file_name_list.append(T1w_Diffusion_dir + os.sep + 'bvecs')
        file_name_list.append(T1w_Diffusion_dir + os.sep + 'data.nii.gz')
        file_name_list.append(T1w_Diffusion_dir + os.sep + 'grad_dev.nii.gz')
        file_name_list.append(T1w_Diffusion_dir + os.sep + 'nodif_brain_mask.nii.gz')
        file_name_list.append(T1w_Diffusion_dir + os.sep + 'nodif_brain_mask_old.nii.gz')

        T1w_xfms_dir = T1w_dir + os.sep + 'xfms'

        file_name_list.append(T1w_xfms_dir + os.sep + 'acpc.mat')
        file_name_list.append(T1w_xfms_dir + os.sep + 'OrigT1w2standard.nii.gz')
        file_name_list.append(T1w_xfms_dir + os.sep + 'OrigT1w2T1w.nii.gz')
        file_name_list.append(T1w_xfms_dir + os.sep + 'OrigT2w2standard.nii.gz')
        file_name_list.append(T1w_xfms_dir + os.sep + 'OrigT2w2T1w.nii.gz')
        file_name_list.append(T1w_xfms_dir + os.sep + 'T1w1_gdc_warp.nii.gz')
        file_name_list.append(T1w_xfms_dir + os.sep + 'T1w2_gdc_warp.nii.gz')
        file_name_list.append(T1w_xfms_dir + os.sep + 'T1w_dc.nii.gz')
        file_name_list.append(T1w_xfms_dir + os.sep + 'T2w_reg_dc.nii.gz')

        eddy_logs_dir = T1w_dir + os.sep + 'Diffusion' + os.sep + 'eddylogs'

        file_name_list.append(eddy_logs_dir + os.sep + 'eddy_unwarped_images.eddy_movement_rms')
        file_name_list.append(eddy_logs_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_map')
        file_name_list.append(eddy_logs_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_n_sqr_stdev_map')
        file_name_list.append(eddy_logs_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_n_stdev_map')
        file_name_list.append(eddy_logs_dir + os.sep + 'eddy_unwarped_images.eddy_outlier_report')
        file_name_list.append(eddy_logs_dir + os.sep + 'eddy_unwarped_images.eddy_parameters')
        file_name_list.append(eddy_logs_dir + os.sep + 'eddy_unwarped_images.eddy_post_eddy_shell_alignment_parameters')
        file_name_list.append(eddy_logs_dir + os.sep + 'eddy_unwarped_images.eddy_restricted_movement_rms')

        # Now check to see if expected files actually exist
        return self.do_all_files_exist(file_name_list, verbose)


def _simple_interactive_demo():

    archive = hcp3t_archive.Hcp3T_Archive()
    completion_checker = OneSubjectCompletionChecker()

    # 100307
    subject_id_list = [
        100307,
        100408,
        101006,
        101107,
        101309,
        101410,
        101915,
        102008,
        102311,
        102816,
        103111,
        103414,
        103515,
        103818,
        104012,
        104820,
        105014,
        105115,
        105216,
        105923,
        106016,
        106319,
        106521,
        107321,
        107422,
        108121,
        108323,
        108525,
        108828,
        109123,
        109325,
        110411,
        111312,
        901442,
        904044,
        907656,
        910241,
        912447,
        917255,
        922854,
        930449,
        932554,
        937160,
        951457,
        957974,
        958976,
        959574,
        965367,
        965771,
        978578,
        979984,
        983773,
        984472,
        987983,
        991267,
        992774,
        994273
    ]

    for subject_id in subject_id_list:
        hcp3t_subject_info = hcp3t_subject.Hcp3TSubjectInfo(
            'HCP_500', str(subject_id))

        log.info("Checking subject: " + hcp3t_subject_info.subject_id)

        resource_exists = completion_checker.does_processed_resource_exist(archive, hcp3t_subject_info)
        log.info("resource_exists: " + str(resource_exists))

        processing_complete = completion_checker.is_processing_complete(archive, hcp3t_subject_info, False)
        log.info("processing_complete: " + str(processing_complete))

        try:
            (success, expected_size, msg) = output_size_checker.check_diffusion_preproc_size(archive, hcp3t_subject_info)
            log.info("expected_size: " + str(expected_size) + "\tsuccess: " + str(success) + "\t" + msg)
        except output_size_checker.NoDiffusionPreprocResource as e:
            log.info("expected_size: " + "N/A" + "tsuccess: " + "N/A" + "\t" + "No Diff Preproc Resource")
        except FileNotFoundError as e:
            log.info("expected_size: " + "N/A" + "tsuccess: " + "N/A" + "\t" + "A necessary output file was not found")


if __name__ == '__main__':
    _simple_interactive_demo()
