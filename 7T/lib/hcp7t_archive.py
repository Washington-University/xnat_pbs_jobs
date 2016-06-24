#!/usr/bin/env python3

"""hcp7t_archive.py: Provide information to allow direct access to an HCP 7T project archive."""

# import of built-in modules
import os
import sys
import glob

# import of third party modules
pass

# path changes and import of local modules
import hcp7t_subject

sys.path.append('../../lib')
import xnat_archive

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def inform(msg):
    """Inform the user of this program by outputing a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)

class Hcp7T_Archive:
    """This class provides information about direct access to an HCP 7T project data archive.
    
    This access goes 'behind the scenes' and uses the actual underlying file system and 
    assumes a particular organization of directories, resources, and file naming conventions.
    Because of this, a change in XNAT implemenation or a change in conventions could cause
    this code to no longer be correct.
    """

    @property
    def FUNCTIONAL_SCAN_MARKER(self):
        """Prefix to a resource directory name that indicates that the resource is for a functional MRI."""
        return 'fMRI'

    @property
    def RESTING_STATE_SCAN_MARKER(self):
        """Prefix to a resource directory name that indicates that the resource is for a resting state MRI."""
        return 'rfMRI'

    @property
    def TASK_SCAN_MARKER(self):
        """Prefix to a resource directory name that indicates that the resource is for a task scan."""
        return 'tfMRI'

    @property
    def UNPROC_SUFFIX(self):
        """Suffix to a resource directory name that indicates that the resource contains unprocessed data."""
        return 'unproc'

    @property
    def PREPROC_SUFFIX(self):
        """Suffix to a resource directory name that indicates that the resource contains preprocessed data."""
        return 'preproc'

    @property
    def FIX_PROCESSED_SUFFIX(self):
        """Suffix to a resource directory name that indicates that the resource contains FIX processed data."""
        return 'FIX'

    @property
    def NAME_DELIMITER(self):
        """Character (or string) used to delimit the parts of a resource name.

        Separates the prefix that indicates the type of the scan (e.g. tfMRI, rfMRI, etc.)
        from the general name of the scan (e.g. REST2, MOVIE1, RETBAR1) and from the 
        suffix that indicates the state of the data (e.g. unproc, preproc, FIX)
        """
        return '_'

    @property
    def TESLA_SPEC(self):
        """String to indicate the tesla rating of the scanner used."""
        return '7T'

    def __init__(self):
        """Constructs an Hcp7T_Archive object for direct access to an HCP 7T project data archive."""
        self._xnat_archive = xnat_archive.XNAT_Archive()

    @property
    def build_home(self):
        """Returns the temporary build/processing directory root."""
        return self._xnat_archive.build_space_root

    def session_name(self, hcp7t_subject_info):
        """Returns the conventional session name for a subject in this HCP 7T project archive.

        :param hcp7t_subject_info: specification of the subject for which a session name will be returned
        :type hcp7t_subject_info: Hcp7TSubjectInfo

        :Example:

        If hcp7t_subject_info.subject_id is 100307, this method would return 100307_7T.
        """
        return hcp7t_subject_info.subject_id + self.NAME_DELIMITER + self.TESLA_SPEC

    def session_dir(self, hcp7t_subject_info):
        """Returns the full path to the conventional session for a subject in this HCP 7T project archive.

        :param hcp7t_subject_info: specification of the subject for which a session directory path 
                                   will be returned
        :type hcp7t_subject_info: Hcp7TSubjectInfo
        """
        return self._xnat_archive.project_archive_root(hcp7t_subject_info.project) + '/' + self.session_name(hcp7t_subject_info)

    def subject_resources_dir(self, hcp7t_subject_info):
        """Returns the full path to the conventional subject-level resources directory for a subject in this HCP 7T project archive.

        :param hcp7t_subject_info: specification of the subject for which a subject-level resources path will be returned
        :type hcp7t_subject_info: Hcp7TSubjectInfo
        """
        return self.session_dir(hcp7t_subject_info) + '/RESOURCES'

    def available_functional_unproc_dirs(self, hcp7t_subject_info):
        """Returns a list of full paths to unprocessed functional scan resources.

        :param hcp7t_subject_info: specification of the subject for which a list of resource dirs will be returned
        :type hcp7t_subject_info: HCP7TSubjectInfo
        """
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + self.FUNCTIONAL_SCAN_MARKER + '*' + self.UNPROC_SUFFIX) 
        return sorted(dir_list)

    def _get_scan_name_from_path(self, path):
        short_path = os.path.basename(path)
        last_char = short_path.rfind(self.NAME_DELIMITER)
        name = short_path[:last_char]
        return name

    def available_functional_unproc_names(self, hcp7t_subject_info):
        """Returns a list of scan names (not full paths) of available unprocessed functional resources.

        :param hcp7t_subject_info: specification of the subject for which a list of unprocessed functional names will be returned
        :type hcp7t_subject_info: HCP7TSubjectInfo

        :Example:
        
        If the full paths to the available unprocessed functional scans for the specified subject are:

        /HCP/hcpddb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/rfMRI_REST1_PA_unproc
        /HCP/hcpddb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/rfMRI_REST2_AP_unproc
        /HCP/hcpddb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/tfMRI_MOVIE1_AP_unproc
        /HCP/hcpddb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/tfMRI_MOVIE2_PA_unproc
        /HCP/hcpddb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/tfMRI_RETCCW_AP_unproc
        /HCP/hcpddb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/tfMRI_RETEXP_AP_unproc

        Then the list of scan names returned by this method will be:
 
        rfMRI_REST1_PA
        rfMRI_REST2_AP
        tfMRI_MOVIE1_AP
        tfMRI_MOVIE2_PA
        tfMRI_RETCCW_AP
        tfMRI_RETEXP_AP

        Notice that not only is the path to the scans not included, the suffix indicating the state of the data,
        unproc, is removed leaving just the scan 'name'.
        """
        dir_list = self.available_functional_unproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_diffusion_unproc_dirs(self, hcp7t_subject_info):
        """Returns a list of full paths to unprocessed diffusion resources.

        :param hcp7t_subject_info: specification of the subject for which a list of resource dirs will be returned
        :type hcp7t_subject_info: HCP7TSubjectInfo
        """
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/Diffusion*' + self.UNPROC_SUFFIX)
        return sorted(dir_list)

    def available_diffusion_unproc_names(self, hcp7t_subject_info):
        """Returns a list of scan resource names (not full paths) for unprocessed diffusion resources.

        :param hcp7t_subject_info: specification of subject
        :type hcp7t_subject_info: HCP7TSubjectInfo
        """
        dir_list = self.available_diffusion_unproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_functional_preproc_dirs(self, hcp7t_subject_info):
        """Returns a list of full paths to preprocessed functional scan resources.

        :param hcp7t_subject_info: specification of the subject for which a list of resource dirs will be returned
        :type hcp7t_subject_info: HCP7TSubjectInfo
        """
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + self.FUNCTIONAL_SCAN_MARKER + '*' + self.PREPROC_SUFFIX) 
        return sorted(dir_list)

    def available_functional_preproc_names(self, hcp7t_subject_info):
        """Returns a list of scan names (not full paths) of available preprocessed functional resources.

        :param hcp7t_subject_info: specification of the subject for which a list of preprocessed functional names will be returned
        :type hcp7t_subject_info: HCP7TSubjectInfo
        """
        dir_list = self.available_functional_preproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def does_functional_preproc_exist(self, hcp7t_subject_info, scan_name):
        """Returns True if there is a functional preproc resource available for the specified scan name.

        :param hcp7t_subject_info: specification of the subject 
        :type hcp7t_subject_info: HCP7TSubjectInfo
        :param scan_name: name of scan for which to check for a functional preproc resource (e.g. tfMRI_MOVIE2_PA)
        :type scan_name: str
        """
        return scan_name in self.available_functional_preproc_names(hcp7t_subject_info)

    def functionally_preprocessed(self, hcp7t_subject_info, scan_name):
        """Returns True if the specified scan has been functionally preprocessed for the specified subject.

        :param hcp7t_subject_info: specification of the subject
        :type hcp7t_subject_info: HCP7TSubjectInfo
        :param scan_name: name of scan for which to determine if the scan has been functionally preprocessed
        :type scan_name: str
        """

        # NOTE: This needs to be modified to do more than simply check to see if the resource exists.
        # It needs to also do the check to see if all the appropriate files exist.
        return self.does_functional_preproc_exist(hcp7t_subject_info, scan_name)

    def available_FIX_processed_dirs(self, hcp7t_subject_info):
        """Returns a list of full paths to FIX processed scan resources.

        :param hcp7t_subject_info: specification of subject for which a list of resource dirs will be returned
        :type hcp7t_subject_info: HCP7TSubjectInfo
        """
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + self.FUNCTIONAL_SCAN_MARKER + '*' + self.FIX_PROCESSED_SUFFIX)
        return sorted(dir_list)

    def available_FIX_processed_names(self, hcp7t_subject_info):
        """Returns a list of scan names (not full paths) of available FIX processed scans.

        :param hcp7t_subject_info: specificatioin of the subject for which a list of preprocessed functional names will be returned
        :type hcp7t_subject_info: HCP7TSubjectInfo
        """
        dir_list = self.available_FIX_processed_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def FIX_processed_resource_name(self, scan_name):
        return scan_name + self.NAME_DELIMITER + self.FIX_PROCESSED_SUFFIX

    def does_FIX_processed_exist(self, hcp7t_subject_info, scan_name):
        """Returns True if there is a FIX processed resource available for the specified scan name.

        :param hcp7t_subject_info: specification of subject
        :type hcp7t_subject_info: HCP7TSubjectInfo
        :param scan_name: name of scan for which to check for a FIX processed resource (e.g. rfMRI_REST1_AP)
        :type scan_name: str
        """
        return scan_name in self.available_FIX_processed_names(hcp7t_subject_info)

    def FIX_processed(self, hcp7t_subject_info, scan_name):
        """Returns True if the specified scan has been FIX processed for the specified subject.

        :param hcp7t_subject_info: specification of the subject
        :type hcp7t_subject_info: HCP7TSubjectInfo
        :param scan_name: name of scan for which to determine if the scan has been FIX processed
        :type scan_name: str
        """

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
            #inform("Checking for existance of file: " + file_name)
            if os.path.isfile(file_name):
                continue
            # If we get here, the most recently checked file does not exist
            inform("FILE DOES NOT EXIST: " + file_name)
            return False

        # If we get here, all files that were checked exist
        return True
        
    def available_resting_state_preproc_dirs(self, hcp7t_subject_info):
        """Returns a list of full paths to functionally preprocessed resting state scan resources.

        :param hcp7t_subject_info: specification of the subject for which a list of resource dirs will be returned
        :type hcp7t_subject_info: Hcp7TSubjectInfo
        """
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + self.RESTING_STATE_SCAN_MARKER + '*' + self.PREPROC_SUFFIX)
        return sorted(dir_list)

    def available_resting_state_preproc_names(self, hcp7t_subject_info):
        """Returns a list of scan names (not full paths) of available preprocessed resting state scan resources.

        :param hcp7t_subject_info: specification of the subject
        :type hcp7t_subject_info: Hcp7TSubjectInfo
        """
        dir_list = self.available_resting_state_preproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_task_preproc_dirs(self, hcp7t_subject_info):
        """Returns a list of full paths to functionally preprocessed task scan resources.
        
        :param hcp7t_subject_info: specification of the subject
        :type hcp7t_subject_info: Hcp7TSubjectInfo
        """
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + self.TASK_SCAN_MARKER + '*' + self.PREPROC_SUFFIX)
        return sorted(dir_list)

    def available_task_preproc_names(self, hcp7t_subject_info):
        """Returns a list of scan names (not full paths) of available preprocessed task scan resources.

        :param hcp7t_subject_info: specification of the subject
        :type hcp7t_subject_info: Hcp7TSubjectInfo
        """
        dir_list = self.available_task_preproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_movie_preproc_dirs(self, hcp7t_subject_info):
        """Returns a list of full paths to functionally preprocessed MOVIE task scan resources.
        
        :param hcp7t_subject_info: specification of the subject
        :type hcp7t_subject_info: Hcp7TSubjectInfo
        """
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + self.TASK_SCAN_MARKER + '*MOVIE*' + self.PREPROC_SUFFIX)
        return sorted(dir_list)

    def available_movie_preproc_names(self, hcp7t_subject_info):
        """Returns a list of scan names (not full paths) of available preprocessed MOVIE task scan resources.

        :param hcp7t_subject_info: specification of the subject
        :type hcp7t_subject_info: Hcp7TSubjectInfo
        """
        dir_list = self.available_movie_preproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def functional_scan_prefix(self, functional_scan_name):
        """Extracts and returns the 'prefix' part of a functional scan name.
        
        :param functional_scan_name: name of scan (e.g. rfMRI_REST3_PA)
        :type functional_scan_name: str

        :Example:

        functional_scan_prefix('rfMRI_REST3_PA') returns 'rfMRI'
        """
        (prefix, base_name, pe_dir) = functional_scan_name.split(self.NAME_DELIMITER)
        return prefix

    def functional_scan_base_name(self, functional_scan_name):
        """Extracts and returns the 'base_name' part of a functional scan name.

        :param functional_scan_name: name of scan (e.g. rfMRI_REST3_PA)
        :type functional_scan_name: str

        :Example:

        functional_scan_base_name('rfMRI_REST3_PA') returns 'REST3'
        """
        (prefix, base_name, pe_dir) = functional_scan_name.split(self.NAME_DELIMITER)
        return base_name

    def functional_scan_pe_dir(self, functional_scan_name):
        """Extracts and returns the phase encoding direction, 'pe_dir', part of a functional scan name.

        :param functional_scan_name: name of scan (e.g. rfMRI_REST3_PA)
        :type functional_scan_name: str

        :Example:

        functional_scan_pe_dir('rfMRI_REST3_PA') returns 'PA'
        """
        (prefix, base_name, pe_dir) = functional_scan_name.split(self.NAME_DELIMITER)
        return pe_dir

    def functional_scan_long_name(self, functional_scan_name):
        """Returns the 'long form' of the specified functional scan name.

        :param functional_scan_name: name of scan (e.g. rfMRI_REST3_PA)
        :type functional_scan_name: str

        This 'long form' is used in some processing contexts as the fMRIName.

        :Example:

        functional_scan_long_name('rfMRI_REST3_PA') returns 'rfMRI_REST3_7T_PA'
        """
        (prefix, base_name, pe_dir) = functional_scan_name.split(self.NAME_DELIMITER)
        return prefix + self.NAME_DELIMITER + base_name + self.NAME_DELIMITER + self.TESLA_SPEC + self.NAME_DELIMITER + pe_dir
    

if __name__ == "__main__":

    hcp7t_archive = Hcp7T_Archive()
    
    subject = hcp7t_subject.Hcp7TSubjectInfo('HCP_Staging_7T', 'HCP_500', '102311')
    print('HCP7T session dir: ' + hcp7t_archive.session_dir(subject))

    print(os.linesep + 'Available functional unproc dirs: ')
    for directory in hcp7t_archive.available_functional_unproc_dirs(subject):
        print(directory)

    print(os.linesep + 'Available functional unproc scan names: ')
    for name in hcp7t_archive.available_functional_unproc_names(subject):
        print(name)
    
    print(os.linesep + 'Available diffusion unproc dirs: ')
    for directory in hcp7t_archive.available_diffusion_unproc_dirs(subject):
        print(directory)

    print(os.linesep + 'Available diffusion unproc scan names: ')
    for name in hcp7t_archive.available_diffusion_unproc_names(subject):
        print(name)

    print(os.linesep + 'Available functional preproc dirs: ')
    for directory in hcp7t_archive.available_functional_preproc_dirs(subject):
        print(directory)

    print(os.linesep + 'Available functional preproc scan names: ')
    for name in hcp7t_archive.available_functional_preproc_names(subject):
        print(name)

    print(os.linesep + 'Are the following functional scans preprocessed')
    for name in hcp7t_archive.available_functional_unproc_names(subject):
        print('scan name: ' + name + ' ' + '\tfunctionally preprocessed: ' + str(hcp7t_archive.functionally_preprocessed(subject, name)))

    print(os.linesep + 'Available FIX processed dirs: ')
    for directory in hcp7t_archive.available_FIX_processed_dirs(subject):
        print(directory)

    print(os.linesep + 'Available FIX processed scan names: ')
    for name in hcp7t_archive.available_FIX_processed_names(subject):
        print(name)

    print(os.linesep + 'Are the following functional scans FIX processed')
    for name in hcp7t_archive.available_functional_unproc_names(subject):
        print('scan name: ' + name + ' ' + '\tFIX processed: ' + str(hcp7t_archive.FIX_processed(subject, name)))

    print(os.linesep + 'Available unprocessed scan names: ')
    for name in hcp7t_archive.available_functional_unproc_names(subject):
        print(name + '\t' +
              '\tprefix: '    + hcp7t_archive.functional_scan_prefix(name) +
              '\tbase_name: ' + hcp7t_archive.functional_scan_base_name(name) +
              '\tpe_dir: '    + hcp7t_archive.functional_scan_pe_dir(name) +
              '\tlong_name: ' + hcp7t_archive.functional_scan_long_name(name))


