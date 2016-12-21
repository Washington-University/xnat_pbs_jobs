#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import logging.config
import os

# import of third party modules

# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.bedpostx.one_subject_completion_checker as one_subject_completion_checker
import hcp.hcp3t.subject as hcp3t_subject
import utils.file_utils as file_utils

# authorship information 
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# configure logging and create module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
logger = logging.getLogger(file_utils.get_logger_name(__file__))

# module constants
DNM = "---" # Does Not Matter
NA = "N/A" # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'



if __name__ == '__main__':

    # get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    logger.info("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp3t_subject.read_subject_info_list(subject_file_name, separator='\t')

    # open complete and incomplete files for writing
    complete_file = open('complete.status', 'w')
    incomplete_file = open('incomplete.status', 'w')

    # create archive access object
    archive = hcp3t_archive.Hcp3T_Archive()

    # create on subject completion checker
    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()

    # create and output the header line
    header_line = "\t".join(["Project", 
                             "Subject ID",
                             "Output Resource Exists",
                             "Output Resource Date",
                             "Files Exist"])
    print(header_line)

    for subject in subject_list:
        logger.debug("subject: " + str(subject))

        output_resource_exists = None
        output_resource_date = None
        files_exist = None

        if archive.does_diffusion_preproc_dir_exist(subject):
            logger.debug("Diffusion preprocessed resource exists")
            if completion_checker.does_processed_resource_exist(archive, subject):
                logger.debug("Output resource exists")
                output_resource_exists = "TRUE"
                timestamp = os.path.getmtime(archive.diffusion_bedpostx_dir_fullpath(subject))
                output_resource_date = datetime.datetime.fromtimestamp(timestamp).strftime(DATE_FORMAT)

                if completion_checker.is_processing_complete(archive, subject):
                    files_exist = "TRUE"
                else:
                    files_exist = "FALSE"

            else:
                logger.debug("Output resource does not exist, but should.")
                output_resource_exists = "FALSE"
                output_resource_date = NA
                files_exist = NA

        else:
            logger.debug("Diffusion preprocessed resource does not exist")
            output_resource_exists = DNM
            output_resource_date = DNM
            files_exist = DNM
            
    
        output_str = "\t".join([subject.project,
                                subject.subject_id,
                                output_resource_exists,
                                output_resource_date,
                                files_exist])

        if files_exist == "TRUE" or files_exist == DNM:
            complete_file.write(output_str + os.linesep)
        else:
            incomplete_file.write(output_str + os.linesep)

        print(output_str)

    complete_file.close()
    incomplete_file.close()
