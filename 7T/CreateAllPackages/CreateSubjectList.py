#!/usr/bin/env python3

# import of built-in modules
import os

# import of third party modules
# None

# import of local modules
import hcp.hcp7t.subject as hcp7t_subject


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Outputs a message that is prefixed by the module file name."""
    print(os.path.basename(__file__) + ": " + msg)


if __name__ == "__main__":

    # Get environment variables
    subject_files_dir = os.getenv('SUBJECT_FILES_DIR')
    if subject_files_dir is None:
        _inform("Environment variable SUBJECT_FILES_DIR must be set!")
        sys.exit(1)

    # Get list of all HCP7T subjects
    all_subjects_file_name = subject_files_dir + os.sep + 'FunctionalPreprocessingHCP7T.subjects.everybody'
    _inform("Retrieveing all subjects from: " + all_subjects_file_name)
    all_subjects_list = hcp7t_subject.read_subject_info_list(all_subjects_file_name)

    # _inform("all_subjects_list: " + str(all_subjects_list))

    # Get list of subject IDs that need to be packaged
    subjects_to_use_file_name = subject_files_dir + os.sep + 'CreateAllPackages.subjects'
    _inform("Retrieving subjects to use from: " + subjects_to_use_file_name)
    subject_ids_to_use_list = hcp7t_subject.read_subject_id_list(subjects_to_use_file_name)

    _inform("subject_ids_to_use_list: " + str(subject_ids_to_use_list))

    # get full subject information for all subjects that are in the subject_ids_to_use_list
    subjects_to_use_list = [subj_info for subj_info in all_subjects_list if subj_info.subject_id in subject_ids_to_use_list]

    # write out the subjects_to_use_list
    hcp7t_subject.write_subject_info_list('newlist', subjects_to_use_list)
