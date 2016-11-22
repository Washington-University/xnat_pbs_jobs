#!/usr/bin/env python3

"""
Abstract Base Class for One Subject Completion Checker classes
"""

# import of built-in modules
import abc
import logging
import os


# import of third party modules
# None


# import of local modules
# None


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


# create and configure a module logger
module_logger = logging.getLogger(__file__)
module_logger.setLevel(logging.INFO)
sh = logging.StreamHandler()
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
module_logger.addHandler(sh)


class OneSubjectCompletionChecker(abc.ABC):
    """Abstract base class for classes that are used to check the completion
       of pipeline processing for one subject
    """

    @abc.abstractmethod
    def does_processed_resource_exist(self, archive, subject_info):
        pass

    @abc.abstractmethod
    def is_processing_complete(self, archive, subject_info, verbose):
        pass

    def do_all_files_exist(self, file_name_list, verbose=False):
        for file_name in file_name_list:
            if verbose:
                module_logger.info("Checking for existence of file: " + file_name)
            if os.path.isfile(file_name):
                continue
            # If we get here, the most recently checked file does not exist
            module_logger.info("FILE DOES NOT EXIST: " + file_name)
            return False

        # If we get here, we've cycled through all the files and
        # all of them exist.
        return True
