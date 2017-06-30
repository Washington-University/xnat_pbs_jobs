#!/usr/bin/env python3

# import of built-in modules
import logging

# import of third-party modules

# import of local modules
import ccf.archive as ccf_archive
import ccf.structural_preprocessing.one_subject_prereq_checker as one_subject_prereq_checker
import ccf.subject as ccf_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
module_logger.setLevel(logging.INFO) # Note: This can be overridden by file configuration


if __name__ == "__main__":

	# get list of subjects to check
	subject_file_name = file_utils.get_subjects_file_name(__file__)
	module_logger.info("Retrieving subject list from: " + subject_file_name)

	subject_list = ccf_subject.read_subject_info_list(subject_file_name, separator=":")

	# create archive
	archive = ccf_archive.CcfArchive('3T')

	# create one prerequisites checker
	prereq_checker = one_subject_prereq_checker.OneSubjectPrereqChecker()

	for subject in subject_list:
		print("subject: " + str(subject))
		subject_id = subject.subject_id
		project = subject.project
		scan = subject.extra

		prereq_checker.are_prereqs_met(archive, subject, True)
