#!/usr/bin/env python3

"""
DeDriftAndResampleHCP7T_HighRes_OneSubjectCompletionChecker.py: Check DeDriftAndResampleHCP7T_HighRes processing
status for one HCP 7T Subject.
"""

# import of built-in modules
import os

# import of third party modules
# None

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Outputs a message that is prefixed by the module file name."""
    print(os.path.basename(__file__) + ": " + msg)


class DeDriftAndResampleHCP7T_HighRes_OneSubjectCompletionChecker:

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, hcp7t_subject_info):
        dir_list = archive.available_DeDriftAndResample_HighRes_processed_dirs(hcp7t_subject_info)
        return len(dir_list) > 0

    def is_processing_complete(self, archive, hcp7t_subject_info, scan_name, verbose=False):

        # If the output resource does not exist, then the DeDriftAndResampleHCP7T_HighRest processing
        # certainly has not been done.
        if not self.does_processed_resource_exist(archive, hcp7t_subject_info):
            return False

        # If we reach here, then the processed resource at least exists.
        # Next we need to check to see if the expected files exist for the specified scan.

        # Build list of expected files
        file_name_list = []

        results_dir = archive.DeDriftAndResample_HighRes_processed_dir_name(hcp7t_subject_info)

        mni_non_linear_dir = archive.DeDriftAndResample_HighRes_processed_dir_name(hcp7t_subject_info) + os.sep + 'MNINonLinear'

        prefix = mni_non_linear_dir + os.sep + hcp7t_subject_info.subject_id
        file_name_list.append(prefix + '.1.6mm_MSMAll.164k_fs_LR.wb.spec')
        file_name_list.append(prefix + '.ArealDistortion_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.corrThickness_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.curvature_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.EdgeDistortion_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.L.inflated_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.midthickness_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.pial_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.very_inflated_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.white_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.MyelinMap_BC_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.R.inflated_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.midthickness_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.pial_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.very_inflated_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.white_1.6mm_MSMAll.164k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.SmoothedMyelinMap_BC_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.SphericalDistortion_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.sulc_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.thickness_1.6mm_MSMAll.164k_fs_LR.dscalar.nii')

        fsave_dir = mni_non_linear_dir + os.sep + 'fsaverage_LR59k'

        prefix = fsave_dir + os.sep + hcp7t_subject_info.subject_id
        file_name_list.append(prefix + '.1.6mm_MSMAll.59k_fs_LR.wb.spec')
        file_name_list.append(prefix + '.ArealDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.atlas_MyelinMap_BC.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.BiasField_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.corrThickness_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.curvature_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.EdgeDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.L.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.white_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.MyelinMap_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.MyelinMap_BC_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.R.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.white_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.SmoothedMyelinMap_BC_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.SphericalDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.sulc_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.thickness_1.6mm_MSMAll.59k_fs_LR.dscalar.nii')

        native_dir = os.sep.join([mni_non_linear_dir, 'Native'])

        prefix = native_dir + os.sep + hcp7t_subject_info.subject_id
        file_name_list.append(prefix + '.ArealDistortion_1.6mm_MSMAll.native.dscalar.nii')
        file_name_list.append(prefix + '.BiasField_1.6mm_MSMAll.native.dscalar.nii')
        file_name_list.append(prefix + '.EdgeDistortion_1.6mm_MSMAll.native.dscalar.nii')
        file_name_list.append(prefix + '.L.ArealDistortion_1.6mm_MSMAll.native.shape.gii')
        file_name_list.append(prefix + '.L.EdgeDistortion_1.6mm_MSMAll.native.shape.gii')
        file_name_list.append(prefix + '.L.sphere.1.6mm_MSMAll.native.surf.gii')
        file_name_list.append(prefix + '.MyelinMap_BC_1.6mm_MSMAll.native.dscalar.nii')
        file_name_list.append(prefix + '.native.wb.spec')
        file_name_list.append(prefix + '.R.ArealDistortion_1.6mm_MSMAll.native.shape.gii')
        file_name_list.append(prefix + '.R.EdgeDistortion_1.6mm_MSMAll.native.shape.gii')
        file_name_list.append(prefix + '.R.sphere.1.6mm_MSMAll.native.surf.gii')
        file_name_list.append(prefix + '.SmoothedMyelinMap_BC_1.6mm_MSMAll.native.dscalar.nii')

        results_scan_dir = os.sep.join([results_dir,
                                        'MNINonLinear',
                                        'Results',
                                        archive.functional_scan_long_name(scan_name)])

        prefix = results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name)
        file_name_list.append(prefix + '_Atlas_1.6mm_MSMAll.dtseries.nii')

        if archive.is_resting_state_scan_name(scan_name) or archive.is_movie_scan_name(scan_name) or archive.is_retinotopy_scan_name(scan_name):
            file_name_list.append(prefix + '_1.6mm_MSMAll.L.atlasroi.59k_fs_LR.func.gii')
            file_name_list.append(prefix + '_1.6mm_MSMAll.R.atlasroi.59k_fs_LR.func.gii')
            file_name_list.append(prefix + '_s1.60_1.6mm_MSMAll.L.atlasroi.59k_fs_LR.func.gii')
            file_name_list.append(prefix + '_s1.60_1.6mm_MSMAll.R.atlasroi.59k_fs_LR.func.gii')

        file_name_list.append(prefix + '_Atlas_1.6mm_MSMAll_hp2000_clean.dtseries.nii')
            
        if archive.is_resting_state_scan_name(scan_name) or archive.is_movie_scan_name(scan_name):

            ica_dir = results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) + '_hp2000.ica'

            file_name_list.append(ica_dir + os.sep + 'Atlas_hp_preclean.dtseries.nii')
            file_name_list.append(ica_dir + os.sep + 'Atlas.nii.gz')

            mc_dir = ica_dir + os.sep + 'mc'

            file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf_conf_hp.nii.gz')
            file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf_conf.nii.gz')
            file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf.par')


        if (not archive.is_resting_state_scan_name(scan_name)) and (not archive.is_movie_scan_name(scan_name)):
            file_name_list.append(prefix + '_Atlas_1.6mm_demean.dtseries.nii')
            file_name_list.append(prefix + '_Atlas_1.6mm_hp2000_clean.dtseries.nii')
            file_name_list.append(prefix + '_Atlas_1.6mm_hp2000.dtseries.nii')
            file_name_list.append(prefix + '_Atlas_1.6mm_MSMAll_demean.dtseries.nii')
            file_name_list.append(prefix + '_Atlas_1.6mm_MSMAll_hp2000.dtseries.nii')

        if (not archive.is_resting_state_scan_name(scan_name)) and (not archive.is_movie_scan_name(scan_name)) and (not archive.is_retinotopy_scan_name(scan_name)):
            file_name_list.append(prefix + '_Atlas_1.6mm.dtseries.nii')
            file_name_list.append(prefix + '_Atlas_1.6mm_mean.dscalar.nii')
            file_name_list.append(prefix + '_Atlas_1.6mm_MSMAll_mean.dscalar.nii')


        t1w_dir = archive.DeDriftAndResample_HighRes_processed_dir_name(hcp7t_subject_info) + os.sep + 'T1w'
        t1w_fsave_dir = t1w_dir + os.sep + 'fsaverage_LR59k'
        t1w_native_dir = t1w_dir + os.sep + 'Native'

        prefix = t1w_fsave_dir + os.sep + hcp7t_subject_info.subject_id
        file_name_list.append(prefix + '.1.6mm_MSMAll.59k_fs_LR.wb.spec')
        file_name_list.append(prefix + '.L.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.midthickness_1.6mm_MSMAll_va.59k_fs_LR.shape.gii')
        file_name_list.append(prefix + '.L.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.L.white_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.midthickness_1.6mm_MSMAll_va.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.midthickness_1.6mm_MSMAll_va_norm.59k_fs_LR.dscalar.nii')
        file_name_list.append(prefix + '.R.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.midthickness_1.6mm_MSMAll_va.59k_fs_LR.shape.gii')
        file_name_list.append(prefix + '.R.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii')
        file_name_list.append(prefix + '.R.white_1.6mm_MSMAll.59k_fs_LR.surf.gii')
            
        prefix = t1w_native_dir + os.sep + hcp7t_subject_info.subject_id
        file_name_list.append(prefix + '.native.wb.spec')
            
        # Now check to see if expected files actually exist
        for file_name in file_name_list:
            if verbose:
                _inform("Checking for existence of file: " + file_name)
            if os.path.isfile(file_name):
                continue
            # If we get here, the most recently checked file does not exist
            _inform("FILE DOES NOT EXIST: " + file_name)
            return False

        # If we get here, all files that were checked exist
        return True


def _simple_interactive_demo():

    hcp7t_subject_info = hcp7t_subject.Hcp7TSubjectInfo(
        'HCP_1200', 'HCP_500', '102311')
    archive = hcp7t_archive.Hcp7T_Archive()

    completion_checker = DeDriftAndResampleHCP7T_HighRes_OneSubjectCompletionChecker()

    _inform("")
    _inform("Checking subject: " + hcp7t_subject_info.subject_id)
    _inform("")
    _inform("hcp7t_subject_info: " + str(hcp7t_subject_info))

    resource_exists = completion_checker.does_processed_resource_exist(archive, hcp7t_subject_info)
    _inform("resource_exists: " + str(resource_exists))

    scan_name_list = []
    scan_name_list.append('rfMRI_REST1_PA')
    scan_name_list.append('rfMRI_REST2_AP')
    scan_name_list.append('rfMRI_REST3_PA')
    scan_name_list.append('rfMRI_REST4_AP')
    scan_name_list.append('tfMRI_MOVIE1_AP')
    scan_name_list.append('tfMRI_MOVIE2_PA')
    scan_name_list.append('tfMRI_MOVIE3_PA')
    scan_name_list.append('tfMRI_MOVIE4_AP')
    scan_name_list.append('tfMRI_RETBAR1_AP')
    scan_name_list.append('tfMRI_RETBAR2_PA')
    scan_name_list.append('tfMRI_RETCCW_AP')
    scan_name_list.append('tfMRI_RETCON_PA')
    scan_name_list.append('tfMRI_RETCW_PA')
    scan_name_list.append('tfMRI_RETEXP_AP')
    scan_name_list.append('tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA')

    for scan_name in scan_name_list:
        _inform("scan_name: " + scan_name)
        processing_complete = completion_checker.is_processing_complete(archive, hcp7t_subject_info, scan_name)
        _inform("processing_complete: " + str(processing_complete))

    # hcp7t_subject_info = hcp7t_subject.Hcp7TSubjectInfo(
    #     'HCP_Staging_7T', 'HCP_900', '181636')

    hcp7t_subject_info = hcp7t_subject.Hcp7TSubjectInfo(
        'HCP_1200', 'HCP_900', '100610')

    
    _inform("")
    _inform("Checking subject: " + hcp7t_subject_info.subject_id)
    _inform("")
    _inform("hcp7t_subject_info: " + str(hcp7t_subject_info))

    for scan_name in scan_name_list:
        _inform("scan_name: " + scan_name)
        processing_complete = completion_checker.is_processing_complete(archive, hcp7t_subject_info, scan_name)
        _inform("processing_complete: " + str(processing_complete))


if __name__ == '__main__':
    _simple_interactive_demo()
