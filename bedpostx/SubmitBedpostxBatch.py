#!/usr/bin/env python3

"""Submit a batch of bedpostx jobs for HCP 3T data."""

# import of built-in modules
import getpass
import logging
import logging.config

# import of third party modules

# import of local modules
import hcp.batch_submitter as batch_submitter
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.bedpostx.one_subject_job_submitter as one_subject_job_submitter
import hcp.hcp3t.subject as hcp3t_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
logger = logging.getLogger(file_utils.get_logger_name(__file__))

class BatchSubmitter(batch_submitter.BatchSubmitter):

    def __init__(self):
        super().__init__(hcp3t_archive.Hcp3T_Archive())

    def submit_jobs(self, subject_list, config):
        
        # submit jobs for the listed subjects
        for subject in subject_list:

            put_server = 'http://db-shadow' + str(self.get_and_inc_shadow_number()) + '.nrg.mir:8080'

            # get information for the subject from the configuration
            setup_file = config.get_value(subject.subject_id, 'SetUpFile')
            clean_output_first = config.get_bool_value(subject.subject_id, 'CleanOutputFirst')
            # walltime_limit_hours = config.get_int_value(subject.subject_id, 'WalltimeLimit')
            # vmem_limit_gbs = config.get_int_value(subject.subject_id, 'VmemLimit')
            processing_stage_str = config.get_value(subject.subject_id, 'ProcessingStage')
            processing_stage = one_subject_job_submitter.ProcessingStage.from_string(processing_stage_str)

            logger.info("-----")
            logger.info(" Submitting bedpostxHCP3T jobs for:")
            logger.info("              project: " + subject.project)
            logger.info("              subject: " + subject.subject_id)
            logger.info("           put_server: " + put_server)
            logger.info("           setup_file: " + setup_file)
            logger.info("   clean_output_first: " + str(clean_output_first))
            # logger.info(" walltime_limit_hours: " + str(walltime_limit_hours))
            # logger.info("       vmem_limit_gbs: " + str(vmem_limit_gbs))
            logger.info("     processing_stage: " + str(processing_stage))
            logger.info("-----")

            submitter = one_subject_job_submitter.OneSubjectJobSubmitter(self._archive, self._archive.build_home)

            submitter.username = userid
            submitter.password = password
            submitter.server = 'https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER')
			
            submitter.setup_script = setup_file

            submitter.project = subject.project
            submitter.subject = subject.subject_id
            submitter.session = subject.subject_id + '_3T'

            # submitter.walltime_limit_hours = walltime_limit_hours
            # submitter.vmem_limit_gbs = vmem_limit_gbs

            submitter.clean_output_resource_first = clean_output_first
            submitter.put_server = put_server

            submitter.submit_jobs(processing_stage)


if __name__ == '__main__':

    # get ConnectomeDB credentials
    userid = input("Connectome DB Username: ")
    password = getpass.getpass("Connectome DB Password: ")

    # read the configuration file
    config_file_name = file_utils.get_config_file_name(__file__)
    logger.info("Reading configuration from file: " + config_file_name)    
    config = my_configparser.MyConfigParser()
    config.read(config_file_name)

    # get list of subjects to process
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    logger.info("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp3t_subject.read_subject_info_list(subject_file_name, separator='\t')

    # process the subjects in the list
    batch_submitter = BatchSubmitter()
    batch_submitter.submit_jobs(subject_list, config)


