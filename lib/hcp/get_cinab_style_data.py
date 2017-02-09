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


# import of third party modules
# None


# import of local modules
import utils.os_utils as os_utils


#
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

        if self.copy:
            os.makedirs(put_to, exist_ok=True)

            if self.show_log:
                rsync_cmd = 'rsync -auLv '
            else:
                rsync_cmd = 'rsync -auL '

            rsync_cmd += get_from + os.sep + '*' + ' ' + put_to
            log.info("rsync_cmd: " + rsync_cmd)

            completed_rsync_process = subprocess.run(rsync_cmd, shell=True, check=True,
                                                     stdout=subprocess.PIPE, universal_newlines=True)
            log.info(completed_rsync_process.stdout)

        else:
            os.makedirs(put_to, exist_ok=True)
            os_utils.lndir(get_from, put_to, self.show_log, ignore_existing_dst_files=True)

    def get_functional_unproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_functional_unproc_dir_fullpaths(subject_info):

            get_from = directory

            last_sep_loc = get_from.rfind(os.sep)
            unproc_loc = get_from.rfind('_' + self.archive.UNPROC_SUFFIX)
            sub_dir = get_from[last_sep_loc+1:unproc_loc]
            put_to = output_study_dir + os.sep + subject_info.subject_id + os.sep + 'unprocessed' + os.sep + \
                self.archive.TESLA_SPEC + os.sep + sub_dir

            self._from_to(get_from, put_to)

    def get_diffusion_unproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_diffusion_unproc_dir_fullpaths(subject_info):

            get_from = directory

            last_sep_loc = get_from.rfind(os.sep)
            unproc_loc = get_from.rfind('_' + self.archive.UNPROC_SUFFIX)
            sub_dir = get_from[last_sep_loc+1:unproc_loc]
            put_to = output_study_dir + os.sep + subject_info.subject_id + os.sep + 'unprocessed' + os.sep + \
                self.archive.TESLA_SPEC + os.sep + sub_dir

            self._from_to(get_from, put_to)

    @abc.abstractmethod
    def get_unproc_data(self, subject_info, output_study_dir):
        raise NotImplementedError

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
        raise NotImplementedError

    @abc.abstractmethod
    def get_full_data(self, subject_info, output_study_dir):
        raise NotImplementedError

    def get_diffusion_preproc_vetting_data(self, subject_info, output_study_dir):

        if not self.copy:
            self.get_diffusion_preproc_data(subject_info, output_study_dir)
            self.get_unproc_data(subject_info, output_study_dir)

        else:
            self.get_unproc_data(subject_info, output_study_dir)
            self.get_diffusion_preproc_data(subject_info, output_study_dir)

    def clean_xnat_specific_files(self, output_study_dir):
        for root, dirs, files in os.walk(output_study_dir):
            for filename in files:
                fullpath = '%s/%s' % (root, filename)
                xnat_catalog_suffix = 'catalog.xml'
                cat_loc = fullpath.rfind(xnat_catalog_suffix)

                provenance_marker = 'Provenance.xml'

                if cat_loc == len(fullpath) - len(xnat_catalog_suffix):
                    # This is an XNAT resource catalog file. It should be removed.
                    os.remove(fullpath)

                elif provenance_marker in fullpath:
                    # This is a provenance file. It should be removed.
                    os.remove(fullpath)

    def clean_pbs_job_logs(self, output_study_dir):
        for root, dirs, files in os.walk(output_study_dir):
            for filename in files:
                fullpath = '%s/%s' % (root, filename)
                pbs_job_marker = 'XNAT_PBS_job'

                if pbs_job_marker in fullpath:
                    os.remove(fullpath)
