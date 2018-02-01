#!/usr/bin/env python3

"""hcp/archive.py: Provide direct access to an HCP project archive."""

# import of built-in modules
import abc
import glob
import os

# import of third party modules
# None


# import of local modules
import xnat.xnat_archive as xnat_archive


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


class HcpArchive(abc.ABC):
    """This class provides access to an HCP project data archive.

    This access goes 'behind the scenes' and uses the actual underlying file
    system and assumes a particular organization of directories, resources, and
    file naming conventions. Because of this, a change in XNAT implementation
    or a change in conventions could cause this code to no longer be correct.
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
    def POSTFIX_PROCESSED_SUFFIX(self):
        """Suffix to a resource directory name that indicates that the resource contains PostFix processed data."""
        return 'PostFix'

    @property
    def RSS_PROCESSED_SUFFIX(self):
        """Suffix to a resource directory name that indicates that the resource contains Resting State Stats processed data."""
        return 'RSS'

    @property
    def HAND_RECLASSIFICATION_SUFFIX(self):
        """Suffix to a resource directory name that indicates that the resource contains hand reclassification data."""
        return 'HandReclassification'

    @property
    def APPLY_HAND_RECLASSIFICATION_SUFFIX(self):
        """Suffix to a resource directory name that indicates that the resource contains applied hand reclassification data."""
        return 'ApplyHandReClassification'

    @property
    def DEDRIFT_AND_RESAMPLE_RESOURCE_NAME(self):
        """Name of MSM All DeDriftAndResample resource"""
        return 'MSMAllDeDrift'

    @property
    def BEDPOSTX_PROCESSED_RESOURCE_NAME(self):
        """Name of resource containing bedpostx processed data."""
        return 'Diffusion_bedpostx'

    @property
    def HAND_RECLASSIFICATION_SUFFIX(self):
        """Suffix to a resource directory name that indicates that the resource contains hand reclassification files."""
        return "HandReclassification"

    @property
    def REAPPLY_FIX_SUFFIX(self):
        return "ReApplyFix"

    @property
    def NAME_DELIMITER(self):
        """Character (or string) used to delimit the parts of a resource name.

        Separates the prefix that indicates the type of the scan (e.g. tfMRI, rfMRI, etc.)
        from the general name of the scan (e.g. REST2, MOVIE1, RETBAR1) and from the
        suffix that indicates the state of the data (e.g. unproc, preproc, FIX)
        """
        return '_'

    @property
    @abc.abstractmethod
    def TESLA_SPEC(self):
        pass

    def __init__(self):
        """Constructs an HcpArchive object."""
        self._xnat_archive = xnat_archive.XNAT_Archive()

    @property
    def xnat_archive(self):
        """an XNAT_Archive object that provides direct access
        to an XNAT data archive on the file system."""
        return self._xnat_archive

    @property
    def build_home(self):
        """the temporary build/processing space directory root."""
        return self.xnat_archive.build_space_root

    def session_name(self, subject_info):
        """the conventional session name for a subject in this project archive.
        e.g. <subject-id>_3T"""
        return subject_info.subject_id + self.NAME_DELIMITER + self.TESLA_SPEC

    def project_archive_root(self, project):
        return self.xnat_archive.project_archive_root(project)

    def session_dir_fullpath(self, subject_info):
        """the full path to the conventional session directory for a subject in
        this project archive."""
        return self.project_archive_root(subject_info.project) + '/' + self.session_name(subject_info)

    def subject_resources_dir_fullpath(self, subject_info):
        """the full path to the conventional subject-level resources
        directory for a subject in this project archive."""
        return self.session_dir_fullpath(subject_info) + '/RESOURCES'

    def available_functional_unproc_dir_fullpaths(self, subject_info):
        """list of full paths to unprocessed functional scan resource directories"""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.FUNCTIONAL_SCAN_MARKER + '*' + self.UNPROC_SUFFIX)
        return sorted(dir_list)

    def available_functional_unproc_names(self, subject_info):
        """list of scan names (not full paths) of available unprocessed functional scans.

        :Example:

        If the full paths to the available unprocessed functional scans for the
        specified subject are:

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

        Notice that not only is the path to the scans not included, the suffix indicating
        the state of the data, unproc, is also removed leaving just the scan 'name'.
        """
        dir_list = self.available_functional_unproc_dir_fullpaths(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_functional_preproc_dir_fullpaths(self, subject_info):
        """Returns a list of full paths to preprocessed functional scan resources."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.FUNCTIONAL_SCAN_MARKER + '*' + self.PREPROC_SUFFIX)
        return sorted(dir_list)

    def diffusion_unproc_dir_fullpath(self, subject_info):
        """the full path to the unprocessed diffusion resource directory"""
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + 'Diffusion_' + self.UNPROC_SUFFIX

    def available_diffusion_unproc_dir_fullpaths(self, subject_info):
        """list of full paths to unprocessed diffusion scan resource directories"""
        dir_list = glob.glob(self.diffusion_unproc_dir_fullpath(subject_info))
        return sorted(dir_list)

    def does_diffusion_unproc_dir_exist(self, subject_info):
        return os.path.isdir(self.diffusion_unproc_dir_fullpath(subject_info))

    def diffusion_preproc_dir_fullpath(self, subject_info):
        """full path to preprocessed diffusion resource directory"""
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + 'Diffusion_' + self.PREPROC_SUFFIX

    def does_diffusion_preproc_dir_exist(self, subject_info):
        return os.path.isdir(self.diffusion_preproc_dir_fullpath(subject_info))

    def available_diffusion_preproc_dir_fullpaths(self, subject_info):
        """list of full paths to preprocessed diffusion resources."""
        dir_list = glob.glob(self.diffusion_preproc_dir_fullpath(subject_info))
        return sorted(dir_list)

    def diffusion_bedpostx_dir_fullpath(self, subject_info):
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + self.BEDPOSTX_PROCESSED_RESOURCE_NAME

    def available_diffusion_bedpostx_dir_fullpaths(self, subject_info):
        dir_list = glob.glob(self.diffusion_bedpostx_dir_fullpath(subject_info))
        return sorted(dir_list)

    def does_diffusion_bedpostx_dir_exist(self, subject_info):
        return os.path.isdir(self.diffusion_bedpostx_dir_fullpath(subject_info))

    def available_diffusion_unproc_names(self, subject_info):
        """list of scan names (not full paths) for unprocessed diffusion resources."""
        dir_list = self.available_diffusion_unproc_dir_fullpaths(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return sorted(name_list)

    def available_diffusion_scan_fullpaths(self, subject_info):
        """full paths to available diffusion scans"""
        dir_list = self.available_diffusion_unproc_dir_fullpaths(subject_info)
        scan_list = []

        for directory in dir_list:
            file_name_list = glob.glob(directory + '/*DWI*dir*.nii.gz')
            for file_name in file_name_list:
                if 'SBRef' not in file_name:
                    scan_list.append(file_name)

        return sorted(scan_list)

    def available_diffusion_scan_names(self, subject_info):
        """list of available diffusion scan names"""
        scan_path_list = self.available_diffusion_scan_fullpaths(subject_info)
        name_list = []
        for scan_path in scan_path_list:
            name_list.append(self._get_scan_file_name_from_path(scan_path))
        return sorted(name_list)

    def available_FIX_processed_dir_fullpaths(self, subject_info):
        """Returns a list of full paths to FIX processed scan resources."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.FUNCTIONAL_SCAN_MARKER + '*' + self.FIX_PROCESSED_SUFFIX)

        return_dir_list = []
        for path in dir_list:
            tokens = self._get_scan_name_from_path(path).split('_')
            if len(tokens) <= 3:
                return_dir_list.append(path)
        
        return sorted(return_dir_list)

    def available_MultiRun_FIX_processed_dir_fullpaths(self, subject_info):
        """Returns a list of full paths to Multi-Run FIX processed scan resources."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.FUNCTIONAL_SCAN_MARKER + '*' + self.FIX_PROCESSED_SUFFIX)

        return_dir_list = []
        for path in dir_list:
            tokens = self._get_scan_name_from_path(path).split('_')
            if len(tokens) > 3:
                return_dir_list.append(path)
                
        return sorted(return_dir_list)
    
    def available_task_processed_dir_fullpaths(self, subject_info):
        dir_list = []
        first_dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.TASK_SCAN_MARKER + '*')

        for directory in first_dir_list:
            lastsepindex = directory.rfind(os.sep)
            basename = directory[lastsepindex + 1:]
            index = basename.find(self.NAME_DELIMITER)
            rindex = basename.rfind(self.NAME_DELIMITER)
            if index == rindex:
                dir_list.append(directory)

        return sorted(dir_list)

    def available_FIX_processed_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available FIX processed scans."""
        dir_list = self.available_FIX_processed_dir_fullpaths(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_MultiRun_FIX_processed_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available Multi-Run FIX processed scans."""
        dir_list = self.available_MultiRun_FIX_processed_dir_fullpaths(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list
    
    def available_hand_reclassification_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available hand reclassifications for scans."""
        dir_list = self.available_hand_reclassification_dir_fullpaths(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_hand_reclassification_dir_fullpaths(self, subject_info):
        """Returns a list of full paths to hand reclassification resources for the scans."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.HAND_RECLASSIFICATION_SUFFIX)
        return sorted(dir_list)

    def available_FIX_processed_resting_state_dir_fullpaths(self, subject_info):
        """Returns a list of full paths to FIX processed resting state scan resources."""
        return_list = []
        dir_list = self.available_FIX_processed_dir_fullpaths(subject_info)
        for directory_path in dir_list:
            scan_name = self._get_scan_name_from_path(directory_path)
            if scan_name.startswith(self.RESTING_STATE_SCAN_MARKER):
                return_list.append(directory_path)

        return return_list

    def available_RSS_processed_dir_fullpaths(self, subject_info):
        """Returns a list of the full paths to RSS processed scan resources."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.RSS_PROCESSED_SUFFIX)
        return sorted(dir_list)

    # def available_reapplyfix_dir_fullpaths(self, subject_info):
    #     dir_list = glob.glob(self.subject_resources_dir_fullpath(subject_info) + '/*' +
    #                          self.REAPPLY_FIX_SUFFIX)
    #     return sorted(dir_list)

    def available_reapplyfix_dir_fullpaths(self, subject_info, reg_name=None):
        if reg_name is not None:
            dir_list = glob.glob(
                self.subject_resources_dir_fullpath(subject_info) + '/*' +
                self.REAPPLY_FIX_SUFFIX + reg_name)
        else:
            dir_list = glob.glob(
                self.subject_resources_dir_fullpath(subject_info) + '/*' +
                self.REAPPLY_FIX_SUFFIX)
        return sorted(dir_list)

    # def available_reapplyfix_names(self, subject_info):
    #     dir_list = self.available_reapplyfix_dir_fullpaths(subject_info)
    #     name_list = []
    #     for directory in dir_list:
    #         name_list.append(self._get_scan_name_from_path(directory))
    #     return name_list

    def available_reapplyfix_names(self, subject_info, reg_name=None):
        dir_list = self.available_reapplyfix_dir_fullpaths(subject_info, reg_name)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    # def reapplyfix_dir_fullpath(self, subject_info, scan_name):
    #     return self.subject_resources_dir_fullpath(subject_info) + os.sep + scan_name + \
    #         '_' + self.REAPPLY_FIX_SUFFIX

    def reapplyfix_dir_fullpath(self, subject_info, scan_name, reg_name=None):
        if reg_name is not None:
            return self.subject_resources_dir_fullpath(subject_info) + os.sep + scan_name + \
                '_' + self.REAPPLY_FIX_SUFFIX + reg_name
        else:
            return self.subject_resources_dir_fullpath(subject_info) + os.sep + scan_name + \
                '_' + self.REAPPLY_FIX_SUFFIX

    def available_handreclassification_dir_fullpaths(self, subject_info):
        """Returns a list of the full paths to the hand reclassification resources."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.HAND_RECLASSIFICATION_SUFFIX)
        return sorted(dir_list)

    def available_apply_handreclassification_dir_fullpaths(self, subject_info):
        """Returns a list of the full paths to the applied hand reclassification resources."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.APPLY_HAND_RECLASSIFICATION_SUFFIX)
        return sorted(dir_list)

    def apply_handreclassification_dir_fullpath(self, subject_info, scan_name):
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + scan_name + \
            '_' + self.APPLY_HAND_RECLASSIFICATION_SUFFIX

    def available_apply_handreclassification_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available apply handreclassification scans."""
        dir_list = self.available_apply_handreclassification_dir_fullpaths(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_msmall_reg_dir_fullpaths(self, subject_info):
        dir_list = glob.glob(self.subject_resources_dir_fullpath(subject_info) + '/MSMAllReg')
        return sorted(dir_list)

    def available_RSS_processed_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available RSS processed scans."""
        dir_list = self.available_RSS_processed_dir_fullpaths(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def _get_scan_name_from_path(self, path):
        short_path = os.path.basename(path)
        last_char = short_path.rfind(self.NAME_DELIMITER)
        name = short_path[:last_char]
        return name

    def _get_session_name_from_path(self, directory):
        short_path = os.path.basename(directory)
        return short_path

    def _get_subject_id_from_session_name(self, session_name):
        last_char = session_name.rfind(self.NAME_DELIMITER)
        subject_id = session_name[:last_char]
        return subject_id

    def _get_scan_file_name_from_path(self, scan_path):
        file_name = os.path.basename(scan_path)
        return file_name

    def available_functional_preproc_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available preprocessed
        functional resources."""
        dir_list = self.available_functional_preproc_dir_fullpaths(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

# ICI name changes to methods from here down are needed for consistency

    def does_functional_unproc_exist(self, subject_info, scan_name):
        return scan_name in self.available_functional_unproc_names(subject_info)

    def does_functional_preproc_exist(self, subject_info, scan_name):
        """Returns True if there is a functional preproc resource available for
        the specified scan name.
        """
        # _inform("subject_info: " + str(subject_info))
        # _inform("scan_name: " + scan_name)
        # _inform("self.available_functional_preproc_names(subject_info): " +
        #         str(self.available_functional_preproc_names(subject_info)))

        return scan_name in self.available_functional_preproc_names(subject_info)

    def functionally_preprocessed(self, subject_info, scan_name):
        """Returns True if the specified scan has been functionally preprocessed
        for the specified subject.
        """

        # NOTE: This should be overridden in a subclass to do more than simply check
        #       to see if the resource exists. It needs to also do the check to see
        #       if all the appropriate files exist.
        _inform("functionally_preprocessed method of HcpArchive class being called.")
        _inform("This method should be overridden in a subclass to do a more ")
        _inform("appropriate check.")
        return self.does_functional_preproc_exist(subject_info, scan_name)

    def DeDriftAndResample_processed_dir_name(self, subject_info):
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + self.DEDRIFT_AND_RESAMPLE_RESOURCE_NAME

    def available_DeDriftAndResample_processed_dirs(self, subject_info):
        """Returns a list of full paths to DeDriftAndResample processed scan resources"""
        dir_list = glob.glob(self.DeDriftAndResample_processed_dir_name(subject_info))
        return sorted(dir_list)

    def available_PostFix_processed_dirs(self, subject_info):
        """Returns a list of full paths to PostFix processed scan resources"""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.FUNCTIONAL_SCAN_MARKER + '*' + self.POSTFIX_PROCESSED_SUFFIX)
        return sorted(dir_list)

    def available_PostFix_processed_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available PostFix processed scans."""
        dir_list = self.available_PostFix_processed_dirs(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def scan_PostFix_resource_name(self, scan):
        return scan + '_' + self.POSTFIX_PROCESSED_SUFFIX

    def RSS_processed_dir_fullpath(self, subject_info, scan):
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + scan + '_' + self.RSS_PROCESSED_SUFFIX

    def scan_PostFix_resource_dir(self, subject_info, scan):
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + self.scan_PostFix_resource_name(scan)

#    def DeDrift_processed_resource_name(self):
#        return 'MSMAllDeDrift'

    def FIX_processed_resource_name(self, scan_name):
        return scan_name + self.NAME_DELIMITER + self.FIX_PROCESSED_SUFFIX

    def does_FIX_processed_exist(self, subject_info, scan_name):
        """Returns True if there is a FIX processed resource available for the specified
        scan name."""
        return scan_name in self.available_FIX_processed_names(subject_info)

    def FIX_processed_dir_fullpath(self, subject_info, scan_name):
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + self.FIX_processed_resource_name(scan_name)
    
    def does_hand_reclassification_exist(self, subject_info, scan_name):
        """Returns True if there is a hand reclassification resource available for the specified
        scan name."""
        return scan_name in self.available_hand_reclassification_names(subject_info)

    def PostFix_processed_resource_name(self, scan_name):
        return scan_name + self.NAME_DELIMITER + self.POSTFIX_PROCESSED_SUFFIX

    def does_PostFix_processed_resource_exist(self, subject_info, scan_name):
        """Returns True if there is a PostFix resource available for the specified
        scan name."""
        return scan_name in self.available_PostFix_processed_names(subject_info)

#    def FIX_processed(self, subject_info, scan_name):
#        return self.FIX_processing_complete(subject_info, scan_name)

    def FIX_processing_complete(self, subject_info, scan_name):
        """Returns True if the specified scan has been FIX processed for the specified subject."""

        # NOTE: This needs to be overridden in a subclass to do more than simply check
        #       to see if the resource exists. It needs to also do the check to see
        #       if all the appropriate files exist.
        _inform("FIX_processing_complete method of HcpArchive class being called.")
        _inform("This method should be overridden in a subclass to do")
        _inform("a more appropriate check.")
        return self.does_FIX_processed_exist(subject_info, scan_name)

    # def PostFix_processing_complete(self, subject_info, scan_name):
    #     """Returns True if the specified scan has completed PostFix processing for the specified subject."""

    #     # NOTE: This needs to be overridden in a subclass to do more than simply check
    #     #       to see if the resource exists. It needs to also do the check to see
    #     #       if all the appropriate files exist.
    #     _inform("PostFix_processing_complete method of HcpArchive class being called.")
    #     _inform("This method should be overriden in a subclass to do")
    #     _inform("a more appropriate check.")
    #     return self.does_PostFix_processed_resource_exist(subject_info, scan_name)

    def is_resting_state_scan_name(self, scan_name):
        return scan_name.startswith(self.RESTING_STATE_SCAN_MARKER)

    def is_task_scan_name(self, scan_name):
        return scan_name.startswith(self.TASK_SCAN_MARKER)

    def available_structural_unproc_dir_fullpaths(self, subject_info):
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + os.sep +
            'T[12]w_' + '*' + self.UNPROC_SUFFIX)
        return sorted(dir_list)

    def does_structural_preproc_dir_exist(self, subject_info):
        return os.path.isdir(self.structural_preproc_dir_fullpath(subject_info))

    def structural_preproc_dir_fullpath(self, subject_info):
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + 'Structural_' + self.PREPROC_SUFFIX

    def available_structural_preproc_dir_fullpaths(self, subject_info):
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + os.sep +
            'Structural' + '_' + self.PREPROC_SUFFIX)
        return sorted(dir_list)

    def available_resting_state_preproc_dirs(self, subject_info):
        """Returns a list of full paths to functionally preprocessed resting state scan resources."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.RESTING_STATE_SCAN_MARKER + '*' + self.PREPROC_SUFFIX)
        return sorted(dir_list)

    def available_resting_state_preproc_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available preprocessed resting
        state scan resources."""
        dir_list = self.available_resting_state_preproc_dirs(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def available_task_preproc_dirs(self, subject_info):
        """Returns a list of full paths to functionally preprocessed task scan resources."""
        dir_list = glob.glob(
            self.subject_resources_dir_fullpath(subject_info) + '/*' +
            self.TASK_SCAN_MARKER + '*' + self.PREPROC_SUFFIX)
        return sorted(dir_list)

    def available_task_preproc_names(self, subject_info):
        """Returns a list of scan names (not full paths) of available preprocessed task
        scan resources."""
        dir_list = self.available_task_preproc_dirs(subject_info)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_scan_name_from_path(directory))
        return name_list

    def functional_scan_prefix(self, functional_scan_name):
        """Extracts and returns the 'prefix' part of a functional scan name.

        :Example:

        functional_scan_prefix('rfMRI_REST3_PA') returns 'rfMRI'
        """
        (prefix, base_name, pe_dir) = functional_scan_name.split(self.NAME_DELIMITER)
        return prefix

    def functional_scan_base_name(self, functional_scan_name):
        """Extracts and returns the 'base_name' part of a functional scan name.

        :Example:

        functional_scan_base_name('rfMRI_REST3_PA') returns 'REST3'
        """
        (prefix, base_name, pe_dir) = functional_scan_name.split(self.NAME_DELIMITER)
        return base_name

    def functional_scan_pe_dir(self, functional_scan_name):
        """Extracts and returns the phase encoding direction, 'pe_dir', part of a functional scan name.

        :Example:

        functional_scan_pe_dir('rfMRI_REST3_PA') returns 'PA'
        """
        (prefix, base_name, pe_dir) = functional_scan_name.split(self.NAME_DELIMITER)
        return pe_dir

    def available_session_dirs(self, project_name):
        """Returns list of full paths to available sessions for a project."""
        dir_list = glob.glob(self.project_archive_root(project_name) + '/*_' + self.TESLA_SPEC)
        return sorted(dir_list)

    def available_session_names(self, project_name):
        """Returns a list of session names (not full paths) for a project."""
        dir_list = self.available_session_dirs(project_name)
        name_list = []
        for directory in dir_list:
            name_list.append(self._get_session_name_from_path(directory))
        return name_list

    def available_subject_ids(self, project_name):
        """Returns a list of subject ids for a project."""
        session_name_list = self.available_session_names(project_name)
        id_list = []
        for session_name in session_name_list:
            id_list.append(self._get_subject_id_from_session_name(session_name))
        return id_list

    def subject_count(self, project_name):
        """Returns the number of available subjects for a project."""
        id_list = self.available_subject_ids(project_name)
        return len(id_list)


def _simple_interactive_demo():
    _inform("hcp_archive.HcpArchive class is Abstract")
    _inform("No instance can be created on which to demonstrate functionality")


if __name__ == '__main__':
    _simple_interactive_demo()
