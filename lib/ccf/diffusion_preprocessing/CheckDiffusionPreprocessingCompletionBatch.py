#!/usr/bin/env python3

# import of built-in modules
import logging
import os

# import of third-party modules

# import of local modules
import ccf.subject as ccf_subject
import utils.file_utils as file_utils
import utils.my_argparse as my_argparse
import ccf.archive as ccf_archive
import ccf.diffusion_preprocessing.one_subject_completion_checker as one_subject_completion_checker
import ccf.diffusion_preprocessing.one_subject_prereq_checker as one_subject_prereq_checker
import ccf.diffusion_preprocessing.one_subject_run_status_checker as one_subject_run_status_checker

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
                             "Classifier",
                             "Prereqs Met",
                             "Resource",
                             "Exists",
                             "Resource Date",
                             "Complete",
                             "Queued/Running"])
    print(header_line)
    output_file.write(header_line + os.linesep)

if __name__ == "__main__":

    parser = my_argparse.MyArgumentParser(
        description="Batch mode checking of completion of diffusion preprocessing")

    # optional arguments
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
        module_logger.info("Completion check is done by checking for completion markers")
        print("Completion check is done by checking for completion markers")
        
    # get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    module_logger.info("Retrieving subject list from: " + subject_file_name)
    print("Retrieving subject list from: " + subject_file_name)
    
    subject_list = ccf_subject.read_subject_info_list(subject_file_name, separator=":")

    # open output file
    output_file = open('StructuralPreprocessing.status', 'w')

    _write_header(output_file)
    
    # create archive
    archive = ccf_archive.CcfArchive()

    # create one subject checkers
    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()
    prereq_checker = one_subject_prereq_checker.OneSubjectPrereqChecker()
    running_checker = one_subject_run_status_checker.OneSubjectRunStatusChecker()

    for subject in subject_list:
        project = subject.project
        subject_id = subject.subject_id
        classifier = subject.classifier

        prereqs_met = prereq_checker.are_prereqs_met(archive, subject)
        queued_or_running = running_checker.get_queued_or_running(subject)

        
