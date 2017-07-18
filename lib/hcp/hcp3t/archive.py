#!/usr/bin/env python3

"""hcp/hcp3t/archive.py: Provide direct access to an HCP 3T project archive."""

# import of built-in modules
import glob
import os


# import of third party modules
# None


# import of local modules
import hcp.archive as hcp_archive
import hcp.hcp3t.subject as hcp3t_subject


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


class Hcp3T_Archive(hcp_archive.HcpArchive):
    """This class provides access to an HCP 3T project data archive.

    This access goes 'behind the scenes' and uses the actual underlying file
    system and assumes a particular organization of directories, resources, and
    file naming conventions. Because of this, a change in XNAT implementation
    or a change in conventions could cause this code to no longer be correct.
    """

    @property
    def TESLA_SPEC(self):
        """String to indicate the tesla rating of the scanner used."""
        return '3T'

    @property
    def SESSION_CLASSIFIER(self):
        return self.TESLA_SPEC
	
    def __init__(self):
        """Constructs an Hcp3T_Archive object."""
        super().__init__()

    def available_supplemental_structural_preproc_dir_fullpaths(self, subject_info):
        dir_list = glob.glob(self.subject_resources_dir_fullpath(subject_info) + os.sep +
                             'Structural' + '_' + self.PREPROC_SUFFIX + '_supplemental')
        return sorted(dir_list)

    def bedpostx_dir_fullpath(self, subject_info):
        return self.subject_resources_dir_fullpath(subject_info) + os.sep + 'Diffusion_bedpostx'

    def available_bedpostx_fullpaths(self, subject_info):
        dir_list = glob.glob(self.bedpostx_dir_fullpath(subject_info))
        return sorted(dir_list)

def _simple_interactive_demo():

    archive = Hcp3T_Archive()

    _inform("archive.FUNCTIONAL_SCAN_MARKER: " + archive.FUNCTIONAL_SCAN_MARKER)
    _inform("archive.RESTING_STATE_SCAN_MARKER: " + archive.RESTING_STATE_SCAN_MARKER)
    _inform("archive.TASK_SCAN_MARKER: " + archive.TASK_SCAN_MARKER)
    _inform("archive.UNPROC_SUFFIX: " + archive.UNPROC_SUFFIX)
    _inform("archive.PREPROC_SUFFIX: " + archive.PREPROC_SUFFIX)
    _inform("archive.FIX_PROCESSED_SUFFIX: " + archive.FIX_PROCESSED_SUFFIX)
    _inform("archive.NAME_DELIMITER: " + archive.NAME_DELIMITER)
    _inform("archive.TESLA_SPEC: " + archive.TESLA_SPEC)
    _inform("archive.build_home: " + archive.build_home)

    subject_info = hcp3t_subject.Hcp3TSubjectInfo('HCP_500', '100307')
    _inform("created subject_info: " + str(subject_info))
    _inform("archive.session_name(subject_info): " + archive.session_name(subject_info))
    _inform("archive.session_dir_fullpath(subject_info): " + archive.session_dir_fullpath(subject_info))
    _inform("archive.subject_resources_dir_fullpath(subject_info): " +
            archive.subject_resources_dir_fullpath(subject_info))

    _inform("")
    _inform("Available functional unproc dirs: ")
    for directory in archive.available_functional_unproc_dir_fullpaths(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available functional unproc scan names: ")
    for name in archive.available_functional_unproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Available diffusion unproc dirs: ")
    for directory in archive.available_diffusion_unproc_dir_fullpaths(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available diffusion unproc scan names: ")
    for name in archive.available_diffusion_unproc_names(subject_info):
        _inform(name)

    _inform("")
    _inform("Available functional preproc dirs: ")
    for directory in archive.available_functional_preproc_dir_fullpaths(subject_info):
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
    for directory in archive.available_FIX_processed_dir_fullpaths(subject_info):
        _inform(directory)

    _inform("")
    _inform("Available FIX processed scan names: ")
    for name in archive.available_FIX_processed_names(subject_info):
        _inform(name)

#    _inform("")
#    _inform("Are the following functional scans FIX processed")
#    for name in archive.available_functional_unproc_names(subject_info):
#        _inform('scan name: ' + name + ' ' + '\tFIX processed: ' +
#              str(archive.FIX_processed(subject_info, name)))

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
    _inform("Available functional unprocessed scan names: ")
    for name in archive.available_functional_unproc_names(subject_info):
        _inform(name + '\t' +
                '\tprefix: ' + archive.functional_scan_prefix(name) +
                '\tbase_name: ' + archive.functional_scan_base_name(name) +
                '\tpe_dir: ' + archive.functional_scan_pe_dir(name))

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
    for scan in archive.available_diffusion_scan_fullpaths(subject_info):
        _inform(scan)

    _inform("")
    _inform("Available diffusion scan names: ")
    for scan_name in archive.available_diffusion_scan_names(subject_info):
        _inform(scan_name)


if __name__ == '__main__':
    _simple_interactive_demo()
