#!/usr/bin/env python3

"""SubmitDeDriftAndResampleHCP7T_HighResBatch.py: Submit a batch of
DeDriftAndResampleHCP7T_HighRes processing jobs for the HCP 7T project."""

# import of built-in modules
import getpass
import os
import sys
import time

# import of third party modules
# None

# import of local modules
import DeDriftAndResampleHCP7T_HighRes_OneSubjectJobSubmitter
import hcp.batch_submitter as batch_submitter
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016-2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user of this program by outputing a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)


def _debug(msg):
    # debug_msg = "DEBUG: " + msg
    # _inform(debug_msg)
    pass


class DeDriftAndResampleHcp7T_HighResBatchSubmitter(batch_submitter.BatchSubmitter):
    """This class submits batches of DeDriftAndResampleHCP7T_HighRes processing jobs."""

    def __init__(self):
        """Construct a DeDriftAndResampleHcp7T_HighResBatchSubmitter"""
        super().__init__(hcp7t_archive.Hcp7T_Archive())

    def submit_jobs(self, subject_list):
        """Submit a batch of jobs."""

        # read configuration file
        config_file_name = file_utils.get_config_file_name(__file__)

        _inform("")
        _inform("--------------------------------------------------------------------------------")
        _inform("Reading configuration from file: " + config_file_name)

        config = my_configparser.MyConfigParser()
        config.read(config_file_name)

        # submit jobs for listed subjects
        for subject in subject_list:

            put_server = 'http://db-shadow' + str(self.shadow_number) + '.nrg.mir:8080'

            # get information for subject from configuration file
            setup_file = scripts_home + os.sep + config.get_value(subject.subject_id, 'SetUpFile')
            clean_output_first = config.get_bool_value(subject.subject_id, 'CleanOutputFirst')
            wall_time_limit = config.get_int_value(subject.subject_id, 'WalltimeLimit')
            vmem_limit = config.get_int_value(subject.subject_id, 'VmemLimit')
            mem_limit = config.get_int_value(subject.subject_id, 'MemLimit')

            _inform("")
            _inform("--------------------------------------------------------------------------------")
            _inform(" Submitting DeDriftAndResampleHCP7T_HighRes jobs for: ")
            _inform("            project: " + subject.project)
            _inform("         refproject: " + subject.structural_reference_project)
            _inform("            subject: " + subject.subject_id)
            _inform("         put_server: " + put_server)
            _inform("         setup_file: " + setup_file)
            _inform(" clean_output_first: " + str(clean_output_first))
            _inform("    wall_time_limit: " + str(wall_time_limit))
            _inform("         vmem_limit: " + str(vmem_limit))
            _inform("          mem_limit: " + str(mem_limit))
            _inform("--------------------------------------------------------------------------------")

            _debug("Create and configure an appropriate 'one subject submitter'")
            one_subject_submitter = DeDriftAndResampleHCP7T_HighRes_OneSubjectJobSubmitter.DeDriftAndResampleHCP7T_HighRes_OneSubjectJobSubmitter(
                self._archive, self._archive.build_home)
            _debug("one_subject_submitter: " + str(one_subject_submitter))

            one_subject_submitter.username = userid
            one_subject_submitter.password = password
            one_subject_submitter.server = 'https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER')
            one_subject_submitter.project = subject.project
            one_subject_submitter.subject = subject.subject_id
            one_subject_submitter.session = subject.subject_id + '_7T'
            one_subject_submitter.structural_reference_project = subject.structural_reference_project
            one_subject_submitter.structural_reference_session = subject.subject_id + '_3T'
            one_subject_submitter.put_server = put_server
            one_subject_submitter.clean_output_resource_first = clean_output_first
            one_subject_submitter.setup_script = setup_file
            one_subject_submitter.walltime_limit_hours = wall_time_limit
            one_subject_submitter.vmem_limit_gbs = vmem_limit
            one_subject_submitter.mem_limit_gbs = mem_limit

            _debug("Use the 'one subject submitter' to submit the jobs for the current subject")
            one_subject_submitter.submit_jobs()

            self.increment_shadow_number()

            time.sleep(60)
            

if __name__ == "__main__":

    # Get environment variables
    scripts_home = os.getenv('SCRIPTS_HOME')
    if scripts_home is None:
        _inform("Environment variable SCRIPTS_HOME must be set!")
        sys.exit(1)

    home = os.getenv('HOME')
    if home is None:
        _inform("Environment variable HOME must be set!")
        sys.exit(1)

    # Get Connectome DB credentials
    userid = input("Connectome DB Username: ")
    password = getpass.getpass("Connectome DB Password: ")

    # Get list of subjects to process
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    _inform('Retrieving subject list from: ' + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Process subjects in list
    batch_submitter = DeDriftAndResampleHcp7T_HighResBatchSubmitter()
    batch_submitter.submit_jobs(subject_list)
