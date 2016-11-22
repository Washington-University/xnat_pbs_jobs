#!/usr/bin/env python3

"""
hcp.hcp7t.diffusion_preprocessing.output_size_checker.py
"""

# import of built-in modules
import logging
import sys


# import of third party modules
# None


# import of local modules
import hcp.hcp3t.diffusion_preprocessing.output_size_checker as hcp3t_output_size_checker
import hcp.hcp7t.archive as hcp7t_archive
import utils.my_argparse as my_argparse


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


class DiffusionOutputSizeChecker(hcp3t_output_size_checker.DiffusionOutputSizeChecker):

    @property
    def DIFFUSION_OUTPUT_DIRECTORY_NAME(self):
        return 'Diffusion_7T'


def _build_subject_list(archive, project, subject):
    subject_list = []
    if (subject == 'all'):
        subject_list = archive.available_subject_ids(project)
    else:
        subject_list.append(subject)

    return subject_list


def main():
    # create a parser object for getting the command line options
    parser = my_argparse.MyArgumentParser(description="Program to check Diffusion Preprocessing Output size")

    # mandatory arguments
    parser.add_argument('-p', '--project', dest='project', required=True, type=str)

    # optional arguments
    parser.add_argument('-s', '--subject', dest='subject', required=False, default='all', type=str)

    # parse the command line arguments
    args = parser.parse_args()

    # show parsed arguments
    log.debug("Project: " + args.project)
    log.debug("Subject: " + args.subject)

    # create archive
    archive = hcp7t_archive.Hcp7T_Archive()

    # create a list of subjects to process
    subject_list = _build_subject_list(archive, args.project, args.subject)

    all_succeeded = True

    # Create a DiffusionOutputSizeChecker
    size_checker = DiffusionOutputSizeChecker()

    print("Subject\tExpected Volumes\tCheck Success")
    for subject in subject_list:
        subject_info = hcp7t_subject.Hcp7TSubjectInfo(args.project, None, subject)

        try:
            # check the diffusion preprocessing size for the specified subject
            (success, expected_size, msg) = size_checker.check_diffusion_preproc_size(archive, subject_info)
            print(subject_info.subject_id + "\t" + str(expected_size) + "\t" + str(success) + "\t" + msg)
            all_succeeded = all_succeeded and success
        except hcp3t_output_size_checker.NoDiffusionPreprocResource as e:
            print(subject_info.subject_id + "\t" + "N/A" + "\t" + "N/A" + "\t" + "No Diff Preproc Resource")
            all_succeeded = False
        except FileNotFoundError as e:
            print(subject_info.subject_id + "\t" + "N/A" + "\t" + "N/A" + "\t" + "A necessary output file was not found")
            all_succeeded = False

    return all_succeeded


if __name__ == '__main__':
    if main():
        sys.exit(0)
    else:
        sys.exit(1)
