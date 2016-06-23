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
sys.path.append('../lib')
import hcp7t_subject
import hcp7t_archive

import SubmitIcaFixProcessingHCP7TOneSubject

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

        for subject in subject_list:
            put_server = 'http://db-shadow' + str(self._current_shadow_number) + '.nrg.mir:8080'

            scan = subject.extra

            inform("")
            inform("--------------------------------------------------------------------------------")
            inform(" Submitting IcaFixProcessingHCP7T jobs for: ")
            inform("      project: " + subject.project )
            inform("   refproject: " + subject.structural_reference_project )
            inform("      subject: " + subject.subject_id )
            inform("         scan: " + scan )
            inform("   put_server: " + put_server )
            inform("--------------------------------------------------------------------------------")

            setup_file = scripts_home + os.sep + 'SetUpHCPPipeline_IcaFixProcessingHCP7T.sh'
            clean_output_first = False

            if scan == 'all':
                scan_spec = None
                incomplete_only = False
            elif scan == 'incomplete':
                scan_spec = None
                incomplete_only = True
            else:
                scan_spec = scan

            self._one_subject_submitter.submit_jobs(userid, password, 'https://db.humanconnectome.org',
                                                    subject.project, subject.subject_id, subject.subject_id + '_7T',
                                                    subject.structural_reference_project, subject.subject_id + '_3T',
                                                    put_server, clean_output_first, setup_file, 
                                                    incomplete_only, scan_spec)

            # cmd = home + os.sep + 'pipeline_tools' + os.sep + 'xnat_pbs_jobs' + os.sep + '7T' + os.sep + 'IcaFixProcessingHCP7T' + os.sep + 'SubmitIcaFixProcessingHCP7T.OneSubject.sh'
            # cmd += ' --user=' + userid
            # cmd += ' --password=' + password
            # cmd += ' --put-server=' + server
            # cmd += ' --project=' + subject.project
            # cmd += ' --subject=' + subject.subject_id
            # cmd += ' --structural-reference-project=' + subject.structural_reference_project
            # cmd += ' --structural-reference-session=' + subject.structural_reference_project + '_3T'
            # cmd += ' --setup-script=' + setup_file
        
            # if scan == 'all':
            #     pass

            # elif scan == 'incomplete':
            #     cmd += ' --incomplete-only'

            # else:
            #     cmd += ' --scan=' + scan

            # subprocess.run(cmd, shell=True, check=True)

            self.increment_shadow_number


if __name__ == "__main__":

    # Get environment variables
    subject_files_dir = os.getenv('SUBJECT_FILES_DIR')

    if subject_files_dir == None:
        inform('Environment variable SUBJECT_FILES_DIR must be set!')
        sys.exit(1)

    scripts_home = os.getenv('SCRIPTS_HOME')

    if scripts_home == None:
        inform('Environment variable SCRIPTS_HOME must be set!')
        sys.exit(1)

    home = os.getenv('HOME')

    if home == None:
        inform('Environment variable HOME must be set!')
        sys.exit(1)

    # Get Connectome DB credentials
    userid = input('Connectome DB Username: ')
    password = getpass.getpass('Connectome DB Password: ')

    # Get list of subjects to process
    subject_file_name = subject_files_dir + os.sep + 'IcaFixProcessingHCP7T.subjects'
    inform('Retrieving subject list from: ' + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Process subjects in list
    submitter = IcaFix7TBatchSubmitter()

    submitter.submit_jobs(subject_list)
