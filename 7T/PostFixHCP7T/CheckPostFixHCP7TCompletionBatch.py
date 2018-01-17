#!/usr/bin/env python3

# import of built-in modules
import datetime
import os
import sys

# import of third party modules

# import of local modules
import PostFixHCP7T_OneSubjectCompletionChecker
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Outputs a message that is prefixed by the module file name."""
    print(os.path.basename(__file__) + ": " + msg)


def _is_subject_complete(subject_results_dict):
    for scan, scan_results in subject_results_dict.items():
        if scan_results['scan_complete'] == 'FALSE':
            return False

    return True


def _write_subject_info(subject, subject_results_dict, afile):

    for scan, scan_results in sorted(subject_results_dict.items()):
        output_str = subject.project + '\t' + subject.subject_id + '\t'
        output_str += scan_results['resource_name'] + '\t'
        output_str += scan_results['resource_exists'] + '\t'
        output_str += scan_results['resource_date'] + '\t'
        output_str += scan_results['scan_complete']

        afile.write(output_str + os.linesep)
        print(output_str)

    print("")


def should_check(subject, scan, archive):
    if scan == 'tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA':
        return True
    else:
        return archive.does_functional_preproc_exist(subject, scan)
    

if __name__ == "__main__":

    # Get list of subjects to check
    subject_file_name = file_utils.get_subjects_file_name(__file__)

    _inform("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Create list of scans to check
    ica_fix_scans_list = []
    ica_fix_scans_list.append('rfMRI_REST1_PA')
    ica_fix_scans_list.append('rfMRI_REST2_AP')
    ica_fix_scans_list.append('rfMRI_REST3_PA')
    ica_fix_scans_list.append('rfMRI_REST4_AP')
    ica_fix_scans_list.append('tfMRI_MOVIE1_AP')
    ica_fix_scans_list.append('tfMRI_MOVIE2_PA')
    ica_fix_scans_list.append('tfMRI_MOVIE3_PA')
    ica_fix_scans_list.append('tfMRI_MOVIE4_AP')
    ica_fix_scans_list.append('tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA')

    # open complete and incomplete files for writing
    complete_file = open('PostFix.complete.status', 'w')
    incomplete_file = open('PostFix.incomplete.status', 'w')

    # Create archive
    archive = hcp7t_archive.Hcp7T_Archive()

    # Create PostFixHCP7T One Subject completion checker
    completion_checker = PostFixHCP7T_OneSubjectCompletionChecker.PostFixHCP7T_OneSubjectCompletionChecker()

    # Check completion for subjects
    for subject in subject_list:

        subject_results_dict = dict()

        for scan in ica_fix_scans_list:

            scan_results_dict = dict()

            # Should we check for the postfix resource?
            # Does the preprocessed resource for this scan exist,
            # or is the scan the special concatenated retinotopy scan?
            if should_check(subject, scan, archive):

                # does the postfix resource for this scan exist?
                if archive.does_PostFix_processed_resource_exist(subject, scan):

                    postfix_resource_exists = "TRUE"
                    timestamp = os.path.getmtime(archive.scan_PostFix_resource_dir(subject, scan))
                    postfix_resource_date = datetime.datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

                    if completion_checker.is_processing_complete(archive, subject, scan):
                        scan_complete = "TRUE"
                    else:
                        scan_complete = "FALSE"

                else:
                    postfix_resource_exists = "FALSE"
                    postfix_resource_date = "N/A"
                    scan_complete = "FALSE"

            else:
                postfix_resource_exists = "---"
                postfix_resource_date = "---"
                scan_complete = "---"

            scan_results_dict['resource_name'] = archive.scan_PostFix_resource_name(scan)
            scan_results_dict['resource_exists'] = postfix_resource_exists
            scan_results_dict['resource_date'] = postfix_resource_date
            scan_results_dict['scan_complete'] = scan_complete

            subject_results_dict[scan] = scan_results_dict

        if _is_subject_complete(subject_results_dict):
            _write_subject_info(subject, subject_results_dict, complete_file)
        else:
            _write_subject_info(subject, subject_results_dict, incomplete_file)
