#!/usr/bin/env python3

# import of built-in modules
import logging

# import of third-party modules

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.multirun_icafix.one_subject_prereq_checker as one_subject_prereq_checker
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
# Note: The following can be overridden by file configuration
module_logger.setLevel(logging.INFO)


if __name__ == "__main__":

    # get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    module_logger.info("Retrieving subject list from: " + subject_file_name)
    print("Retrieving subject list from: " + subject_file_name)
    
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name, separator=":")

    # create archive
    archive = hcp7t_archive.Hcp7T_Archive()

    # create one prerequisites checker
    prereq_checker = one_subject_prereq_checker.OneSubjectPrereqChecker()

    for subject in subject_list:
        print("checking subject: " + str(subject), end=" - ")
        
        if (prereq_checker.are_prereqs_met(archive, subject, True)):
            print("Prerequisites Met")
        else:
            print("Prerequisites NOT Met")
            

