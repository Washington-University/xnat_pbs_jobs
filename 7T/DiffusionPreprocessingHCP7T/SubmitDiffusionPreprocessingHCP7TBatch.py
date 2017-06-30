#!/usr/bin/env python3

"""
SubmitDiffusionPreprocessingHCP7TBatch.py: Submit a batch of
DiffusionPreprocessingHCP7T jobs for the HCP 7T project
"""

# import of built-in modules
import getpass
import os
import sys

# import of third party modules
# None

# import of local modules
import hcp.batch_submitter as batch_submitter
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.diffusion_preprocessing.one_subject_job_submitter as one_subject_job_submitter
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    print(os.path.basename(__file__) + ": " + msg)


def _debug(msg):
    # debug_msg = "DEBUG: " + msg
    # _inform(debug_msg)
    pass


class BatchSubmitter(batch_submitter.BatchSubmitter):

    def __init__(self):
        super().__init__(hcp7t_archive.Hcp7T_Archive())

    def submit_jobs(self, subject_list):

        # Read the configuration file
        config_file_name = file_utils.get_config_file_name(__file__)
        _inform("Reading configuration from file: " + config_file_name)

        config = my_configparser.MyConfigParser()
        config.read(config_file_name)

        # Submit jobs for listed subjects
        for subject in subject_list:

            put_server = 'http://db-shadow' + str(self.get_and_inc_shadow_number()) + '.nrg.mir:8080'

            # get information for subject from the configuration file
            setup_file = xnat_pbs_jobs_home + os.sep + config.get_value(subject.subject_id, 'SetUpFile')
            clean_output_first = config.get_bool_value(subject.subject_id, 'CleanOutputFirst')
            pre_eddy_walltime_limit_hrs = config.get_int_value(subject.subject_id, 'PreEddyWalltimeLimit')
            pre_eddy_vmem_limit_gbs = config.get_int_value(subject.subject_id, 'PreEddyVmemLimit')
            eddy_walltime_limit_hrs = config.get_int_value(subject.subject_id, 'EddyWalltimeLimit')
            post_eddy_walltime_limit_hrs = config.get_int_value(subject.subject_id, 'PostEddyWalltimeLimit')
            post_eddy_vmem_limit_gbs = config.get_int_value(subject.subject_id, 'PostEddyVmemLimit')

            _inform("")
            _inform("--------------------------------------------------------------------------------")
            _inform(" Submitting DiffusionPreprocessingHCP7T jobs for:")
            _inform("            project: " + subject.project)
            _inform("         refproject: " + subject.structural_reference_project)
            _inform("            subject: " + subject.subject_id)
            _inform("         put_server: " + put_server)
            _inform("         setup_file: " + setup_file)
            _inform(" clean_output_first: " + str(clean_output_first))
            _inform("--------------------------------------------------------------------------------")

            submitter = one_subject_job_submitter.OneSubjectJobSubmitter(self._archive, self._archive.build_home)

            submitter.username = userid
            submitter.password = password			
            submitter.server = 'https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER')

            submitter.project = subject.project
            submitter.subject = subject.subject_id
            submitter.session = subject.subject_id + '_7T'

            submitter.structural_reference_project = subject.structural_reference_project
            submitter.structural_reference_session = subject.subject_id + '_3T'

            submitter.pre_eddy_walltime_limit_hours = pre_eddy_walltime_limit_hrs
            submitter.pre_eddy_vmem_limit_gbs = pre_eddy_vmem_limit_gbs
            submitter.eddy_walltime_limit_hours = eddy_walltime_limit_hrs
            submitter.post_eddy_walltime_limit_hours = post_eddy_walltime_limit_hrs
            submitter.post_eddy_vmem_limit_gbs = post_eddy_vmem_limit_gbs

            submitter.setup_script = setup_file
            submitter.clean_output_resource_first = clean_output_first
            submitter.pe_dirs_spec = 'PAAP'
            submitter.put_server = put_server

            submitter.submit_jobs()


if __name__ == "__main__":

    # Get Environment varialbles
    xnat_pbs_jobs_home = os.getenv('XNAT_PBS_JOBS')
    if not xnat_pbs_jobs_home:
        _inform("Environment variable XNAT_PBS_JOBS must be set!")
        sys.exit(1)

    # home = os.getenv('HOME')
    # if home == None:
    #     _inform("Environment variable HOME must be set!")
    #     sys.exit(1)

    # Get Connectome DB credentials
    userid = input("Connectome DB Username: ")
    password = getpass.getpass("Connectome DB Password: ")

    # Get list of subjects to process
    subject_file_name = 'SubmitDiffusionPreprocessingHCP7TBatch.subjects'
    _inform('Retrieving subject list from: ' + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Process the subjects in the list
    batch_submitter = BatchSubmitter()
    batch_submitter.submit_jobs(subject_list)
