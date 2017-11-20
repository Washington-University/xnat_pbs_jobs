#!/usr/bin/env python3

"""
Abstract Base Class for objects used to get (copy of link) a CinaB style directory tree
of data for a specified subject within a specified project.
"""


# import of built-in modules
import abc
import logging
import os
import subprocess

# import of third-party modules

# import of local modules
import utils.debug_utils as debug_utils
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
module_logger.setLevel(logging.WARNING)  # Note: This can be overriddent by log file configuration
print("module_logger.name = " + module_logger.name)

class CinabStyleDataRetriever(abc.ABC):

    def __init__(self, archive):
        self._archive = archive

        # indication of whether data should be copied
        # False ==> symbolic links will be created
        # True  ==> data will be copied
        self._copy = False

        # indication of whether logging of files copied
        # or linked should be shown
        self._show_log = False

    @property
    def archive(self):
        return self._archive

    @property
    def copy(self):
        return self._copy

    @copy.setter
    def copy(self, value):
        if not isinstance(value, bool):
            raise TypeError("copy must be set to a boolean value")
        self._copy = value

    @property
    def show_log(self):
        return self._show_log

    @show_log.setter
    def show_log(self, value):
        if not isinstance(value, bool):
            raise TypeError("show_log must be set to a boolean value")
        self._show_log = value

    def _from_to(self, get_from, put_to):
        module_logger.debug(debug_utils.get_name() + " get_from: " + get_from + " put_to: " + put_to)
        if self.copy:
            module_logger.debug(debug_utils.get_name() + " copying")
            os.makedirs(put_to, exist_ok=True)

            if self.show_log:
                rsync_cmd = 'rsync -auLv '
            else:
                rsync_cmd = 'rsync -auL '

            rsync_cmd += get_from + os.sep + '*' + ' ' + put_to
            module_logger.info("rsync_cmd: " + rsync_cmd)

            completed_rsync_process = subprocess.run(
                rsync_cmd, shell=True, check=True,
                stdout=subprocess.PIPE, universal_newlines=True)
            module_logger.info(completed_rsync_process.stdout)

        else:
            module_logger.debug(debug_utils.get_name() + " linking")
            os.makedirs(put_to, exist_ok=True)
            os_utils.lndir(get_from, put_to, self.show_log, ignore_existing_dst_files=True)

    def get_functional_unproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_functional_unproc_dir_fullpaths(subject_info):

            get_from = directory

            last_sep_loc = get_from.rfind(os.sep)
            unproc_loc = get_from.rfind('_' + self.archive.UNPROC_SUFFIX)
            sub_dir = get_from[last_sep_loc + 1:unproc_loc]
            put_to = output_study_dir + os.sep + subject_info.subject_id + os.sep + 'unprocessed' + os.sep + \
                self.archive.TESLA_SPEC + os.sep + sub_dir

            self._from_to(get_from, put_to)

    def get_diffusion_unproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_diffusion_unproc_dir_fullpaths(subject_info):

            get_from = directory

            last_sep_loc = get_from.rfind(os.sep)
            unproc_loc = get_from.rfind('_' + self.archive.UNPROC_SUFFIX)
            sub_dir = get_from[last_sep_loc + 1:unproc_loc]
            put_to = output_study_dir + os.sep + subject_info.subject_id + os.sep + 'unprocessed' + os.sep + \
                self.archive.TESLA_SPEC + os.sep + sub_dir

            self._from_to(get_from, put_to)

    @abc.abstractmethod
    def get_unproc_data(self, subject_info, output_study_dir):
        raise NotImplementedError()

    def get_functional_preproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_functional_preproc_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_diffusion_preproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_diffusion_preproc_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_icafix_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_FIX_processed_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id + os.sep + 'MNINonLinear' + os.sep + 'Results'
            self._from_to(get_from, put_to)

    def get_multirun_icafix_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_MultiRun_FIX_processed_dir_fullpaths(subject_info):

            get_from = directory + os.sep + subject_info.subject_id
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_taskfmri_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_task_processed_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_postfix_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_PostFix_processed_dirs(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_resting_state_stats_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_RSS_processed_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_handreclassification_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_handreclassification_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir
            self._from_to(get_from, put_to)

    def get_apply_hand_reclassification_data(self, subject_info, output_study_dir):
        module_logger.debug(debug_utils.get_name())
        for directory in self.archive.available_apply_handreclassification_dir_fullpaths(subject_info):

            get_from = directory
            module_logger.debug(debug_utils.get_name() + " get_from: " + get_from)
            put_to = output_study_dir
            self._from_to(get_from, put_to)

    def get_msmall_reg_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_msmall_reg_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_msmall_dedrift_and_resample_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_DeDriftAndResample_processed_dirs(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_bedpostx_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_diffusion_bedpostx_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    @abc.abstractmethod
    def get_preproc_data(self, subject_info, output_study_dir):
        raise NotImplementedError()

    @abc.abstractmethod
    def get_full_data(self, subject_info, output_study_dir):
        raise NotImplementedError()

    def get_diffusion_preproc_vetting_data(self, subject_info, output_study_dir):

        if not self.copy:
            self.get_diffusion_preproc_data(subject_info, output_study_dir)
            self.get_unproc_data(subject_info, output_study_dir)

        else:
            self.get_unproc_data(subject_info, output_study_dir)
            self.get_diffusion_preproc_data(subject_info, output_study_dir)

    def remove_pbs_job_files(self, directory):
        cmd = 'find ' + directory + ' -name "*XNAT_PBS*_job.sh*" -delete'
        completed_process = subprocess.run(
            cmd, shell=True, check=True, stdout=subprocess.PIPE,
            universal_newlines=True)

        cmd = 'find ' + directory + ' -name "*.starttime" -delete'
        completed_process = subprocess.run(
            cmd, shell=True, check=True, stdout=subprocess.PIPE,
            universal_newlines=True)

        cmd = 'find ' + directory + ' -name "StructuralHCP.log" -delete'
        completed_process = subprocess.run(
            cmd, shell=True, check=True, stdout=subprocess.PIPE,
            universal_newlines=True)

        cmd = 'find ' + directory + ' -name "StructuralHCP.err" -delete'
        completed_process = subprocess.run(
            cmd, shell=True, check=True, stdout=subprocess.PIPE,
            universal_newlines=True)
        
        return

    def remove_xnat_catalog_files(self, directory):
        cmd = 'find ' + directory + ' -name "*_catalog.xml" -delete'
        completed_process = subprocess.run(
            cmd, shell=True, check=True, stdout=subprocess.PIPE,
            universal_newlines=True)

        cmd = 'find ' + directory + ' -name "*_Provenance.xml" -delete'
        completed_process = subprocess.run(
            cmd, shell=True, check=True, stdout=subprocess.PIPE,
            universal_newlines=True)

        return

    
    
