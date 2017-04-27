#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import logging.config
import os

# import of third-party modules

# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.reapplyfix.one_subject_completion_checker as one_subject_completion_checker
import hcp.hcp3t.subject as hcp3t_subject
import utils.file_utils as file_utils
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# configure logging and create module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
logger = logging.getLogger(file_utils.get_logger_name(__file__))

DNM = "---"  # Does Not Matter
NA = "N/A"  # Not Available
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

	parser = my_argparse.MyArgumentParser()
	
	parser.add_argument('-r', '--reg-name', dest='reg_name', required=False, default="", type=str)
	args = parser.parse_args()
	
	if args.reg_name != "":
		print("reg_name: " + args.reg_name)
		
	# get list of subjects to check
	subject_file_name = file_utils.get_subjects_file_name(__file__)
	logger.info("Retrieving subject list from: " + subject_file_name)
	subject_list = hcp3t_subject.read_subject_info_list(subject_file_name, separator="\t")

	# open output file
	output_file = open('ReApplyFix.status', 'w')

	_write_header()
	
	# create archive
	archive = hcp3t_archive.Hcp3T_Archive()

	# create one subject completion checker
	completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()

	if args.reg_name != "":
		print("setting completion checker reg_name to " + args.reg_name)
		completion_checker.reg_name = args.reg_name

	for subject in subject_list:
		subject_id = subject.subject_id
		project = subject.project
		scan = subject.extra
		logger.debug("       id: " + subject_id)
		logger.debug("  project: " + project)
		logger.debug("     scan: " + scan)

		if completion_checker.does_processed_resource_exist(archive, subject, scan):
			logger.debug("processed resource exists")

			resource_exists = True
			if args.reg_name != "":
				fullpath = archive.reapplyfix_dir_fullpath(subject, scan, args.reg_name)
			else:
				fullpath = archive.reapplyfix_dir_fullpath(subject, scan)

			timestamp = os.path.getmtime(fullpath)
			resource_date = datetime.datetime.fromtimestamp(timestamp).strftime(DATE_FORMAT)
			files_exist = completion_checker.is_processing_complete(archive, subject, scan)

		else:
			logger.debug("processed resource DOES NOT exist")
			resource_exists = False
			resource_date = NA
			files_exist = False

		_write_subject_info(output_file, project, subject_id, scan,
							resource_exists, resource_date, files_exist)



