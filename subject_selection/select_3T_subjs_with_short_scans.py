#!/usr/bin/env python3

# import of built-in modules
import os
import sys
import subprocess

# import of third party modules
pass

# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def _inform(msg):
    """Inform the user by writing out a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    #print(os.path.basename(__file__) + ": " + msg)
    print(msg)


def get_volume_count(file_name):
    
    cmd = 'fslinfo ' + file_name
    cmd += " | grep dim4 | head -1 | tr -s ' ' | cut -d ' ' -f 2"

    completed_process = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
    volume_count = int(completed_process.stdout)
    return volume_count


def get_expected_volume_count(file_name):
    file_base_name = os.path.basename(file_name)
    #_inform("file_base_name: " + file_base_name)
    (subject_id, session_classifier, dwi, dircount_str, pe_dir_and_suffix) = file_base_name.split('_')
    dircount_str = dircount_str[3:]
    #_inform("dircount_str: " + dircount_str)
    return int(dircount_str)


def main():
    archive = hcp3t_archive.Hcp3T_Archive()

    project_names = ['HCP_500', 'HCP_900']
    
    for project_name in project_names:

        subject_ids = archive.available_subject_ids(project_name)

        for subject_id in subject_ids:
            subject_info = hcp3t_subject.Hcp3TSubjectInfo(project_name, subject_id)
            available_diffusion_scan_fullpaths = archive.available_diffusion_scan_fullpaths(subject_info)

            for diffusion_scan in available_diffusion_scan_fullpaths:
                #_inform("")
                volume_count = get_volume_count(diffusion_scan)
                #_inform("diffusion_scan: " + diffusion_scan + " volume_count: " + str(volume_count))
                expected_volume_count = get_expected_volume_count(diffusion_scan)
                #_inform("diffusion_scan: " + diffusion_scan + " expected_volume_count: " + str(expected_volume_count))

                if volume_count != expected_volume_count:
                    _inform("diffusion_scan: " + os.path.basename(diffusion_scan) + 
                            " has expected volume count: " + str(expected_volume_count) +
                            " and actual volume count: " + str(volume_count))


if __name__ == "__main__":
    main()
