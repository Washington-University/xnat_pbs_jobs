#!/usr/bin/env python3

# import of built-in modules
import datetime
import os
import sys

# import of third party modules
# None

# import of local modules
import DeDriftAndResampleHCP7T_OneSubjectCompletionChecker
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


_PROJECT = 'HCP_1200'


def _inform(msg):
    """Outputs a message that is prefixed by the module file name."""
    print(os.path.basename(__file__) + ": " + msg)


def _is_subject_complete(subject_results_dict):
    for scan, scan_results in subject_results_dict.items():
        if scan_results['files_exist'] == 'FALSE':
            return False

    return True


def _write_subject_info(subject, subject_results_dict, afile):

    for scan, scan_results in sorted(subject_results_dict.items()):
        output_str = _PROJECT + '\t' + subject.subject_id + '\t'
        output_str += scan_results['resource_name'] + '\t'
        output_str += scan_results['scan_name'] + '\t'
        output_str += scan_results['resource_exists'] + '\t'
        output_str += scan_results['resource_date'] + '\t'
        output_str += scan_results['files_exist']

        afile.write(output_str + os.linesep)
        print(output_str)

    print("")


def should_check(subject, scan, archive):
    if scan == 'tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA':
        retinotopy_scan_count = len(archive.available_retinotopy_unproc_dirs(subject))
        return retinotopy_scan_count == 6
    else:
        return archive.does_functional_unproc_exist(subject, scan)
    

if __name__ == "__main__":

    # Get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    _inform("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Create list of scan names to check
    dedrift_scan_names_list = []
    dedrift_scan_names_list.append('rfMRI_REST1_PA')
    dedrift_scan_names_list.append('rfMRI_REST2_AP')
    dedrift_scan_names_list.append('rfMRI_REST3_PA')
    dedrift_scan_names_list.append('rfMRI_REST4_AP')
    dedrift_scan_names_list.append('tfMRI_MOVIE1_AP')
    dedrift_scan_names_list.append('tfMRI_MOVIE2_PA')
    dedrift_scan_names_list.append('tfMRI_MOVIE3_PA')
    dedrift_scan_names_list.append('tfMRI_MOVIE4_AP')
    dedrift_scan_names_list.append('tfMRI_RETBAR1_AP')
    dedrift_scan_names_list.append('tfMRI_RETBAR2_PA')
    dedrift_scan_names_list.append('tfMRI_RETCCW_AP')
    dedrift_scan_names_list.append('tfMRI_RETCON_PA')
    dedrift_scan_names_list.append('tfMRI_RETCW_PA')
    dedrift_scan_names_list.append('tfMRI_RETEXP_AP')
    dedrift_scan_names_list.append('tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA')

    # open complete and incomplete files for writing
    complete_file = open(_PROJECT + '.complete.status', 'w')
    incomplete_file = open(_PROJECT + '.incomplete.status', 'w')

    # Create archive
    archive = hcp7t_archive.Hcp7T_Archive()

    # Create DeDriftAndResampleHCP7T One subject completion checker
    completion_checker = DeDriftAndResampleHCP7T_OneSubjectCompletionChecker.DeDriftAndResampleHCP7T_OneSubjectCompletionChecker()

    # Check completion for listed subjects
    for subject in subject_list:

        subject_results_dict = dict()

        for scan_name in dedrift_scan_names_list:

            scan_results_dict = dict()

            # Should we check for the MSMAllDeDrift resource
            if should_check(subject, scan_name, archive):

                # does the DeDriftAndResample resource exist?
                if completion_checker.does_processed_resource_exist(archive, subject):
                    dedrift_resource_exists = "TRUE"
                    timestamp = os.path.getmtime(archive.DeDriftAndResample_processed_dir_name(subject))
                    dedrift_resource_date = datetime.datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

                    if completion_checker.is_processing_complete(archive, subject, scan_name):
                        files_exist = "TRUE"
                    else:
                        files_exist = "FALSE"

                else:
                    dedrift_resource_exists = "FALSE"
                    dedrift_resource_date = "N/A"
                    files_exist = "FALSE"

            else:
                # unprocessed resource does not exist
                dedrift_resource_exists = "---"
                dedrift_resource_date = "---"
                files_exist = "---"

            scan_results_dict['resource_name'] = archive.DEDRIFT_AND_RESAMPLE_RESOURCE_NAME
            scan_results_dict['resource_exists'] = dedrift_resource_exists
            scan_results_dict['resource_date'] = dedrift_resource_date
            scan_results_dict['files_exist'] = files_exist
            scan_results_dict['scan_name'] = scan_name

            subject_results_dict[scan_name] = scan_results_dict

        if _is_subject_complete(subject_results_dict):
            _write_subject_info(subject, subject_results_dict, complete_file)
        else:
            _write_subject_info(subject, subject_results_dict, incomplete_file)
