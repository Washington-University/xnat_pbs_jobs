#!/usr/bin/env python3


# import of built-in modules
import datetime
import logging
import os
import sys


# import of third party modules
pass


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
sh = logging.StreamHandler()
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(sh)

DNM = "---" # Does Not Matter
NA  = "N/A" # Not Available
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

    print("Project",    end="\t")
    print("Subject ID", end="\t")
    print("Structural Preproc Resource Date", end="\t")
    print()

    for subject in subject_list:

        project = subject.project
        subject_id = subject.subject_id

        package_path = packages_root + os.sep + 'PostMsmAll' + os.sep + project + \
            os.sep + subject_id + os.sep + 'preproc' + os.sep + \
            subject_id + '_3T_Structural_preproc.zip'
        checksum_path = package_path + '.md5'

        if len(archive.available_structural_unproc_dir_fullpaths(subject)) > 0:

            if archive.does_structural_preproc_dir_exist(subject):
                preproc_date = datetime.datetime.fromtimestamp(os.path.getmtime(archive.structural_preproc_dir_fullpath(subject)))
                preproc_date_str = preproc_date.strftime(DATE_FORMAT)

            else:
                # preprocessed structural data for this subject does not exist
                preproc_date_str = NA


    
        else:
            # no unprocessed structural data exists for this subject
            preproc_date_str = DNM


        print(project,          end="\t")
        print(subject_id,       end="\t")
        print(preproc_date_str, end="\t")
        print()
