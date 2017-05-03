#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import logging.config
import os

# import of third-party modules

# import of local modules
import ccf.archive as ccf_archive
import ccf.dedrift_and_resample.one_subject_completion_checker as one_subject_completion_checker
import ccf.subject as ccf_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))

DNM = "---"  # Does Not Matter
NA = "N/A"  # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'


def _write_header():

	header_line = "\t".join(["Project",
							 "Subject ID",
							 "Path",
							 "Resource Exists",
							 "Resource Date",
							 "Files Exist"])
	print(header_line)

	
def _write_subject_info(output_file, project, subject_id, path,
						resource_exists, resource_date, files_exist):

	subject_line = "\t".join([project,
							  subject_id,
							  path,
							  str(resource_exists),
							  resource_date,
							  str(files_exist)])
	print(subject_line)
	output_file.write(subject_line + os.linesep)


if __name__ == "__main__":

	# get list of subjects to check
	subject_file_name = 'subjectfiles' + os.sep + file_utils.get_subjects_file_name(__file__)
	module_logger.info("Retrieving subject list from: " + subject_file_name)
	subject_list = ccf_subject.read_subject_info_list(subject_file_name, separator=":")

	# open output file
	output_file = open('DeDriftAndResample.status', 'w')

	_write_header()
	
	# create archive
	archive = ccf_archive.CcfArchive('3T')

	# create one subject completion checker
	completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()
	
	for subject in subject_list:
		subject_id = subject.subject_id
		project = subject.project
		module_logger.debug("      id: " + subject_id)
		module_logger.debug(" project: " + project)

		fullpath = archive.dedrift_and_resample_dir_full_path(subject)
		
		if completion_checker.does_processed_resource_exist(archive, subject):
			module_logger.debug("processed resource exists")
			resource_exists = True
			timestamp = os.path.getmtime(fullpath)
			resource_date = datetime.datetime.fromtimestamp(timestamp).strftime(DATE_FORMAT)
			files_exist = completion_checker.is_processing_complete(archive, subject)

		else:
			module_logger.debug("processed resource DOES NOT exist")
			resource_exists = False
			resource_date = NA
			files_exist = False

		_write_subject_info(output_file, project, subject_id, fullpath,
							resource_exists, resource_date, files_exist)
