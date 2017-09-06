#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import ccf.batch_submitter as batch_submitter
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
# Note: This can be overridden by file configuration
module_logger.setLevel(logging.WARNING)  


class BatchSubmitter(batch_submitter.BatchSubmitter):

    def __init__(self):
        super.__init__(hcp7t_archive.HCP7T_Archive)

    def submit_jobs(self, username, password, subject_list, config):

        # submit jobs for the listed subjects
        for subject in subject_list:

            print("subject: " + str(subject))


def do_submissions(userid, password, subject_list):

    # read the configuration file
    config_file_name = file_utils.get_config_file_name(__file__)
    print("Reading configuration from file: " + config_file_name)
    config = my_configparser.MyConfigParser()
    config.read(config_file_name)

    # process subjects in the list
    batch_submitter = BatchSubmitter()
    batch_submitter.submit_jobs(userid, password, subject_list, config)


if __name__ == '__main__':

    logging.config.fileConfig(
        file_utils.get_logging_config_file_name(__file__),
        disable_existing_loggers=False)

    # get Database credentials
    userid = input("DB Username: ")
    password = getpass.getpass("DB Password: ")

    # get list of subjects to process
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    print("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name, separator=":")

    do_submissions(userid, password, subject_list)
    
