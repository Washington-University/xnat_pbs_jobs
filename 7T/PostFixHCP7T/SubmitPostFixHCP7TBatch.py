#!/usr/bin/env python3

"""SubmitPostFixHCP7TBatch.py: Submit a batch of PostFix processing jobs for the HCP 7T project."""

# import of built-in modules
import getpass
import os
import sys

# import of third party modules
# None

# import of local modules
import PostFixHCP7T_OneSubjectJobSubmitter
import hcp.batch_submitter as batch_submitter
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user of this program by outputing a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)


class PostFixHcp7TBatchSubmitter(batch_submitter.BatchSubmitter):
    """This class submits batches of PostFix processing jobs for the HCP 7T project."""

    def __init__(self):
        """Construct a PostFixHcp7TBatchSubmitter"""
        super().__init__(hcp7t_archive.Hcp7T_Archive())
        self._one_subject_submitter = PostFixHCP7T_OneSubjectJobSubmitter.PostFixHCP7T_OneSubjectJobSubmitter(
            self._archive, self._archive.build_home)

    def submit_jobs(self, subject_list):
        """Submit a batch of PostFix processing jobs."""

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

            if config.get_value(subject.subject_id, 'CleanOutputFirst') == 'True':
                clean_output_first = True
            else:
                clean_output_first = False

            wall_time_limit = int(config.get_value(subject.subject_id, 'WalltimeLimit'))
            vmem_limit = int(config.get_value(subject.subject_id, 'VmemLimit'))
            mem_limit = 'UNSPECIFIED'

            scan = subject.extra

            _inform("")
            _inform("--------------------------------------------------------------------------------")
            _inform(" Submitting PostFixHCP7T jobs for: ")
            _inform("            project: " + subject.project)
            _inform("            subject: " + subject.subject_id)
            _inform("               scan: " + scan)
            _inform("         put_server: " + put_server)
            _inform("         setup_file: " + setup_file)
            _inform(" clean_output_first: " + str(clean_output_first))
            _inform("    wall_time_limit: " + str(wall_time_limit))
            _inform("          mem_limit: " + str(mem_limit))
            _inform("         vmem_limit: " + str(vmem_limit))
            _inform("--------------------------------------------------------------------------------")

            # figure out the specification of the scan(s) to process and whether to only
            # process incomplete scans
            if scan == 'all':
                # want to run them all without regard to whether they are previously complete
                scan_spec = None
                incomplete_only = False
            elif scan == 'incomplete':
                # want to look at all of them and run only those that are incomplete
                scan_spec = None
                incomplete_only = True
            else:
                # want to run this specific one without regard to whether it is previously complete
                scan_spec = scan
                incomplete_only = False

            # Use the "one subject submitter" to submit the jobs for the current subject
            self._one_subject_submitter.submit_jobs(
                userid, password, 'https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                subject.project, subject.subject_id, subject.subject_id + '_7T',
                subject.structural_reference_project, subject.subject_id + '_3T',
                put_server, clean_output_first, setup_file,
                incomplete_only, scan_spec,
                wall_time_limit, mem_limit, vmem_limit)
            self.increment_shadow_number


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
    submitter = PostFixHcp7TBatchSubmitter()
    submitter.submit_jobs(subject_list)
