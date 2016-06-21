#!/usr/bin/env python3

import os
import sys
import glob
import hcp7t_subject

sys.path.append('../../lib')
import xnat_archive

FUNCTIONAL_SCAN_MARKER = 'fMRI'
UNPROC_SUFFIX = 'unproc'
PREPROC_SUFFIX = 'preproc'
FIX_PROCESSED_SUFFIX = 'FIX'
NAME_DELIMITER = '_'
TESLA_SPEC='7T'

class Hcp7T_Archive:

    def __init__(self):
        self.__xnat_archive = xnat_archive.XNAT_Archive()

    def session_name(self, hcp7t_subject_info):
        return hcp7t_subject_info.subject_id + NAME_DELIMITER + TESLA_SPEC

    def session_dir(self, hcp7t_subject_info):
        return self.__xnat_archive.project_archive_root(hcp7t_subject_info.project) + '/' + self.session_name(hcp7t_subject_info)

    def subject_resources_dir(self, hcp7t_subject_info):
        return self.session_dir(hcp7t_subject_info) + '/RESOURCES'

    def available_functional_unproc_dirs(self, hcp7t_subject_info):
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + FUNCTIONAL_SCAN_MARKER + '*' + UNPROC_SUFFIX) 
        return sorted(dir_list)

    def available_functional_unproc_names(self, hcp7t_subject_info):
        dir_list = self.available_functional_unproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            short_dir = os.path.basename(directory)
            last_char = short_dir.rfind(NAME_DELIMITER)
            name = short_dir[:last_char]
            name_list.append(name)
        return name_list

    def available_diffusion_unproc_dirs(self, hcp7t_subject_info):
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/Diffusion*' + UNPROC_SUFFIX)
        return sorted(dir_list)

    def available_diffusion_unproc_names(self, hcp7t_subject_info):
        dir_list = self.available_diffusion_unproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            short_dir = os.path.basename(directory)
            last_char = short_dir.rfind(NAME_DELIMITER)
            name = short_dir[:last_char]
            name_list.append(name)
        return name_list

    def available_functional_preproc_dirs(self, hcp7t_subject_info):
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + FUNCTIONAL_SCAN_MARKER + '*' + PREPROC_SUFFIX) 
        return sorted(dir_list)

    def available_functional_preproc_names(self, hcp7t_subject_info):
        dir_list = self.available_functional_preproc_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            short_dir = os.path.basename(directory)
            last_char = short_dir.rfind(NAME_DELIMITER)
            name = short_dir[:last_char]
            name_list.append(name)
        return name_list

    def does_functional_preproc_exist(self, hcp7t_subject_info, scan_name):
        return scan_name in self.available_functional_preproc_names(hcp7t_subject_info)

    def functionally_preprocessed(self, hcp7t_subject_info, scan_name):
        return self.does_functional_preproc_exist(hcp7t_subject_info, scan_name)

    def available_FIX_processed_dirs(self, hcp7t_subject_info):
        dir_list = glob.glob(self.subject_resources_dir(hcp7t_subject_info) + '/*' + FUNCTIONAL_SCAN_MARKER + '*' + FIX_PROCESSED_SUFFIX)
        return sorted(dir_list)

    def available_FIX_processed_names(self, hcp7t_subject_info):
        dir_list = self.available_FIX_processed_dirs(hcp7t_subject_info)
        name_list = []
        for directory in dir_list:
            short_dir = os.path.basename(directory)
            last_char = short_dir.rfind(NAME_DELIMITER)
            name = short_dir[:last_char]
            name_list.append(name)
        return name_list

    def functional_scan_prefix(self, functional_scan_name):
        # example: functional_scan_name = rfMRI_REST3_PA
        (prefix, base_name, pe_dir) = functional_scan_name.split(NAME_DELIMITER)
        return prefix

    def functional_scan_base_name(self, functional_scan_name):
        # example: functional_scan_name = rfMRI_REST3_PA
        (prefix, base_name, pe_dir) = functional_scan_name.split(NAME_DELIMITER)
        return base_name

    def functional_scan_pe_dir(self, functional_scan_name):
        # example: functional_scan_name = rfMRI_REST3_PA
        (prefix, base_name, pe_dir) = functional_scan_name.split(NAME_DELIMITER)
        return pe_dir

    def functional_scan_long_name(self, functional_scan_name):
        # example: functional_scan_name = rfMRI_REST3_PA
        (prefix, base_name, pe_dir) = functional_scan_name.split(NAME_DELIMITER)
        return prefix + NAME_DELIMITER + base_name + NAME_DELIMITER + TESLA_SPEC + NAME_DELIMITER + pe_dir
    

if __name__ == "__main__":

    hcp7t_archive = Hcp7T_Archive()
    
    subject = hcp7t_subject.Hcp7TSubjectInfo('HCP_Staging_7T', 'HCP_500', '102311')
    print('HCP7T session dir: ' + hcp7t_archive.session_dir(subject))

    print(os.linesep + 'Available functional unproc dirs: ')
    for directory in hcp7t_archive.available_functional_unproc_dirs(subject):
        print(directory)

    print(os.linesep + 'Available functional unproc scan names: ')
    for name in hcp7t_archive.available_functional_unproc_names(subject):
        print(name)
    
    print(os.linesep + 'Available diffusion unproc dirs: ')
    for directory in hcp7t_archive.available_diffusion_unproc_dirs(subject):
        print(directory)

    print(os.linesep + 'Available diffusion unproc scan names: ')
    for name in hcp7t_archive.available_diffusion_unproc_names(subject):
        print(name)

    print(os.linesep + 'Available functional preproc dirs: ')
    for directory in hcp7t_archive.available_functional_preproc_dirs(subject):
        print(directory)

    print(os.linesep + 'Available functional preproc scan names: ')
    for name in hcp7t_archive.available_functional_preproc_names(subject):
        print(name)

    print(os.linesep + 'Are the following functional scans preprocessed')
    for name in hcp7t_archive.available_functional_unproc_names(subject):
        print('scan name: ' + name + ' ' + '\tfunctionally preprocessed: ' + str(hcp7t_archive.functionally_preprocessed(subject, name)))

    print(os.linesep + 'Available FIX processed dirs: ')
    for directory in hcp7t_archive.available_FIX_processed_dirs(subject):
        print(directory)

    print(os.linesep + 'Available FIX processed scan names: ')
    for name in hcp7t_archive.available_FIX_processed_names(subject):
        print(os.linesep + name)
        print('prefix: ' + hcp7t_archive.functional_scan_prefix(name))
        print('base_name: ' + hcp7t_archive.functional_scan_base_name(name))
        print('pe_dir: ' + hcp7t_archive.functional_scan_pe_dir(name))
        print('long_name: ' + hcp7t_archive.functional_scan_long_name(name))


