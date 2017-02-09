#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import logging.config
import os
import sys

# import of third party modules
# None

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create and configure a module logger
logging.config.fileConfig(file_utils.get_logging_config_file_name(__file__))
log = logging.getLogger(file_utils.get_logger_name(__file__))

DNM = "---"  # Does Not Matter
NA = "N/A"  # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'

def print_header_line():
    delim = "\t"
    print("Project", end=delim)
    print("Reference Project", end=delim)
    print("Subject ID", end=delim)
    print("Package Path", end=delim)
    print("Package Exists", end=delim)
    print("Package Date", end=delim)
    print("Package Size", end=delim)
    print("Checksum Exists", end=delim)
    print("Checksum Date", end=delim)
    print("Checksum Newer Than Package")


def print_data_line(project, ref_project, subject_id, package_path, package_exists, package_date_str, package_size, checksum_exists, checksum_date_str, checksum_newer):
    delim = "\t"
    print(project, end=delim)
    print(ref_project, end=delim)
    print(subject_id, end=delim)
    print(package_path, end=delim)
    print(package_exists, end=delim)
    print(package_date_str, end=delim)
    print(package_size, end=delim)
    print(checksum_exists, end=delim)
    print(checksum_date_str, end=delim)
    print(checksum_newer)


if __name__ == '__main__':

    # Get environment variables
    packages_root = os.getenv('PACKAGES_ROOT')
    if not packages_root:
        log.info("Environment variable PACKAGES_ROOT must be set!")
        sys.exit(1)

    # Create archive access object
    archive = hcp7t_archive.Hcp7T_Archive()
   
    # # Get list of subjects
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    log.info("Retrieving subject list from: " + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    print_header_line()

    for subject in subject_list:

        for modality in ['REST', 'MOVIE']:

            project = subject.project
            ref_project = subject.structural_reference_project
            subject_id = subject.subject_id

            package_path = packages_root + os.sep + 'prerelease' + os.sep + 'zip' + os.sep + project + \
                os.sep + subject_id + os.sep + 'fixextended' + os.sep + subject_id + '_' + archive.TESLA_SPEC + \
                '_' + modality + '_fixextended.zip'
            checksum_path = package_path + '.md5'
            
            package_exists = os.path.isfile(package_path)
            
            if package_exists:
                package_date = datetime.datetime.fromtimestamp(os.path.getmtime(package_path))
                package_date_str = package_date.strftime(DATE_FORMAT)
                package_size = file_utils.human_readable_byte_size(os.path.getsize(package_path), 1000.0)
            else:
                # package file does not exist
                package_date_str = NA
                package_size = NA
                
            checksum_exists = os.path.isfile(checksum_path)
                
            if checksum_exists:
                checksum_date = datetime.datetime.fromtimestamp(os.path.getmtime(checksum_path))
                checksum_date_str = checksum_date.strftime(DATE_FORMAT)
                checksum_newer = checksum_date > package_date
            else:
                checksum_date_str = NA
                checksum_newer = NA

            print_data_line(project, ref_project, subject_id, package_path, package_exists, package_date_str, package_size, 
                            checksum_exists, checksum_date_str, checksum_newer)
                

    #     if archive.does_diffusion_unproc_dir_exist(subject):

    #         if archive.does_diffusion_preproc_dir_exist(subject):

    #             preproc_date = datetime.datetime.fromtimestamp(os.path.getmtime(archive.diffusion_preproc_dir_fullpath(subject)))
    #             preproc_date_str = preproc_date.strftime(DATE_FORMAT)

    #             package_exists = os.path.isfile(package_path)

    #             if package_exists:
    #                 package_date = datetime.datetime.fromtimestamp(os.path.getmtime(package_path))
    #                 package_date_str = package_date.strftime(DATE_FORMAT)
    #                 package_size = file_utils.human_readable_byte_size(os.path.getsize(package_path), 1000.0)
    #                 package_newer = package_date > preproc_date
    #             else:
    #                 # package file does not exist
    #                 package_date_str = NA
    #                 package_size = NA
    #                 package_newer = NA

    #             checksum_exists = os.path.isfile(checksum_path)

    #             if checksum_exists:
    #                 checksum_date = datetime.datetime.fromtimestamp(os.path.getmtime(checksum_path))
    #                 checksum_date_str = checksum_date.strftime(DATE_FORMAT)
    #                 checksum_newer = checksum_date > package_date
    #             else:
    #                 checksum_date_str = NA
    #                 checksum_newer = NA

    #         else:
    #             # preprocessed diffusion data for this subject does not exist
    #             preproc_date_str = NA
    #             package_path = DNM
    #             package_exists = DNM
    #             package_date_str = DNM
    #             package_size = DNM
    #             package_newer = DNM
    #             checksum_exists = DNM
    #             checksum_date_str = DNM
    #             checksum_newer = DNM

    #     else:
    #         # unprocessed diffusion data for this subject does not exist
    #         preproc_date_str = DNM
    #         package_path = DNM
    #         package_exists = DNM
    #         package_date_str = DNM
    #         package_size = DNM
    #         package_newer = DNM
    #         checksum_exists = DNM
    #         checksum_date_str = DNM
    #         checksum_newer = DNM

    #     print(project,           end="\t")
    #     print(ref_project,       end="\t")
    #     print(subject_id,        end="\t")
    #     print(preproc_date_str,  end="\t")
    #     print(package_path,      end="\t")
    #     print(package_exists,    end="\t")
    #     print(package_date_str,  end="\t")
    #     print(package_size,      end="\t")
    #     print(package_newer,     end="\t")
    #     print(checksum_exists,   end="\t")
    #     print(checksum_date_str, end="\t")
    #     print(checksum_newer)
