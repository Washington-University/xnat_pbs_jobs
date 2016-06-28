#!/usr/bin/env python3

"""hcp7t_archive.py: Provide direct access to an HCP 7T project archive."""

# import of built-in modules
import os
import sys
import glob

# import of third party modules
pass

# path changes and import of local modules
import hcp7t_subject
#import xnat_archive
import hcp_archive

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def _inform(msg):
    """Inform the user by writing out a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)

class Hcp7T_Archive(hcp_archive.HcpArchive):
    """This class provides access to an HCP 7T project data archive.
    
    This access goes 'behind the scenes' and uses the actual underlying file
    system and assumes a particular organization of directories, resources, and 
    file naming conventions. Because of this, a change in XNAT implementation 
    or a change in conventions could cause this code to no longer be correct.
    """

    @property
    def TESLA_SPEC(self):
        """String to indicate the tesla rating of the scanner used."""
        return '7T'


    def __init__(self):
        """Constructs an Hcp7T_Archive object for direct access to an HCP 7T project data archive."""
        super().__init__()


    def FIX_processed(self, hcp7t_subject_info, scan_name):
        """Returns True if the specified scan has been FIX processed for the specified subject."""

        # If the output resource does not exist, then the processing has not been done.
        if not self.does_FIX_processed_exist(hcp7t_subject_info, scan_name):
            return False

        # If we reach here, then the FIX processed resource at least exists.  
        # Next we need to check to see if the expected files exist.

        results_dir = self.subject_resources_dir(hcp7t_subject_info) + os.sep + self.FIX_processed_resource_name(scan_name)
        results_scan_dir = results_dir + os.sep + self.functional_scan_long_name(scan_name)
        ica_dir = results_scan_dir + os.sep + self.functional_scan_long_name(scan_name) + '_hp2000.ica'

        file_name_list = []        
        file_name_list.append(ica_dir + os.sep + 'Atlas_hp_preclean.dtseries.nii') 
        file_name_list.append(ica_dir + os.sep + 'Atlas.nii.gz')
        file_name_list.append(ica_dir + os.sep + 'mask.nii.gz')

        filtered_func_dir = ica_dir + os.sep + 'filtered_func_data.ica'

        file_name_list.append(filtered_func_dir + os.sep + 'eigenvalues_percent')
        file_name_list.append(filtered_func_dir + os.sep + 'log.txt')
        file_name_list.append(filtered_func_dir + os.sep + 'mask.nii.gz')
        file_name_list.append(filtered_func_dir + os.sep + 'mean.nii.gz')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_dewhite')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_FTdewhite')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_FTmix')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_IC.nii.gz')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_ICstats')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_mix')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_oIC.nii.gz')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_pcaD')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_pcaE')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_pca.nii.gz')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_PPCA')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_Tmodes')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_unmix')
        file_name_list.append(filtered_func_dir + os.sep + 'melodic_white')
        file_name_list.append(filtered_func_dir + os.sep + 'Noise__inv.nii.gz')

        fix_dir = ica_dir + os.sep + 'fix'

        file_name_list.append(fix_dir + os.sep + 'fastsg_mixeltype.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'fastsg_seg.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'features.csv')
        file_name_list.append(fix_dir + os.sep + 'features_info.csv')
        file_name_list.append(fix_dir + os.sep + 'features.mat')
        file_name_list.append(fix_dir + os.sep + 'highres2std.mat')
        file_name_list.append(fix_dir + os.sep + 'hr2exf.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'hr2exfTMP.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'hr2exfTMP.txt')
        file_name_list.append(fix_dir + os.sep + 'logMatlab.txt')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc0dil2.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc0dil.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc0.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc1dil2.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc1dil.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc1.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc2dil2.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc2dil.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc2.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc3dil2.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc3dil.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std1mm2exfunc3.nii.gz')
        file_name_list.append(fix_dir + os.sep + 'std2exfunc.mat')
        file_name_list.append(fix_dir + os.sep + 'std2highres.mat')
        file_name_list.append(fix_dir + os.sep + 'subcort.nii.gz')

        reg_dir = ica_dir + os.sep + 'reg'

        file_name_list.append(reg_dir + os.sep + 'highres2example_func.mat')
        file_name_list.append(reg_dir + os.sep + 'veins_exf.nii.gz')
        file_name_list.append(reg_dir + os.sep + 'veins.nii.gz')

        mc_dir = ica_dir + os.sep + 'mc'

        file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf_conf_hp.nii.gz')
        file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf_conf.nii.gz')
        file_name_list.append(mc_dir + os.sep + 'prefiltered_func_data_mcf.par')

        for file_name in file_name_list:
            #_inform("Checking for existance of file: " + file_name)
            if os.path.isfile(file_name):
                continue
            # If we get here, the most recently checked file does not exist
            _inform("FILE DOES NOT EXIST: " + file_name)
            return False

        # If we get here, all files that were checked exist
        return True
        

    def available_movie_preproc_dirs(self, subject_info):
        """Returns a list of full paths to functionally preprocessed MOVIE task scan resources."""
        dir_list = glob.glob(self.subject_resources_dir(subject_info) + '/*' + 
                             self.TASK_SCAN_MARKER + '*MOVIE*' + self.PREPROC_SUFFIX)
        return sorted(dir_list)


    def available_movie_preproc_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available preprocessed 
        MOVIE task scan resources."""
        dir_list = self.available_movie_preproc_dirs(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    
    def available_retinotopy_preproc_dirs(self, subject_info):
        """Returns a list of full paths to functionally preprocessed retinotopy task scan 
        resources."""
        dir_list = glob.glob(self.subject_resources_dir(subject_info) + '/*' +
                             self.TASK_SCAN_MARKER + '*RET*' + self.PREPROC_SUFFIX)
        return sorted(dir_list)


    def available_retinotopy_preproc_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available functionally
        preprocessed retinotopy task scan resources."""
        dir_list = self.available_retinotopy_preproc_dirs(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list


    def functional_scan_long_name(self, functional_scan_name):
        """Returns the 'long form' of the specified functional scan name.

        This 'long form' is used in some processing contexts as the fMRIName.

        :Example:

        functional_scan_long_name('rfMRI_REST3_PA') returns 'rfMRI_REST3_7T_PA'
        """
        (prefix, base_name, pe_dir) = functional_scan_name.split(self.NAME_DELIMITER)
        return prefix + self.NAME_DELIMITER + base_name + self.NAME_DELIMITER + self.TESLA_SPEC + self.NAME_DELIMITER + pe_dir

    
def _simple_interactive_demo():

    archive = Hcp7T_Archive()
    
    _inform("archive.FUNCTIONAL_SCAN_MARKER: " + archive.FUNCTIONAL_SCAN_MARKER)
    _inform("archive.RESTING_STATE_SCAN_MARKER: " + archive.RESTING_STATE_SCAN_MARKER)
    _inform("archive.TASK_SCAN_MARKER: " + archive.TASK_SCAN_MARKER)
    _inform("archive.UNPROC_SUFFIX: " + archive.UNPROC_SUFFIX)
    _inform("archive.PREPROC_SUFFIX: " + archive.PREPROC_SUFFIX)
    _inform("archive.FIX_PROCESSED_SUFFIX: " + archive.FIX_PROCESSED_SUFFIX)
    _inform("archive.NAME_DELIMITER: " + archive.NAME_DELIMITER)
    _inform("archive.TESLA_SPEC: " + archive.TESLA_SPEC)
    _inform("archive.build_home: " + archive.build_home)

    subject_info = hcp7t_subject.Hcp7TSubjectInfo('HCP_Staging_7T', 'HCP_500', '102311')
    _inform("created subject_info: " + str(subject_info))
    _inform("archive.session_name(subject_info): " + archive.session_name(subject_info))
    _inform("archive.session_dir(subject_infor): " + archive.session_dir(subject_info))
    _inform("archive.subject_resources_dir(subject_info): " + 
            archive.subject_resources_dir(subject_info))

    _inform("")
    _inform("Available functional unproc dirs: ")
    for directory in archive.available_functional_unproc_dirs(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available functional unproc scan names: ")
    for name in archive.available_functional_unproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Available diffusion unproc dirs: ")
    for directory in archive.available_diffusion_unproc_dirs(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available diffusion unproc scan names: ")
    for name in archive.available_diffusion_unproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Available functional preproc dirs: ")
    for directory in archive.available_functional_preproc_dirs(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available functional preproc scan names: ")
    for name in archive.available_functional_preproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Are the following functional scans preprocessed")
    for name in archive.available_functional_unproc_names(subject_info):
        _inform("scan name: " + name + " " + "\tfunctionally preprocessed: " + 
              str(archive.functionally_preprocessed(subject_info, name)))

    _inform("")
    _inform("Available FIX processed dirs: ")
    for directory in archive.available_FIX_processed_dirs(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available FIX processed scan names: ")
    for name in archive.available_FIX_processed_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Are the following functional scans FIX processed")
    for name in archive.available_functional_unproc_names(subject_info):
        _inform('scan name: ' + name + ' ' + '\tFIX processed: ' + 
              str(archive.FIX_processed(subject_info, name)))

    _inform("")
    _inform("Available resting state preproc dirs: ")
    for directory in archive.available_resting_state_preproc_dirs(subject_info):
        _inform(directory)
    
    _inform("")
    _inform("Available resting state preproc names: ")
    for name in archive.available_resting_state_preproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Available task preproc dirs: ")
    for directory in archive.available_task_preproc_dirs(subject_info):
        _inform(directory)
    
    _inform("")
    _inform("Available task preproc names: ")
    for name in archive.available_task_preproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Available MOVIE preproc dirs: ")
    for directory in archive.available_movie_preproc_dirs(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available MOVIE preproc names: ")
    for name in archive.available_movie_preproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Available RETINOTOPY preproc dirs: ")
    for directory in archive.available_retinotopy_preproc_dirs(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available RETINOTOPY preproc names: ")
    for name in archive.available_retinotopy_preproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Available functional unprocessed scan names: ")
    for name in archive.available_functional_unproc_names(subject_info):
        _inform(name + '\t' +
                '\tprefix: '    + archive.functional_scan_prefix(name) +
                '\tbase_name: ' + archive.functional_scan_base_name(name) +
                '\tpe_dir: '    + archive.functional_scan_pe_dir(name) +
                '\tlong_name: ' + archive.functional_scan_long_name(name))

    _inform("")
    _inform("Available session dirs for project: " + subject_info.project)
    for session in archive.available_session_dirs(subject_info.project):
        _inform(session)

    _inform("")
    _inform("Available session names for project: " + subject_info.project)
    for name in archive.available_session_names(subject_info.project):
        _inform(name)

    _inform("")
    _inform("Available subject ids for project: " + subject_info.project)
    for subject_id in archive.available_subject_ids(subject_info.project):
        _inform(subject_id)

    _inform("")
    _inform("Number of available subject ids for project: " + subject_info.project + " " + 
            str(archive.subject_count(subject_info.project)))

    _inform("")
    _inform("Available diffusion scans: ")
    for scan in archive.available_diffusion_scans(subject_info):
        _inform(scan)

    _inform("")
    _inform("Available diffusion scan names: ")
    for scan_name in archive.available_diffusion_scan_names(subject_info):
        _inform(scan_name)
    
if __name__ == '__main__':
    _simple_interactive_demo()
