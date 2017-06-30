#!/usr/bin/env python3

# import of built-in modules
import getpass
import logging
import logging.config

# import of third party modules

# import of local modules
import hcp.batch_submitter as batch_submitter
import hcp.hcp3t.applyhandreclassification.one_subject_job_submitter as one_subject_job_submitter
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
logger = logging.getLogger(file_utils.get_logger_name(__file__))

logger.info("logger: '" + logger.name + "' created and configured")

class BatchSubmitter(batch_submitter.BatchSubmitter):

    def __init__(self):
        super().__init__(hcp3t_archive.Hcp3T_Archive())

    def submit_jobs(self, username, password, subject_list, config):

        # submit jobs for the listed subjects
        for subject in subject_list:

            put_server = 'http://db-shadow' + str(self.get_and_inc_shadow_number()) + '.nrg.mir:8080'

            # get information for the subject from the configuration
            setup_file = config.get_value(subject.subject_id, 'SetUpFile')
            clean_output_first = config.get_bool_value(subject.subject_id, 'CleanOutputFirst')
            processing_stage_str = config.get_value(subject.subject_id, 'ProcessingStage')
            processing_stage = one_subject_job_submitter.ProcessingStage.from_string(processing_stage_str)
            walltime_limit_hrs = config.get_value(subject.subject_id, 'WalltimeLimitHours')
            vmem_limit_gbs = config.get_value(subject.subject_id, 'VmemLimitGbs')
            scan = subject.extra

            logger.info("-----")
            logger.info(" Submitting ApplyHandReClassification jobs for:")
            logger.info("             project: " + subject.project)
            logger.info("             subject: " + subject.subject_id)
            logger.info("                scan: " + scan)
            logger.info("          put_server: " + put_server)
            logger.info("          setup_file: " + setup_file)
            logger.info("  clean_output_first: " + str(clean_output_first))
            logger.info("    processing_stage: " + str(processing_stage))
            logger.info("-----")

            submitter = one_subject_job_submitter.OneSubjectJobSubmitter(self._archive, self._archive.build_home)

            submitter.username = username
            submitter.password = password
            submitter.server = 'https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER')
            
            submitter.project = subject.project
            submitter.subject = subject.subject_id
            submitter.session = subject.subject_id + '_3T'
            submitter.scan = scan

            submitter.setup_script = setup_file
            submitter.clean_output_resource_first = clean_output_first
            submitter.put_server = put_server
            submitter.walltime_limit_hours = walltime_limit_hrs
            submitter.vmem_limit_gbs = vmem_limit_gbs

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
    subject_list = hcp3t_subject.read_subject_info_list(subject_file_name, separator=':')

    # process the subjects in the list
    batch_submitter = BatchSubmitter()
    batch_submitter.submit_jobs(userid, password, subject_list, config)

