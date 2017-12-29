#!/usr/bin/env python3

"""
DeDriftAndResampleHCP7T_OneSubjectCompletionChecker.py: Check DeDriftAndResampleHCP7T processing
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


class DeDriftAndResampleHCP7T_OneSubjectCompletionChecker:

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, hcp7t_subject_info):
        dir_list = archive.available_DeDriftAndResample_processed_dirs(hcp7t_subject_info)
        return len(dir_list) > 0

    def is_processing_complete(self, archive, hcp7t_subject_info, scan_name, verbose=False):

        # If the output resource does not exist, then the DeDriftAndResampleHCP7T processing
        # certainly has not been done.
        if not self.does_processed_resource_exist(archive, hcp7t_subject_info):
            return False

        # If we reach here, then the processed resource at least exists.
        # Next we need to check to see if the expected files exist for the specified scan.

        # Build list of expected files
        results_dir = archive.DeDriftAndResample_processed_dir_name(hcp7t_subject_info)
        mni_nonlinear_dir = results_dir + os.sep + 'MNINonLinear'
        fsaverage_dir = mni_nonlinear_dir + os.sep + 'fsaverage_LR32k'
        native_dir = mni_nonlinear_dir + os.sep + 'Native'
        results_scan_dir = mni_nonlinear_dir + os.sep + 'Results' + os.sep + archive.functional_scan_long_name(scan_name)

        file_name_list = []

        # mni_nonlinear_dir
        
        for map in ['ArealDistortion', 'corrThickness', 'curvature', 'EdgeDistortion', 'MyelinMap_BC', 'SmoothedMyelinMap_BC', 'SphericalDistortion', 'sulc', 'thickness']:
            file_name_list.append(mni_nonlinear_dir + os.sep + hcp7t_subject_info.subject_id + '.' + map + '_MSMAll.164k_fs_LR.dscalar.nii')

        for surface in ['inflated', 'midthickness', 'pial', 'very_inflated', 'white']:
            for side in ['L', 'R']:
                file_name_list.append(mni_nonlinear_dir + os.sep + hcp7t_subject_info.subject_id + '.' + side + '.' + surface + '_MSMAll.164k_fs_LR.surf.gii')
            
        file_name_list.append(mni_nonlinear_dir + os.sep + hcp7t_subject_info.subject_id + '.MSMAll.164k_fs_LR.wb.spec')

        # fsaverage_dir
        
        for map in ['ArealDistortion', 'BiasField', 'corrThickness', 'curvature', 'EdgeDistortion', 'MyelinMap_BC', 'MyelinMap', 'SmoothedMyelinMap_BC', 'SphericalDistortion', 'sulc', 'thickness' ]:
            file_name_list.append(fsaverage_dir + os.sep + hcp7t_subject_info.subject_id + '.' + map + '_MSMAll.32k_fs_LR.dscalar.nii')

        for surface in ['inflated', 'midthickness', 'pial', 'very_inflated', 'white']:
            for side in ['L', 'R']:
                file_name_list.append(fsaverage_dir + os.sep + hcp7t_subject_info.subject_id + '.' + side + '.' + surface + '_MSMAll.32k_fs_LR.surf.gii')

        file_name_list.append(fsaverage_dir + os.sep + hcp7t_subject_info.subject_id + '.MSMAll.32k_fs_LR.wb.spec')

        # native_dir
        
        for map in ['ArealDistortion', 'BiasField', 'EdgeDistortion', 'MyelinMap_BC', 'SmoothedMyelinMap_BC']:
            file_name_list.append(native_dir + os.sep + hcp7t_subject_info.subject_id + '.' + map + '_MSMAll.native.dscalar.nii')

        for shape in ['ArealDistortion', 'EdgeDistortion']:
            for side in ['L', 'R']:
                file_name_list.append(native_dir + os.sep + hcp7t_subject_info.subject_id + '.' + side + '.' + shape + '_MSMAll.native.shape.gii')
            
        for surface in ['sphere']:
            for side in ['L', 'R']:
                file_name_list.append(native_dir + os.sep + hcp7t_subject_info.subject_id + '.' + side + '.' + surface + '.MSMAll.native.surf.gii')
        
        file_name_list.append(native_dir + os.sep + hcp7t_subject_info.subject_id + '.native.wb.spec')
                              
        # results_scan_dir
        retinotopy_scans_count = len(archive.available_retinotopy_unproc_dirs(hcp7t_subject_info))
        
        if archive.is_concatenated_scan_name(scan_name):
            if retinotopy_scans_count == 6:
            
                file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                      '_Atlas_MSMAll_demean.dtseries.nii')
                file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                      '_Atlas_MSMAll.dtseries.nii')
                file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                      '_Atlas_MSMAll_hp2000_clean.dtseries.nii')
                file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                      '_Atlas_MSMAll_hp2000.dtseries.nii')
                file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                '_Atlas_MSMAll_mean.dscalar.nii')
                
                ica_dir = results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) + '_hp2000.ica'

                file_name_list.append(ica_dir + os.sep + 'Atlas.dtseries.nii')
                
        elif archive.is_resting_state_scan_name(scan_name) or archive.is_movie_scan_name(scan_name):
                        
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_Atlas_MSMAll.dtseries.nii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_MSMAll.L.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_MSMAll.R.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_s2_MSMAll.L.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_s2_MSMAll.R.atlasroi.32k_fs_LR.func.gii')

            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_Atlas_MSMAll_hp2000_clean.dtseries.nii')

            ica_dir = results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) + '_hp2000.ica'

            file_name_list.append(ica_dir + os.sep + 'Atlas.dtseries.nii')
            file_name_list.append(ica_dir + os.sep + 'Atlas_hp_preclean.dtseries.nii')
            file_name_list.append(ica_dir + os.sep + 'Atlas.nii.gz')

            mc_dir = ica_dir + os.sep + 'mc'

            file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf_conf_hp.nii.gz')
            file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf_conf.nii.gz')
            file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf.par')

        else:

            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_Atlas_MSMAll_demean.dtseries.nii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_Atlas_MSMAll.dtseries.nii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_Atlas_MSMAll_hp2000_clean.dtseries.nii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_Atlas_MSMAll_hp2000.dtseries.nii')            
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_MSMAll.L.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_MSMAll.R.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_s2_MSMAll.L.atlasroi.32k_fs_LR.func.gii')
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_s2_MSMAll.R.atlasroi.32k_fs_LR.func.gii')
            
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

    completion_checker = DeDriftAndResampleHCP7T_OneSubjectCompletionChecker()

    _inform("")
    _inform("Checking subject: 102311")
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

    for scan_name in scan_name_list:
        _inform("scan_name: " + scan_name)
        processing_complete = completion_checker.is_processing_complete(archive, hcp7t_subject_info, scan_name)
        _inform("processing_complete: " + str(processing_complete))

    hcp7t_subject_info = hcp7t_subject.Hcp7TSubjectInfo(
        'HCP_Staging_7T', 'HCP_900', '181636')

    _inform("")
    _inform("Checking subject: 181636")
    _inform("")
    _inform("hcp7t_subject_info: " + str(hcp7t_subject_info))

    for scan_name in scan_name_list:
        _inform("scan_name: " + scan_name)
        processing_complete = completion_checker.is_processing_complete(archive, hcp7t_subject_info, scan_name)
        _inform("processing_complete: " + str(processing_complete))


if __name__ == '__main__':
    _simple_interactive_demo()
