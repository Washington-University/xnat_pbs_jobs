#!/usr/bin/env python3

"""SubmitIcaFixProcessingHCP7TBatch.py: Submit a batch of ICA+FIX processing jobs for the HCP 7T project."""

# import of built-in modules
import os
import sys
import getpass
import random
import subprocess

# import of third party modules
pass

# path changes and import of local modules
import hcp.hcp7t.subject as hcp7t_subject
import hcp.hcp7t.archive as hcp7t_archive
import utils.my_configparser as my_configparser

import SubmitIcaFixProcessingHCP7TOneSubject


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

class IcaFix7TBatchSubmitter:
    """This class submits batches of ICA+FIX processing jobs for the HCP 7T project."""

    @property
    def START_SHADOW_NUMBER(self):
        """Starting ConnectomeDB shadow server number."""
        return 1

    @property
    def MAX_SHADOW_NUMBER(self):
        """Maximum ConnectomeDB shadow server number."""
        return 8

    def __init__(self):
        """Construct an IcaFix7TBatchSubmitter"""
        self._current_shadow_number = random.randint(self.START_SHADOW_NUMBER, self.MAX_SHADOW_NUMBER)
        self._archive = hcp7t_archive.Hcp7T_Archive()
        self._one_subject_submitter = SubmitIcaFixProcessingHCP7TOneSubject.IcaFix7TOneSubjectSubmitter(self._archive, self._archive.build_home)

    @property
    def shadow_number(self):
        """shadow number"""
        return self._current_shadow_number

    def increment_shadow_number(self):
        """Increments the current shadow_number and cycles it around if it goes past the maximum."""
        self._current_shadow_number = self._current_shadow_number + 1
        if self._current_shadow_number > self.MAX_SHADOW_NUMBER:
            self._current_shadow_number = self.START_SHADOW_NUMBER
        
    def submit_jobs(self, subject_list):
        """Submit a batch of ICA+FIX processing jobs.

        :param subject_list: list of subject specifications for which to submit jobs
        :type subject_list: list of Hcp7TSubjectInfo objects
        """

        # read configuration file
        config_file_name = os.path.basename(__file__)
        if config_file_name.endswith('.py'):
            config_file_name = config_file_name[:-3]
        config_file_name += '.ini'
        
        _inform("")
        _inform("--------------------------------------------------------------------------------")
        _inform("Reading configuration from file: " + config_file_name)

        config = my_configparser.MyConfigParser()
        config.read(config_file_name)

        # submit jobs for listed subjects
        for subject in subject_list:

            put_server = 'http://db-shadow' + str(self._current_shadow_number) + '.nrg.mir:8080'

            # get information for subject from configuration file
            setup_file = scripts_home + os.sep + config.get_value(subject.subject_id, 'SetUpFile')
            clean_output_first = bool(config.get_value(subject.subject_id, 'CleanOutputFirst'))
            wall_time_limit = int(config.get_value(subject.subject_id, 'WalltimeLimit'))
            mem_limit = int(config.get_value(subject.subject_id, 'MemLimit'))
            vmem_limit = int(config.get_value(subject.subject_id, 'VmemLimit'))

            scan = subject.extra

            _inform("")
            _inform("--------------------------------------------------------------------------------")
            _inform(" Submitting IcaFixProcessingHCP7T jobs for: ")
            _inform("            project: " + subject.project )
            _inform("         refproject: " + subject.structural_reference_project )
            _inform("            subject: " + subject.subject_id )
            _inform("               scan: " + scan )
            _inform("         put_server: " + put_server )
            _inform("         setup_file: " + setup_file )
            _inform(" clean_output_first: " + str(clean_output_first) )
            _inform("    wall_time_limit: " + str(wall_time_limit) )
            _inform("          mem_limit: " + str(mem_limit) )
            _inform("         vmem_limit: " + str(vmem_limit) )
            _inform("--------------------------------------------------------------------------------")

            # figure out the specification of the scan(s) to process and whether
            # to only process incomplete scans
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
            self._one_subject_submitter.submit_jobs(userid, password, 'https://db.humanconnectome.org',
                                                    subject.project, subject.subject_id, subject.subject_id + '_7T',
                                                    subject.structural_reference_project, subject.subject_id + '_3T',
                                                    put_server, clean_output_first, setup_file, 
                                                    incomplete_only, scan_spec, 
                                                    wall_time_limit, mem_limit, vmem_limit)
            self.increment_shadow_number


if __name__ == "__main__":

    # Get environment variables
    subject_files_dir = os.getenv('SUBJECT_FILES_DIR')

    if subject_files_dir == None:
        _inform("Environment variable SUBJECT_FILES_DIR must be set!")
        sys.exit(1)

    scripts_home = os.getenv('SCRIPTS_HOME')

    if scripts_home == None:
        _inform("Environment variable SCRIPTS_HOME must be set!")
        sys.exit(1)

    home = os.getenv('HOME')

    if home == None:
        _inform("Environment variable HOME must be set!")
        sys.exit(1)

    # Get Connectome DB credentials
    userid = input("Connectome DB Username: ")
    password = getpass.getpass("Connectome DB Password: ")

    # Get list of subjects to process
    subject_file_name = subject_files_dir + os.sep + 'IcaFixProcessingHCP7T.subjects'
    _inform('Retrieving subject list from: ' + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Process subjects in list
    submitter = IcaFix7TBatchSubmitter()

    submitter.submit_jobs(subject_list)
