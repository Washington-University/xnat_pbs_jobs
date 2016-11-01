#!/usr/bin/env python3

# import of built-in modules
import datetime
import os
import sys


# import of third party modules
pass


# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.diffusion_preprocessing.one_subject_completion_checker as one_subject_completion_checker
import hcp.hcp3t.diffusion_preprocessing.output_size_checker as output_size_checker
import hcp.hcp3t.subject as hcp3t_subject


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Outputs a message that is prefixed by the module file name."""
    print(os.path.basename(__file__) + ": " + msg)


if __name__ == "__main__":

    # Get list of subjects to check
    subject_file_name = 'CheckDiffusionPreprocessingHCPBatch.subjects'
    _inform("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp3t_subject.read_subject_info_list(subject_file_name)

    # open complete and incomplete status output files for writing
    complete_file = open('complete.status', 'w')
    incomplete_file = open('incomplete.status', 'w')

    # Create archive
    archive = hcp3t_archive.Hcp3T_Archive()

    # Create a one subject completion checker
    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()

    # Check completion status for listed subjects
    print("Project\tSubject ID\tOutput Resource Exists\tOutput Resource Date\tFiles Exist\tExpected Output Volumes\tExpected Output Matches")

    for subject in subject_list:

        if archive.does_diffusion_unproc_dir_exist(subject):
            # Diffusion unprocessed resource exists

            # Does the processed resource exist?
            if completion_checker.does_processed_resource_exist(archive, subject):
                processed_resource_exists = "TRUE"
                timestamp = os.path.getmtime(archive.diffusion_preproc_dir_fullpath(subject))
                processed_resource_date = datetime.datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

                if completion_checker.is_processing_complete(archive, subject):
                    files_exist = "TRUE"
                else:
                    files_exist = "FALSE"

                try:
                    size_checker = output_size_checker.DiffusionOutputSizeChecker()
                    (success, expected_size, msg) = size_checker.check_diffusion_preproc_size(archive, subject)
                except output_size_checker.NoDiffusionPreprocResource as e:
                    success = False
                    expected_size = 0
                    msg = ""
                except FileNotFoundError as e:
                    success = False
                    expected_size = 0
                    msg = ""

                expected_size_str = str(expected_size)
                matches_expected = "TRUE" if success else "FALSE"

            else:
                processed_resource_exists = "FALSE"
                processed_resource_date = "N/A"
                files_exist = "FALSE"
                expected_size_str = "N/A"
                matches_expected="N/A"

        else:
            # Diffusion unprocessed resource does not exist
            processed_resource_exists = "---"
            processed_resource_date   = "---"
            files_exist = "---"
            expected_size_str = "---"
            matches_expected = "---"
        
        output_str = subject.project + "\t"
        output_str += subject.subject_id + "\t"
        output_str += processed_resource_exists + "\t"
        output_str += processed_resource_date + "\t"
        output_str += files_exist + "\t"
        output_str += expected_size_str + "\t"
        output_str += matches_expected

        if files_exist == "FALSE":
            incomplete_file.write(output_str + os.linesep)
        else:
            complete_file.write(output_str + os.linesep)

        print(output_str)
                



