#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import os

# import of third-party modules

# import of local modules
import ccf.archive as ccf_archive
import ccf.functional_preprocessing.one_subject_completion_checker as one_subject_completion_checker
#import ccf.functional_preprocessing.one_subject_prereq_checker as one_subject_prereq_checker
#import ccf.functional_preprocessing.one_subject_run_status_checker as one_subject_run_status_checker
import ccf.subject as ccf_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
module_logger.setLevel(logging.INFO) # Note: This can be overridden by file configuration

DNM = "---"  # Does Not Matter
NA = "N/A"  # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'

def _write_header(output_file):
    header_line = "\t".join(["Project", "Subject ID", "Classifier", "Prereqs Met", "Resource",  "Exists", "Complete", "Queued/Running"])
    print(header_line)
    output_file.write(header_line + os.linesep)

    
def _write_scan_info(output_file, project, subject_id, classifier, prereqs_met, resource, exists, complete, queued_or_running):
    scan_line = "\t".join([project, subject_id, classifier, str(prereqs_met), resource, str(exists), str(complete), str(queued_or_running)])
    print(subject_line)
    output_file.write(subject_line + os.linesep)
    

if __name__ == "__main__":

    # get list of subjects/scans to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    module_logger.info("Retrieving subject/scan list from: " + subject_file_name)
    print("Retrieving subject/scan list from: " + subject_file_name)
    
    subject_list = ccf_subject.read_subject_info_list(subject_file_name, separator=":")

    # open output file
    output_file = open('FunctionalPreprocessing.status', 'w')

    _write_header(output_file)
    
    # create archive
    archive = ccf_archive.CcfArchive()

    # create one subject completion checker
    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()
#    running_checker = one_subject_run_status_checker.OneSubjectRunStatusChecker()
#    prereq_checker = one_subject_prereq_checker.OneSubjectPrereqChecker()
    
    for subject in subject_list:
        project = subject.project
        subject_id = subject.subject_id
        classifier = subject.classifier
        scan = subject.extra

        fullpath = archive.functional_preproc_dir_full_path(subject)
        resource = archive.functional_preproc_dir_name(subject)
        
        print("fullpath: " + fullpath)
        print("resource: " + resource)
        print()
        
        if completion_checker.does_processed_resource_exist(archive, subject):
            resource_exists = True
            
            timestamp = os.path.getmtime(fullpath)
            resource_date = datetime.datetime.fromtimestamp(timestamp).strftime(DATE_FORMAT)
            #files_exist = completion_checker.is_processing_marked_complete(archive, subject)
            files_exist = False
            #prereqs_met = prereq_checker.are_prereqs_met(archive, subject)
            prereqs_met = False

        else:
            resource_exists = False
            resource_date = NA
            files_exist = False
            prereqs_met = False
            
        # queued_or_running = running_checker.get_queued_or_running(subject)
        queued_or_running = False
        
        _write_scan_info(output_file, project, subject_id, classifier, prereqs_met, resource, resource_exists, files_exist, queued_or_running)
            
