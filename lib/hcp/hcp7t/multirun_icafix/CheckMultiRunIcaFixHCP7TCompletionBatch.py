#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import os

# import of third-party modules

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.multirun_icafix.one_subject_completion_checker as one_subject_completion_checker
import hcp.hcp7t.multirun_icafix.one_subject_prereq_checker as one_subject_prereq_checker
import hcp.hcp7t.multirun_icafix.one_subject_run_status_checker as one_subject_run_status_checker
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
# Note: The following can be overridden by file configuration
module_logger.setLevel(logging.INFO) 

DNM = "---"  # Does Not Matter
NA = "N/A"  # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'

def _write_header(output_file):
    header_line = "\t".join(["Project",
                             "Subject ID",
                             "Prereqs Met",
                             "Resource",
                             "Exists",
                             "Resource Date",
                             "Complete",
                             "Queued/Running"])
    print(header_line)
    output_file.write(header_line + os.linesep)


def _write_subject_info(output_file, project, subject_id, prereqs_met,
                        resource, exists, resource_date_str, complete,
                        queued_or_running):
    subject_line = "\t".join([project, subject_id, str(prereqs_met),
                              resource, str(exists), resource_date_str, str(complete),
                              str(queued_or_running)])
    print(subject_line)
    output_file.write(subject_line + os.linesep)

    
if __name__ == "__main__":

    parser = my_argparse.MyArgumentParser(
        description="Batch mode checking of completion of MultiRunIcaFixHCP7T Processing")

    # optional 
    # The --bypass-mark option tells this program to ignore whether the resource
    # is marked complete and just go ahead and do a full completion check.
    parser.add_argument('-b', '--bypass-mark', dest='bypass_mark', action='store_true',
                        required=False, default=False)
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true',
                        required=False, default=False)

    # parse the command line arguments
    args = parser.parse_args()

    if args.bypass_mark:
        module_logger.info("Bypassing completion markers and doing complete check")
        print("Bypassing completion markers and doing complete check")
    else:
        module_logger.info("Competion check is done by checking for completion markers")
        print("Competion check is done by checking for completion markers")

    # get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    module_logger.info("Retrieving subject list from: " + subject_file_name)
    print("Retrieving subject list from: " + subject_file_name)

    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name, separator=":")

    # open output file
    output_file = open('MultiRunIcaFixHCP7T.status', 'w')

    _write_header(output_file)
    
    # create archive
    archive = hcp7t_archive.Hcp7T_Archive()

    # create one subject checkers
    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()
    prereq_checker = one_subject_prereq_checker.OneSubjectPrereqChecker()
    running_checker = one_subject_run_status_checker.OneSubjectRunStatusChecker()

    for subject in subject_list:
        subject_id = subject.subject_id
        project = subject.project

        prereqs_met = prereq_checker.are_prereqs_met(archive, subject)
        queued_or_running = running_checker.get_queued_or_running(subject)

        if completion_checker.does_processed_resource_exist(archive, subject):
            resource_exists = True

            fullpath = archive.multirun_icafix_proc_dir_full_path(subject)
            resource = archive.multirun_icafix_proc_dir_name(subject)

            timestamp = os.path.getmtime(fullpath)
            resource_date = datetime.datetime.fromtimestamp(timestamp).strftime(DATE_FORMAT)
    
            if args.bypass_mark:
                files_exist = completion_checker.is_processing_complete(archive, subject,
                                                                        verbose=args.verbose)
            else:
                files_exist = completion_checker.is_processing_marked_complete(archive, subject)

        else:
            resource = DNM
            resource_exists = False
            resource_date = NA
            files_exist = False

        _write_subject_info(output_file, project, subject_id, prereqs_met,
                            resource, resource_exists, resource_date,
                            files_exist, queued_or_running)
