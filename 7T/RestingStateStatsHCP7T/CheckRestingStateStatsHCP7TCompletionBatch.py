#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import logging.config
import os

# import of third party modules
# None

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.resting_state_stats.one_subject_completion_checker as one_subject_completion_checker
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# configure logging and create module logger
logging_config_file_name=file_utils.get_logging_config_file_name(__file__)
print(os.path.basename(__file__)+":", "Getting logging configuration from:", logging_config_file_name)
logging.config.fileConfig(logging_config_file_name)

logger_name=file_utils.get_logger_name(__file__)
print(os.path.basename(__file__)+":", "logger name:", logger_name)
logger = logging.getLogger(logger_name)

DNM = "---" # Does Not Matter
NA = "N/A" # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'


def get_resource_name(scan_name):
    return scan_name + '_RSS'


def _is_subject_complete(subject_results_dict):
    for scan, scan_results_dict in subject_results_dict.items():
        if scan_results_dict['files_exist'] == 'FALSE':
            return False

    return True


def _write_subject_info(subject, subject_results_dict, afile):

    for scan, scan_results_dict in sorted(subject_results_dict.items()):
        output_str = "\t".join([subject.project, 
                                subject.structural_reference_project,
                                subject.subject_id, 
                                scan_results_dict['resource_name'], 
                                scan_results_dict['resource_exists'],
                                scan_results_dict['resource_date'],
                                scan_results_dict['files_exist']])

        afile.write(output_str + os.linesep)
        print(output_str)

    print("")


if __name__ == "__main__":

    # get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    logger.info("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name, separator=":")

    # create list of scans to check
    scans_to_check_list = []
    scans_to_check_list.append('rfMRI_REST1_PA')
    scans_to_check_list.append('rfMRI_REST2_AP')
    scans_to_check_list.append('rfMRI_REST3_PA')
    scans_to_check_list.append('rfMRI_REST4_AP')
    scans_to_check_list.append('tfMRI_MOVIE1_AP')
    scans_to_check_list.append('tfMRI_MOVIE2_PA')
    scans_to_check_list.append('tfMRI_MOVIE3_PA')
    scans_to_check_list.append('tfMRI_MOVIE4_AP')

    # open complete and incomplete files for writing
    complete_file = open('complete.status', 'w')
    incomplete_file = open('incomplete.status', 'w')

    # create archive
    archive = hcp7t_archive.Hcp7T_Archive()

    # create one subject completion checker
    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()

    # check completion status for listed subjects

    header_line = "\t".join(["Project",
                             "Structural Reference Project",
                             "Subject ID",
                             "Output Resource Name",
                             "Output Resource Exists",
                             "Output Resource Date",
                             "Files Exist"])
    print(header_line)

    for subject in subject_list:
        logger.debug("subject: " + str(subject))

        subject_results_dict = dict()

        for scan_name in scans_to_check_list:
            logger.debug("scan_name: " + str(scan_name))

            scan_results_dict = dict()

            if archive.does_FIX_processed_exist(subject, scan_name):
                # FIX processed resource does exist for this scan.
                # So the RSS process resource should exist.
                if completion_checker.does_processed_resource_exist(archive, subject, scan_name):

                    rss_resource_exists = "TRUE"
                    timestamp = os.path.getmtime(archive.RSS_processed_dir_fullpath(subject, scan_name))
                    rss_resource_date = datetime.datetime.fromtimestamp(timestamp).strftime(DATE_FORMAT)

                    if completion_checker.is_processing_complete(archive, subject, scan_name):
                        files_exist = "TRUE"
                    else:
                        files_exist = "FALSE"

                else:
                    rss_resource_exists = "FALSE"
                    rss_resource_date = NA
                    files_exist = "FALSE"

            else:
                # FIX processed resource for this scan does not exist.
                rss_resource_exists = DNM
                rss_resource_date = DNM
                files_exist = DNM
                
            scan_results_dict['resource_name'] = get_resource_name(scan_name)
            scan_results_dict['resource_exists'] = rss_resource_exists
            scan_results_dict['resource_date'] = rss_resource_date
            scan_results_dict['files_exist'] = files_exist

            subject_results_dict[scan_name] = scan_results_dict

        if _is_subject_complete(subject_results_dict):
            _write_subject_info(subject, subject_results_dict, complete_file)
        else:
            _write_subject_info(subject, subject_results_dict, incomplete_file)





