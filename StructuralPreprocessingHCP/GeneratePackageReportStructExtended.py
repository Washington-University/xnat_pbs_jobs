#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import os
import sys

# import of third party modules
# None

# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create and configure a module logger
log = logging.getLogger(__file__)
log.setLevel(logging.INFO)
sh = logging.StreamHandler()
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(sh)

DNM = "---"  # Does Not Matter
NA = "N/A"   # Not Available

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
    print("Structural Preproc Resource Date", end="\t")
    print("Package Path", end="\t")
    print("Package Exists", end="\t")
    print("Package Date", end="\t")
    print("Package Size", end="\t")
    print("Package Newer Than Resource", end="\t")
    print("Checksum Exists", end="\t")
    print("Checksum Date", end="\t")
    print("Checksum Newer Than Package")

    for subject in subject_list:

        project = subject.project
        subject_id = subject.subject_id

        package_path = packages_root + os.sep + 'prerelease' + os.sep + 'zip' + os.sep + project + os.sep
        package_path += subject_id + os.sep + 'preproc' + os.sep + subject_id + '_3T_Structural_preproc_extended.zip'
        checksum_path = package_path + '.md5'

        if len(archive.available_structural_unproc_dir_fullpaths(subject)) > 0:

            if archive.does_structural_preproc_dir_exist(subject):
                preproc_date = datetime.datetime.fromtimestamp(os.path.getmtime(archive.structural_preproc_dir_fullpath(subject)))
                preproc_date_str = file_utils.getmtime_str(archive.structural_preproc_dir_fullpath(subject))

                package_exists = os.path.isfile(package_path)

                if package_exists:
                    package_date = datetime.datetime.fromtimestamp(os.path.getmtime(package_path))
                    package_date_str = file_utils.getmtime_str(package_path)
                    package_size = file_utils.human_readable_byte_size(os.path.getsize(package_path), 1000.0)
                    package_newer = package_date > preproc_date

                else:
                    # package file does not exist
                    package_date_str = NA
                    package_size = NA
                    package_newer = NA

                checksum_exists = os.path.isfile(checksum_path)

                if checksum_exists:
                    checksum_date = datetime.datetime.fromtimestamp(os.path.getmtime(checksum_path))
                    checksum_date_str = file_utils.getmtime_str(checksum_path)
                    checksum_newer = checksum_date > package_date
                else:
                    checksum_date_str = NA
                    checksum_newer = NA

            else:
                # preprocessed structural data for this subject does not exist
                preproc_date_str = NA
                package_path = DNM
                package_exist = DNM
                package_date_str = DNM
                package_size = DNM
                package_newer = DNM
                checksum_exists = DNM
                checksum_date_str = DNM
                checksum_newer = DNM

        else:
            # no unprocessed structural data exists for this subject
            preproc_date_str = DNM
            package_path = DNM
            package_exists = DNM
            package_date_str = DNM
            package_size = DNM
            package_newer = DNM
            checksum_exists = DNM
            checksum_date_str = DNM
            checksum_newer = DNM

        # Print row for this subject
        print(project, end="\t")
        print(subject_id, end="\t")
        print(preproc_date_str, end="\t")
        print(package_path, end="\t")
        print(package_exists, end="\t")
        print(package_date_str, end="\t")
        print(package_size, end="\t")
        print(package_newer, end="\t")
        print(checksum_exists, end="\t")
        print(checksum_date_str, end="\t")
        print(checksum_newer)
