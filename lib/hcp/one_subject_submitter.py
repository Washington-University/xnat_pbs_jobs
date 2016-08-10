#!/usr/bin/env python3

"""
hcp/one_subject_job_submitter.py: Abstract base class for an object
that submits jobs for a pipeline for one subject.
"""

# import of built-in modules
import os
import abc

# import of third party modules
pass

# import of local modules
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user by writing out a message that is prefixed by the module's
    file name.
    """
    print(os.path.basename(__file__) + ": " + msg)


class OneSubjectSubmitter:
    """This class is an abstract base class for classes that are used
    to submit jobs for one pipeline for one subject.
    """

    def __init__(self, archive, build_home):
        """Constructs a OneSubjectSubmitter.

        :param archive: Archive with which this submitter is to work.
        :type archive: HcpArchive

        :param build_home: path to build space
        :type build_home: str
        """
        self._archive = archive
        self._build_home = build_home

        home = os_utils.getenv_required('HOME')
        self._xnat_pbs_jobs_home = home + os.sep 
        self._xnat_pbs_jobs_home += 'pipeline_tools' + os.sep 
        self._xnat_pbs_jobs_home += 'xnat_pbs_jobs'

        self._log_dir = os_utils.getenv_required('LOG_DIR')

    @property
    @abc.abstractmethod
    def PIPELINE_NAME(self):
        pass

    @property
    def archive(self):
        """Returns the archive with which this submitter is to work."""
        return self._archive

    @property
    def build_home(self):
        """Returns the temporary (e.g. build space) root directory."""
        return self._build_home

    @property
    def xnat_pbs_jobs_home(self):
        """Returns the home directory for the XNAT PBS job scripts."""
        return self._xnat_pbs_jobs_home

    @property
    def log_dir(self):
        """Returns the directory in which to place PUT logs."""
        return self._log_dir
