#!/usr/bin/env python3

# import of built-in modules
import datetime
import os

# import of third-party modules

# import of local modules
import RepairIcaFixProcessingHCP7T_OneSubjectCompletionChecker
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2018, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def _inform(msg):
    print(os.path.basename(__file__) + ": " + msg)

def _is_subject_complete(subject_results_dict):
    for scan, scan_results in subject_results_dict.items():
        if scan_results['scan_complete'] == 'FALSE':
            return False

    return True

def _write_subject_info(subject, subject_results_dict, afile):

    for scan, scan_results in sorted(subject_results_dict.items()):
        output_str = subject.project + '\t'
        output_str += subject.structural_reference_project + '\t'
        output_str += subject.subject_id + '\t'
        output_str += scan_results['resource_name'] + '\t'
        output_str += scan_results['resource_exists'] + '\t'
        output_str += scan_results['resource_date'] + '\t'
        output_str += scan_results['scan_complete']

        afile.write(output_str + os.linesep)
        print(output_str)

    print("")


def should_check(subject, scan, archive):
    return archive.does_functional_preproc_exist(subject, scan)


if __name__ == "__main__":

    # Get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)

    _inform("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Create list of scans to check
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
    complete_file = open('RepairIcaFixProcessingHCP7T.complete.status', 'w')
    incomplete_file = open('RepairIcaFixProcessingHCP7T.incomplete.status', 'w')
    
    # Create archive
    archive = hcp7t_archive.Hcp7T_Archive()

    # Create RepairIcaFixProcessingHCP7T_OneSubjectCompletionChecker
    completion_checker = RepairIcaFixProcessingHCP7T_OneSubjectCompletionChecker.RepairIcaFixProcessingHCP7T_OneSubjectCompletionChecker()

    # Check for completion of subjects
    for subject in subject_list:

        subject_results_dict = dict()

        for scan in scans_to_check_list:

            scan_results_dict = dict()

            if should_check(subject, scan, archive):

                if archive.does_FIX_processed_exist(subject, scan):

                    resource_exists = "TRUE"
                    timestamp = os.path.getmtime(archive.FIX_processed_dir_fullpath(subject, scan))
                    resource_date = datetime.datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

                    if completion_checker.is_processing_complete(archive, subject, scan):
                        scan_complete = "TRUE"
                    else:
                        scan_complete = "FALSE"

                else:
                    resource_exists = "FALSE"
                    resource_date = "N/A"
                    scan_complete = "FALSE"

            else:
                resource_exists = "---"
                resource_date = "---"
                scan_complete = "---"

            scan_results_dict['resource_name'] = archive.FIX_processed_dir_fullpath(subject, scan)
            scan_results_dict['resource_exists'] = resource_exists
            scan_results_dict['resource_date'] = resource_date
            scan_results_dict['scan_complete'] = scan_complete

            subject_results_dict[scan] = scan_results_dict

        if _is_subject_complete(subject_results_dict):
            _write_subject_info(subject, subject_results_dict, complete_file)
        else:
            _write_subject_info(subject, subject_results_dict, incomplete_file)
            
            
