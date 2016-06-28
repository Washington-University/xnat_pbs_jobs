#!/usr/bin/env python3

"""select_3T_subjs_with_no_dir97.py"""

# import of built-in modules
import os
import sys

# import of third party modules
pass

# import of local modules
sys.path.append(os.path.abspath('../lib'))
import hcp3t_archive
import hcp3t_subject

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def _inform(msg):
    """Inform the user by writing out a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)


def main():
    archive = hcp3t_archive.Hcp3T_Archive()

    project_name = 'HCP_500'

    subject_ids = archive.available_subject_ids(project_name)

    for subject_id in subject_ids:
        _inform("")
        _inform("subject_id: " + subject_id)

        subject_info = hcp3t_subject.Hcp3TSubjectInfo(project_name, subject_id)
        available_diffusion_scan_names = archive.available_diffusion_scan_names(subject_info)

        _inform("available diffusion scans: " + str(available_diffusion_scan_names))


if __name__ == "__main__":
    main()
