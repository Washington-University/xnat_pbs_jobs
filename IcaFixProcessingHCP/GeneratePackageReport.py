#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import os
import sys

# import of third-party modules
# None

# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create and configure a module logger
log = logging.getLogger(__file__)
log.setLevel(logging.INFO)
# log.setLevel(logging.DEBUG)
sh = logging.StreamHandler()
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(sh)

DNM = "---"  # Does Not Matter
NA = "N/A"   # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'

if __name__ == '__main__':

    # Get environment variables
    packages_root = os.getenv('PACKAGES_ROOT')
    if not packages_root:
        log.info("Environment variable PACKAGES_ROOT must be set!")
        sys.exit(1)

    # Create archive access object
    archive = hcp3t_archive.Hcp3T_Archive()
    
    # Get list of subjects
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    log.info("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp3t_subject.read_subject_info_list(subject_file_name)

    # Print header row
    print("Project", end="\t")
    print("Subject ID", end="\t")
    # print("Scan", end="\t")
    print("FIX Resource Date", end="\t")
    print("Package Path", end="\t")
    print("Package Exists", end="\t")
    print("Package Date", end="\t")
    print("Package Size", end="\t")
    print("Package Newer Than Resource", end="\t")
    print("Checksum Exists", end="\t")
    print("Checksum Date", end="\t")
    print("Checksum Newer Than Package")

    # Print space between header row and content rows
    print()

    # Print content rows
    for subject in subject_list:

        project = subject.project
        subject_id = subject.subject_id

        package_path = packages_root + os.sep + 'PostMsmAll' + os.sep + project + os.sep
        package_path += subject_id + os.sep + 'fix' + os.sep + subject_id + '_3T_rfMRI_REST_fix.zip'
        checksum_path = package_path + '.md5'

        # if there are resting state preprocessed resources
        resting_state_scan_dir_list = archive.available_resting_state_preproc_dirs(subject)
        if len(resting_state_scan_dir_list) > 0:
            for scan_dir in resting_state_scan_dir_list:
                print(scan_dir)

        sys.exit()
