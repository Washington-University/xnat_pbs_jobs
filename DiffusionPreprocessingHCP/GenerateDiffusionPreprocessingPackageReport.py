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

    print("Project",                     end="\t")
    print("Subject ID",                  end="\t")
    print("Preproc Resource Date",       end="\t")
    print("Package Path",                end="\t")
    print("Package Exists",              end="\t")
    print("Package Date",                end="\t")
    print("Package Size",                end="\t")
    print("Package Newer Than Resource", end="\t")
    print("Checksum Exists",             end="\t")
    print("Checksum Date",               end="\t")
    print("Checksum Newer Than Package")

    for subject in subject_list:

        project = subject.project
        subject_id = subject.subject_id

        package_path = packages_root + os.sep + 'prerelease' + os.sep + 'zip' + os.sep + project + \
            os.sep + subject_id + os.sep + 'preproc' + os.sep + subject_id + '_3T_Diffusion_preproc.zip'
        checksum_path = package_path + '.md5'

        if archive.does_diffusion_unproc_dir_exist(subject):

            if archive.does_diffusion_preproc_dir_exist(subject):

                preproc_date     = datetime.datetime.fromtimestamp(os.path.getmtime(archive.diffusion_preproc_dir_fullpath(subject)))
                preproc_date_str = preproc_date.strftime(DATE_FORMAT)

                package_exists = os.path.isfile(package_path)

                if package_exists:
                    package_date     = datetime.datetime.fromtimestamp(os.path.getmtime(package_path))
                    package_date_str = package_date.strftime(DATE_FORMAT)
                    package_size     = file_utils.human_readable_byte_size(os.path.getsize(package_path), 1000.0)
                    package_newer    = package_date > preproc_date
                else:
                    package_date_str = NA
                    package_size     = NA
                    package_newer    = NA

                checksum_exists = os.path.isfile(checksum_path)

                if checksum_exists:
                    checksum_date     = datetime.datetime.fromtimestamp(os.path.getmtime(checksum_path))
                    checksum_date_str = checksum_date.strftime(DATE_FORMAT)
                    checksum_newer    = checksum_date > package_date
                else:
                    checksum_date_str = NA
                    checksum_newer    = NA

            else:
                # preprocessed diffusion data for this subject does not exist
                preproc_date_str  = NA
                package_path      = DNM
                package_exists    = DNM
                package_date_str  = DNM
                package_size      = DNM
                package_newer     = DNM
                checksum_exists   = DNM
                checksum_date_str = DNM
                checksum_newer    = DNM

        else:
            # unprocessed diffusion data for this subject does not exist
            preproc_date_str  = DNM
            package_path      = DNM
            package_exists    = DNM
            package_date_str  = DNM
            package_size      = DNM
            package_newer     = DNM
            checksum_exists   = DNM
            checksum_date_str = DNM
            checksum_newer    = DNM

        print(project,           end="\t")
        print(subject_id,        end="\t")
        print(preproc_date_str,  end="\t")
        print(package_path,      end="\t")
        print(package_exists,    end="\t")
        print(package_date_str,  end="\t")
        print(package_size,      end="\t")
        print(package_newer,     end="\t")
        print(checksum_exists,   end="\t")
        print(checksum_date_str, end="\t")
        print(checksum_newer)
