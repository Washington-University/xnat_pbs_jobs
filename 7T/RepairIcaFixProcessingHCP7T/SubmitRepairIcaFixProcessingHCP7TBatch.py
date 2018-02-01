#!/usr/bin/env python3

# import of built-in modules
import getpass
import os
import sys

# import of third party modules

# import of local modules
import SubmitRepairIcaFixProcessingHCP7TOneSubject
import hcp.batch_submitter as batch_submitter
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2018, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    print(os.path.basename(__file__) + ": " + msg)


class RepairIcaFixProcessing7TBatchSubmitter(batch_submitter.BatchSubmitter):

    def __init__(self):
        super().__init__(hcp7t_archive.Hcp7T_Archive())
        self._one_subject_submitter = SubmitRepairIcaFixProcessingHCP7TOneSubject.RepairIcaFixProcessing7TOneSubjectJobSubmitter(
            self._archive, self._archive.build_home)

        self._current_shadow_number = 2

    def increment_shadow_number(self):
        self._current_shadow_number += 1
        if self._current_shadow_number > 8:
            self._current_shadow_number = 2

    def submit_jobs(self, subject_list):
        # read configuration file
        config_file_name = file_utils.get_config_file_name(__file__)

        _inform("")
        _inform("--------------------------------------------------------------------------------")
        _inform("Reading configuration from file: " + config_file_name)

        config = my_configparser.MyConfigParser()
        config.read(config_file_name)

        # submit jobs for listed subjects
        for subject in subject_list:

            put_server = 'http://db-shadow' + str(self._current_shadow_number) + '.nrg.mir:8080'

            setup_file = scripts_home + os.sep + config.get_value(subject.subject_id, 'SetUpFile')

            wall_time_limit = int(config.get_value(subject.subject_id, 'WalltimeLimit'))
            mem_limit = int(config.get_value(subject.subject_id, 'MemLimit'))
            vmem_limit = int(config.get_value(subject.subject_id, 'VmemLimit'))

            scan = subject.extra

            _inform("")
            _inform("--------------------------------------------------------------------------------")
            _inform(" Submitting RepairIcaFixProcessingHCP7T jobs for: ")
            _inform("            project: " + subject.project )
            _inform("         refproject: " + subject.structural_reference_project )
            _inform("            subject: " + subject.subject_id )
            _inform("               scan: " + scan )
            _inform("         put_server: " + put_server )
            _inform("         setup_file: " + setup_file )
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
            self._one_subject_submitter.submit_jobs(
                userid, password, 'https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                subject.project, subject.subject_id, subject.subject_id + '_7T',
                subject.structural_reference_project, subject.subject_id + '_3T',
                put_server, setup_file, 
                incomplete_only, scan_spec, 
                wall_time_limit, mem_limit, vmem_limit)
            
            self.increment_shadow_number()
                
if __name__ == "__main__":

    scripts_home = os_utils.getenv_required('SCRIPTS_HOME')
    home = os_utils.getenv_required('HOME')

    # Get Connectome DB credentials
    userid = input("Connectome DB Username: ")
    password = getpass.getpass("Connectome DB Password: ")

    # Get list of subjects to process
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    _inform('Retrieving subject list from: ' + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Process subjects in list
    submitter = RepairIcaFixProcessing7TBatchSubmitter()
    submitter.submit_jobs(subject_list)
