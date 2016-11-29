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
import utils.my_argparse as my_argparse

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

    parser = my_argparse.MyArgumentParser()

    # madatory arguments
    parser.add_argument('-s', '--scan', dest='scan', required=True, choices=['REST', 'REST1', 'REST2'], type=str)
    args = parser.parse_args()

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
    print("Last FIX Resource Date", end="\t")
    print("Package Path", end="\t")
    print("Package Exists", end="\t")
    print("Package Date", end="\t")
    print("Package Size", end="\t")
    print("Package Newer Than Last FIX Resource", end="\t")
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
        package_path += subject_id + os.sep 
        
        if args.scan == 'REST':
            package_path += 'fix' + os.sep + subject_id + '_3T_rfMRI_REST_fix.zip'
        else:
            package_path += 'fixextended' + os.sep + subject_id + '_3T_rfMRI_' + args.scan + '_fixextended.zip'

        checksum_path = package_path + '.md5'

        preproc_date = datetime.datetime.min
        preproc_exists = False

        # find out if preprocessed resting state data exists
        # and get the latest date for any preprocessed resting state data that does exist
        resting_state_preproc_dir_list = archive.available_resting_state_preproc_dirs(subject)
        for resting_state_preproc_dir in resting_state_preproc_dir_list:
            preproc_exists = True
            timestamp = os.path.getmtime(resting_state_preproc_dir)
            resting_state_preproc_date = datetime.datetime.fromtimestamp(timestamp)
            if resting_state_preproc_date > preproc_date:
                preproc_date = resting_state_preproc_date
                preproc_date_str = preproc_date.strftime(DATE_FORMAT)

        if preproc_exists:
            log.debug("some preprocessed resting state data exists")
            # If looking for extended zip packages, see if preprocessed data exists for 
            # the particular resting state scan specified
            resting_state_preproc_names = archive.available_resting_state_preproc_names(subject)
            
            resting_state_preproc_scans = set()
            for resting_state_preproc_name in resting_state_preproc_names:
                first_underscore = resting_state_preproc_name.find('_')
                last_underscore = resting_state_preproc_name.rfind('_')
                base_scan_name = resting_state_preproc_name[first_underscore:last_underscore]

            sys.exit()



        if preproc_exists:
            log.debug("preprocessed resting state data exists")

            # So we know that at least some preprocessed resting state data exists.
            # Now we need to know if resting state fixed processed data exists.
            fix_processed_date = datetime.datetime.min
            fix_processed_exists = False

            resting_state_fix_processed_dir_list = archive.available_FIX_processed_resting_state_dir_fullpaths(subject)
            for resting_state_fix_processed_dir in resting_state_fix_processed_dir_list:
                fix_processed_exists = True
                timestamp = os.path.getmtime(resting_state_fix_processed_dir)
                resting_state_fix_processed_date = datetime.datetime.fromtimestamp(timestamp)
                if resting_state_fix_processed_date > fix_processed_date:
                    fix_processed_date = resting_state_fix_processed_date
                    fix_processed_date_str = fix_processed_date.strftime(DATE_FORMAT)

            if fix_processed_exists:
                log.debug("fix processed resting state data exists")

                # So now we know that some FIX processed resting state data exists.
                # Does the package exist?

                package_exists = os.path.isfile(package_path)

                if package_exists:
                    timestamp = os.path.getmtime(package_path)
                    package_date = datetime.datetime.fromtimestamp(timestamp)
                    package_date_str = file_utils.getmtime_str(package_path)
                    package_size = file_utils.human_readable_byte_size(os.path.getsize(package_path), 1000.0)
                    package_newer = package_date > preproc_date

                else:
                    # The package does not exist, but it should. This is a problem.
                    package_date_str = NA
                    package_size = NA
                    package_newer = NA

                # We still know that at least some FIX processed resting state data exists.
                # Does the checksum file exist? (Yes, I know that if the package doesn't
                # exist, we wouldn't expect that the checksum file would exist, but it
                # is simpler to just code this as an independent check.)

                checksum_exists = os.path.isfile(checksum_path)

                if checksum_exists:
                    timestamp = os.path.getmtime(checksum_path)
                    checksum_date = datetime.datetime.fromtimestamp(timestamp)
                    checksum_date_str = file_utils.getmtime_str(checksum_path)
                    checksum_newer = checksum_date > fix_processed_date

                else:
                    # The checksum file does not exist, but it should. This is a problem.
                    checksum_date_str = NA
                    checksum_newer = NA

            else:
                # Preprocessed resting state data exists, but no fix processed resting state
                # data exists. This is a problem
                log.debug("No fix processed resting state data exists")
                fix_processed_date_str = NA
                package_path = DNM
                package_exists = DNM
                package_date_str = DNM
                package_size = DNM
                package_newer = DNM
                checksum_exists = DNM
                checksum_date_str = DNM
                checksum_newer = DNM

        else:
            log.debug("no preprocessed resting state data exists")
            fix_processed_date_str = DNM
            package_path = DNM
            package_exists = DNM
            package_date_str = DNM
            package_size = DNM
            package_newer = DNM
            checksum_exists = DNM
            checksum_date_str = DNM
            checksum_newer = DNM

        # Print content row for this subject
        print(project, end="\t")
        print(subject_id, end="\t")
        print(fix_processed_date_str, end="\t")
        print(package_path, end="\t")
        print(package_exists, end="\t")
        print(package_date_str, end="\t")
        print(package_size, end="\t")
        print(package_newer, end="\t")
        print(checksum_exists, end="\t")
        print(checksum_date_str, end="\t")
        print(checksum_newer)
