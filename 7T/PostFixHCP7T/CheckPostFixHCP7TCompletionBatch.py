#!/usr/bin/env python3

# import of built-in modules
import datetime
import os
import sys

# import of third party modules
# None

# import of local modules
import PostFixHCP7T_OneSubjectCompletionChecker
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject

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
        output_str = "HCP_Staging_7T" + '\t' + subject.subject_id + '\t'
        output_str += scan_results['resource_name'] + '\t'
        output_str += scan_results['resource_exists'] + '\t'
        output_str += scan_results['resource_date'] + '\t'
        output_str += scan_results['scan_complete']

        afile.write(output_str + os.linesep)
        print(output_str)

    print("")


if __name__ == "__main__":

    # Get environment variables
    subject_files_dir = os.getenv('SUBJECT_FILES_DIR')
    if subject_files_dir is None:
        _inform("Environment variable SUBJECT_FILES_DIR must be set!")
        sys.exit(1)

    # Get list of subjects to check
    subject_file_name = subject_files_dir + os.sep + 'CheckPostFixProcessingHCP7T.python.subjects'
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

    # open complete and incomplete files for writing
    complete_file = open('HCP_Staging_7T.complete.status', 'w')
    incomplete_file = open('HCP_Staging_7T.incomplete.status', 'w')

    # Create archive
    archive = hcp7t_archive.Hcp7T_Archive()

    # Create PostFixHCP7T One Subject completion checker
    completion_checker = PostFixHCP7T_OneSubjectCompletionChecker.PostFixHCP7T_OneSubjectCompletionChecker()

    # Check completion for subjects
    for subject in subject_list:

        subject_results_dict = dict()

        for scan in ica_fix_scans_list:

            scan_results_dict = dict()

            # does the preprocess resource for this scan exist?
            if archive.does_functional_preproc_exist(subject, scan):

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
