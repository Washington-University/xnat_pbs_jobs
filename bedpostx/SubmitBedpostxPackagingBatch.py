#!/usr/bin/env python3

# import of built-in modules
import logging
import logging.config

# import of third party modules

# import of local modules
import hcp.batch_submitter as batch_submitter
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.bedpostx.one_subject_package_job_submitter as one_subject_package_job_submitter
import hcp.hcp3t.subject as hcp3t_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
logger = logging.getLogger(file_utils.get_logger_name(__file__))

class BatchPackagingSubmitter(batch_submitter.BatchSubmitter):
    
    def __init__(self):
        super().__init__(hcp3t_archive.Hcp3T_Archive())

    def submit_jobs(self, subject_list, config):

        for subject in subject_list:

            server = 'http://db-shadow' + str(self.get_and_inc_shadow_number()) + '.nrg.mir:8080'
            packaging_stage_str = config.get_value(subject.subject_id, 'PackagingStage')
            packaging_stage = one_subject_package_job_submitter.PackagingStage.from_string(packaging_stage_str)

            logger.info("-----")
            logger.info(" Submitting bedpostx packaging jobs for:")
            logger.info("          project: " + subject.project)
            logger.info("          subject: " + subject.subject_id)
            logger.info("           server: " + server)
            logger.info("  packaging_stage: " + str(packaging_stage))
            logger.info("-----")

            submitter = one_subject_package_job_submitter.OneSubjectPackageJobSubmitter(self._archive, self._archive.build_home)

            submitter.project = subject.project
            submitter.subject = subject.subject_id
            submitter.session = subject.subject_id + '_3T'
            submitter.server = server

            submitter.submit_jobs(packaging_stage)


if __name__ == '__main__':

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
    batch_submitter = BatchPackagingSubmitter()
    batch_submitter.submit_jobs(subject_list, config)
