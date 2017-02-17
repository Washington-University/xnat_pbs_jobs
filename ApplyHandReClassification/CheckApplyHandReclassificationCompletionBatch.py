#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import logging.config
import os

# import of third party modules
# None

# import of local modules
import hcp.hcp3t.applyhandreclassification.one_subject_completion_checker as one_subject_completion_checker
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# configure logging and create module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
logger = logging.getLogger(file_utils.get_logger_name(__file__))

DNM = "---" # Does Not Matter
NA = "N/A" # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'


def _write_header():
    
    header_line = "\t".join(["Project",
                             "Subject ID",
                             "Scan",
                             "Resource Exists",
                             "Resource Date",
                             "Files Exist"])
    print(header_line)

def _write_subject_info(output_file, project, subject_id, scan, 
                        resource_exists, resource_date, files_exist):

    subject_line = "\t".join([project,
                              subject_id,
                              scan,
                              str(resource_exists),
                              resource_date,
                              str(files_exist)])
    print(subject_line)
    output_file.write(subject_line + os.linesep)


if __name__ == "__main__":

    # get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    logger.info("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp3t_subject.read_subject_info_list(subject_file_name, separator="\t")

    # open output file
    output_file = open('ApplyHandReclassification.status', 'w')

    # create archive
    archive = hcp3t_archive.Hcp3T_Archive()

    # create one subject completion checker
    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()

    for subject in subject_list:
        subject_id = subject.subject_id
        project = subject.project
        scan = subject.extra
        logger.debug("       id: " + subject_id)
        logger.debug("  project: " + project)
        logger.debug("     scan: " + scan)

        if archive.does_hand_reclassification_exist(subject, scan):
            # hand reclassification resource does exist
            # so the ApplyHandReclassification resource should exist
            
            if completion_checker.does_processed_resource_exist(archive, subject, scan):
                logger.debug("processed resource exists")

                ahr_resource_exists = True
                timestamp = os.path.getmtime(archive.apply_handreclassification_dir_fullpath(subject, scan))
                ahr_resource_date = datetime.datetime.fromtimestamp(timestamp).strftime(DATE_FORMAT)

                if completion_checker.is_processing_complete(archive, subject, scan):
                    files_exist = True
                else:
                    files_exist = False

            else:
                logger.debug("processed resource DOES NOT exist")
                ahr_resource_exists = False
                ahr_resource_date = NA
                files_exist = False

        else:
            # hand reclassification resource for this scan does not exist
            ahr_resource_exists = DNM
            ahr_resource_date = DNM
            files_exist = DNM

        _write_subject_info(output_file, project, subject_id, scan, 
                            ahr_resource_exists, ahr_resource_date, files_exist) 
