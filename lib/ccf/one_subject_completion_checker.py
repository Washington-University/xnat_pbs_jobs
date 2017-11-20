#!/usr/bin/env python3

"""
Abstract Base Class for One Subject Completion Checker Classes
"""

# import of built-in modules
import abc
import os
import sys

# import of third-party modules

# import of local modules
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

class OneSubjectCompletionChecker(abc.ABC):
    """
    Abstract base class for classes that are used to check the completion
    of pipeline processing for one subject
    """

    @abc.abstractmethod
    def my_resource(self, archive, subject_info):
        pass

    @abc.abstractmethod
    def my_prerequisite_dir_full_paths(self, archive, subject_info):
        pass

    @abc.abstractmethod
    def completion_marker_file_name(self):
        pass

    @abc.abstractmethod
    def starttime_marker_file_name(self):
        pass

    @abc.abstractmethod
    def list_of_expected_files(self, archive, subject_info):
        pass
    
    def my_resource_time_stamp(self, archive, subject_info):
        return os.path.getmtime(self.my_resource(archive, subject_info))
                                
    def does_processed_resource_exist(self, archive, subject_info):
        fullpath = self.my_resource(archive, subject_info)
        return os.path.isdir(fullpath)

    def latest_prereq_resource_time_stamp(self, archive, subject_info):
        latest_time_stamp = 0
        prerequisite_dir_paths = self.my_prerequisite_dir_full_paths(archive, subject_info)

        for full_path in prerequisite_dir_paths:
            this_time_stamp = os.path.getmtime(full_path)
            if this_time_stamp > latest_time_stamp:
                latest_time_stamp = this_time_stamp

        return latest_time_stamp

    def do_all_files_exist(self, file_name_list, verbose=False, output=sys.stdout, short_circuit=True):
        return file_utils.do_all_files_exist(file_name_list, verbose, output, short_circuit)
    
    def is_processing_marked_complete(self, archive, subject_info):

        # If the processed resource does not exist, then the process is certainly not marked
        # as complete. The file that marks completeness would be in that resource.
        if not self.does_processed_resource_exist(archive, subject_info):
            return False

        resource_path = self.my_resource(archive, subject_info)
        completion_marker_file_path = resource_path + os.sep + self.completion_marker_file_name()
        starttime_marker_file_path = resource_path + os.sep + self.starttime_marker_file_name()
        
        # If the completion marker file does not exist, the the processing is certainly not marked
        # as complete.
        marker_file_exists = os.path.exists(completion_marker_file_path)
        if not marker_file_exists:
            return False

        # If the completion marker file is older than the starttime marker file, then any mark
        # of completeness is invalid.
        if not os.path.exists(starttime_marker_file_path):
            return False

        if os.path.getmtime(completion_marker_file_path) < os.path.getmtime(starttime_marker_file_path):
            return False

        # If the completion marker file does exist, then look at the contents for further
        # confirmation.

        f = open(completion_marker_file_path, "r")
        lines = f.readlines()

        if lines[-1].strip() != 'Completion Check was successful':
            return False

        return True
        
    def is_processing_complete(self, archive, subject_info,
                               verbose=False, output=sys.stdout, short_circuit=True):

        # If the processed resource does not exist, then the processing is certainly not complete.
        if not self.does_processed_resource_exist(archive, subject_info):
            if verbose:
                print("resource: " + self.my_resource(archive, subject_info) + " DOES NOT EXIST",
                      file=output)
            return False

        # If processed resource is not newer than prerequisite resources, then the processing
        # is not complete.
        resource_time_stamp = self.my_resource_time_stamp(archive, subject_info)
        latest_prereq_time_stamp = self.latest_prereq_resource_time_stamp(archive, subject_info)
        
        if resource_time_stamp <= latest_prereq_time_stamp:
            if verbose:
                print("resource: " + self.my_resource(archive, subject_info) + " IS NOT NEWER THAN ALL PREREQUISITES", file=output)
            return False

        # If processed resource exists and is newer than all the prerequisite resources, then check
        # to see if all the expected files exist
        expected_file_list = self.list_of_expected_files(archive, subject_info)
        return self.do_all_files_exist(expected_file_list, verbose, output, short_circuit)
