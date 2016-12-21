#!/usr/bin/env python3

# import of built-in modules
import logging
import os

# import of third party modules

# import of local modules
import hcp.one_subject_completion_checker
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# configure logging and create module logger
logger = logging.getLogger(file_utils.get_logger_name(__file__))

class OneSubjectCompletionChecker(hcp.one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, hcp3t_subject_info):
        return archive.does_diffusion_bedpostx_dir_exist(hcp3t_subject_info)

    def is_processing_complete(self, archive, hcp3t_subject_info, verbose=False):
        logger.debug("is_processing_complete")
        return self._do_output_files_exist(archive, hcp3t_subject_info, verbose)

    def _do_output_files_exist(self, archive, hcp3t_subject_info, verbose=False):
        logger.debug("_do_output_files_exist: archive: " + str(archive))
        logger.debug("_do_output_files_exist: hcp3t_subject_info: " + str(hcp3t_subject_info))
        logger.debug("_do_output_files_exist: verbose: " + str(verbose))

        # If the processed/output resource does not exist, then the processing has
        # certainly not been done.
        if not self.does_processed_resource_exist(archive, hcp3t_subject_info):
            return False

        # If we reach here, then the processed/output resource at least exists.
        # Next we need to check to see if the expected files exist.

        # Build a list of expected files
        file_name_list = []

        diffusion_bedpostx_dir = archive.diffusion_bedpostx_dir_fullpath(hcp3t_subject_info)
        diffusion_bedpostx_dir += os.sep + 'T1w' + os.sep + 'Diffusion.bedpostX'
        logger.debug("diffusion_bedpostx_dir: " + diffusion_bedpostx_dir)

        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'bvals')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'bvecs')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'commands.txt')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads1_dispersion.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads1.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads2_dispersion.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads2.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads2_thr0.05_modf2.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads2_thr0.05.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads3_dispersion.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads3.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads3_thr0.05_modf3.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'dyads3_thr0.05.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_dsamples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_d_stdsamples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_f1samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_f2samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_f3samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_fsumsamples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_ph1samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_ph2samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_ph3samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_Rsamples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_S0samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_tausamples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_th1samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_th2samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'mean_th3samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_f1samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_f2samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_f3samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_ph1samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_ph2samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_ph3samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_th1samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_th2samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'merged_th3samples.nii.gz')
        file_name_list.append(diffusion_bedpostx_dir + os.sep + 'nodif_brain_mask.nii.gz')

        logs_dir = diffusion_bedpostx_dir + os.sep + 'logs'

        file_name_list.append(logs_dir + os.sep + 'postproc_ID')

        logs_gpu_dir = logs_dir + os.sep + 'logs_gpu'
        
        # file_name_list.append(logs_gpu_dir)

        monitor_dir = logs_dir + os.sep + 'monitor'
        file_name_list.append(monitor_dir + os.sep + '0')
        file_name_list.append(monitor_dir + os.sep + '1')
        file_name_list.append(monitor_dir + os.sep + '2')
        file_name_list.append(monitor_dir + os.sep + '3')

        xfms_dir = diffusion_bedpostx_dir + os.sep + 'xfms'
        
        file_name_list.append(xfms_dir + os.sep + 'eye.mat')

        # Now check to see if all expected files actually exist
        return self.do_all_files_exist(file_name_list, verbose)
