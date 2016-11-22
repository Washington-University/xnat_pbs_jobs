#!/usr/bin/env python3

"""
hcp.hcp3t.diffusion_preprocessing.output_size_checker.py
"""

# import of built-in modules
import logging
import os
import re
import subprocess
import sys


# import of third party modules
# None


# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject
import utils.my_argparse as my_argparse
import utils.str_utils as str_utils


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


class NoDiffusionPreprocResource(Exception):
    pass


class DiffusionOutputSizeChecker:

    @property
    def DIFFUSION_OUTPUT_DIRECTORY_NAME(self):
        return 'Diffusion'

    def _get_expected_volume_count(self, file_name):
        sum_col1 = 0
        sum_col2 = 0
        series_file = open(file_name, 'r')

        for line in series_file:
            # remove new line characters and leading and trailing spaces
            line = str_utils.remove_ending_new_lines(line).strip()
            log.debug("line: " + line)

            # get 2 values from the line
            (num1, num2) = line.split(' ')
            log.debug("num1: " + num1)
            log.debug("num2: " + num2)

            sum_col1 += int(num1)
            sum_col2 += int(num2)

        series_file.close()

        return min(sum_col1, sum_col2)

    def _determine_expected_output_volume_count(self, archive, subject_info):
        diff_preproc_resource_path = archive.diffusion_preproc_dir_fullpath(subject_info)
        log.debug("diff_preproc_resource_path: " + diff_preproc_resource_path)

        if not os.path.exists(diff_preproc_resource_path):
            raise NoDiffusionPreprocResource(diff_preproc_resource_path + " Does not Exist ")

        eddy_dir = diff_preproc_resource_path + os.sep + self.DIFFUSION_OUTPUT_DIRECTORY_NAME + os.sep + 'eddy'
        log.debug("eddy_dir: " + eddy_dir)

        # Calculate the expected volume count based on the positive series
        pos_series_vol_num_file_name = eddy_dir + os.sep + 'Pos_SeriesVolNum.txt'
        log.debug("reading from: " + pos_series_vol_num_file_name)
        pos_series_expected_vol_count = self._get_expected_volume_count(pos_series_vol_num_file_name)

        # Calculate the expected volume count based on the negative series
        neg_series_vol_num_file_name = eddy_dir + os.sep + 'Neg_SeriesVolNum.txt'
        log.debug("reading from: " + neg_series_vol_num_file_name)
        neg_series_expected_vol_count = self._get_expected_volume_count(neg_series_vol_num_file_name)

        if pos_series_expected_vol_count != neg_series_expected_vol_count:
            raise ValueError("Expected volume count based on positive series: " +
                             pos_series_expected_vol_count +
                             " not equal to expected volume count based on negative series: " +
                             neg_series_expected_vol_count)

        return pos_series_expected_vol_count

    def _get_volume_count(self, file_name):

        if not os.path.isfile(file_name):
            return 0

        cmd = 'fslinfo ' + file_name + ' | grep dim4 | grep -v pix'
        completed_process = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE,
                                           universal_newlines=True)
        # remove new line characters and leading and trailing spaces
        output = str_utils.remove_ending_new_lines(completed_process.stdout).strip()
        # collapse whitespace to single spaces
        output = re.sub('\W+', ' ', output)
        log.debug("output: " + output)

        (name, value) = output.split(' ')
        log.debug("name: " + name)
        log.debug("value: " + value)

        return int(value)

    def _get_diffusion_preproc_data_volume_count(self, archive, subject_info):
        diff_preproc_resource_path = archive.diffusion_preproc_dir_fullpath(subject_info)
        log.debug("diff_preproc_resource_path: " + diff_preproc_resource_path)

        if not os.path.exists(diff_preproc_resource_path):
            raise NoDiffusionPreprocResource(diff_preproc_resource_path + " Does not Exist ")

        file_name = diff_preproc_resource_path + os.sep + self.DIFFUSION_OUTPUT_DIRECTORY_NAME
        file_name += os.sep + 'data' + os.sep + 'data.nii.gz'
        log.debug("file_name: " + file_name)

        return self._get_volume_count(file_name)

    def _get_T1w_diffusion_preproc_data_volume_count(self, archive, subject_info):
        diff_preproc_resource_path = archive.diffusion_preproc_dir_fullpath(subject_info)
        log.debug("diff_preproc_resource_path: " + diff_preproc_resource_path)

        if not os.path.exists(diff_preproc_resource_path):
            raise RuntimeError(diff_preproc_resource_path + " Does not Exist ")

        file_name = diff_preproc_resource_path + os.sep + 'T1w' + os.sep + self.DIFFUSION_OUTPUT_DIRECTORY_NAME
        file_name += os.sep + 'data.nii.gz'
        log.debug("file_name: " + file_name)

        return self._get_volume_count(file_name)

    def check_diffusion_preproc_size(self, archive, subject_info):
        log.debug("archive: " + str(archive))
        log.debug("subject_info: " + str(subject_info))

        success = True
        message = ''

        expected_output_volume_count = self._determine_expected_output_volume_count(archive, subject_info)
        log.debug("expected_output_volume_count: " + str(expected_output_volume_count))

        diff_preproc_count = self._get_diffusion_preproc_data_volume_count(archive, subject_info)
        log.debug("diff_preproc_count: " + str(diff_preproc_count))
        T1w_diff_preproc_count = self._get_T1w_diffusion_preproc_data_volume_count(archive, subject_info)
        log.debug("T1w_diff_preproc_count: " + str(T1w_diff_preproc_count))

        if diff_preproc_count != expected_output_volume_count:
            log.debug("Diffusion Preproc Volume Count: " + str(diff_preproc_count) +
                      " != Expected Value: " + str(expected_output_volume_count))
            message += " Diffusion Volume Count: " + str(diff_preproc_count)
            success = False

        if T1w_diff_preproc_count != expected_output_volume_count:
            log.debug("T1w Diffusion Preproc Volume Count: " + str(T1w_diff_preproc_count) +
                      " != Expected Value: " + str(expected_output_volume_count))
            message += " T1w Diffusion Volume Count: " + str(T1w_diff_preproc_count)
            success = False

        return (success, expected_output_volume_count, message)


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
    archive = hcp3t_archive.Hcp3T_Archive()

    # Create a list of subjects to process
    subject_list = _build_subject_list(archive, args.project, args.subject)

    all_succeeded = True

    # Create a DiffusionOutputSizeChecker
    size_checker = DiffusionOutputSizeChecker()

    print("Subject\tExpected Volumes\tCheck Success")
    for subject in subject_list:
        subject_info = hcp3t_subject.Hcp3TSubjectInfo(args.project, subject)

        try:
            # check the diffusion preprocessing size for the specified subject
            (success, expected_size, msg) = size_checker.check_diffusion_preproc_size(archive, subject_info)
            print(subject_info.subject_id + "\t" + str(expected_size) + "\t" + str(success) + "\t" + msg)
            all_succeeded = all_succeeded and success
        except NoDiffusionPreprocResource as e:
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
