#!/usr/bin/env python3

"""
Abstract Base Class for One Subject Prerequisites Checker Classes
"""

# import of built-in modules
import abc

# import of third-party modules

# import of local modules

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

class OneSubjectPrereqChecker(abc.ABC):
    """
    Abstract base class for classes that are used to check for prerequisites
    for running a particular pipeline's processing for one subject
    """

    @abc.abstractmethod
    def are_prereqs_met(self, archive, subject_info, verbose):
        pass
