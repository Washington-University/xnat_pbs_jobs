#!/usr/bin/env python3

# import of build-in modules
import datetime
import logging
import logging.config
import os

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

# configure logging and create a module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
logger = logging.getLogger(file_utils.get_logger_name(__file__))

DNM = "---"  # Does Not Matter
NA = "N/A"  # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'


def print_header_line():
    delim = "\t"
    print("Project", end=delim)
    print("Subject ID", end=delim)
    print("bedpostX Resource Date", end=delim)
    print("Package Path", end=delim)
    print("Package Exists", end=delim)
    print("Package Date", end=delim)
    print("Package Size", end=delim)
    print("Package Newer Than Resource", end=delim)
    print("Checksum Exists", end=delim)
    print("Checksum Date", end=delim)
    print("Checksum Newer Than Package", end=delim)
    print("")


if __name__ == '__main__':

    # Get environment variables
    packages_root = os.getenv('PACKAGES_ROOT')
    if not packages_root:
        logger.info("Environment variable PACKAGES_ROOT must be set!")
        sys.exit(1)

    # Create archive access object
    archive = hcp3t_archive.Hcp3T_Archive()

    # Get list of subjects
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    logger.info("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp3t_subject.read_subject_info_list(subject_file_name, separator='\t')

    print_header_line()

    for subject in subject_list:

        project = subject.project
        subject_id = subject.subject_id

        package_path = packages_root 
        package_path += os.sep + 'prerelease' 
        package_path += os.sep + 'zip' 
        package_path += os.sep + project
        package_path += os.sep + subject_id
        package_path += os.sep + 'bedpostx'
        package_path += os.sep + subject_id + '_bedpostx.zip'

        checksum_path = package_path + '.md5'

        if archive.does_diffusion_preproc_dir_exist(subject):
            bedpostx_date = datetime.datetime.fromtimestamp(os.path.getmtime(archive.bedpostx_dir_fullpath(subject)))
            bedpostx_date_str = bedpostx_date.strftime(DATE_FORMAT)

            package_exists = os.path.isfile(package_path)

            if package_exists:
                package_date = datetime.datetime.fromtimestamp(os.path.getmtime(package_path))
                package_date_str = package_date.strftime(DATE_FORMAT)
                package_size = file_utils.human_readable_byte_size(os.path.getsize(package_path), 1000.0)
                package_newer = package_date > bedpostx_date

            else:
                # package file does not exist (but should)
                package_date_str = NA
                package_size = NA
                package_newer = NA

            checksum_exists = os.path.isfile(checksum_path)

            if checksum_exists:
                checksum_date = datetime.datetime.fromtimestamp(os.path.getmtime(checksum_path))
                checksum_date_str = checksum_date.strftime(DATE_FORMAT)
                checksum_newer = checksum_date > package_date
            else:
                checksum_date_str = NA
                checksum_newer = NA

        else:
            # preprocessed diffusion data for this subject does not exist
            bedpostx_date_str = DNM
            package_path = DNM
            package_exists = DNM
            package_date_str = DNM
            package_size = DNM
            package_newer = NA
            checksum_exists = DNM
            checksum_date_str = DNM
            checksum_newer = DNM

        delim="\t"
        print(project, end=delim)
        print(subject_id, end=delim)
        print(bedpostx_date_str, end=delim)
        print(package_path, end=delim)
        print(package_exists, end=delim)
        print(package_date_str, end=delim)
        print(package_size, end=delim)
        print(package_newer, end=delim)
        print(checksum_exists, end=delim)
        print(checksum_date_str, end=delim)
        print(checksum_newer, end=delim)
        print("")
