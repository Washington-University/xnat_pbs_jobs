#!/usr/bin/env python3

"""
one_subject_job_submitter.py: Abstract base class for an object
that submits jobs for a pipeline for one subject.
"""

# import of built-in modules
import abc
import contextlib
import os
import stat
import time

# import of third-party modules

# import of local modules
import utils.os_utils as os_utils
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user by writing out a message that is prefixed by the module's
    file name.
    """
    print(os.path.basename(__file__) + ": " + msg)


class OneSubjectJobSubmitter(abc.ABC):
    """This class is an abstract base class for classes that are used
    to submit jobs for one pipeline for one subject.
    """

    def __init__(self, archive, build_home):
        """Constructs a OneSubjectJobSubmitter.

        :param archive: Archive with which this submitter is to work.
        :type archive: HcpArchive

        :param build_home: path to build space
        :type build_home: str
        """
        self._archive = archive
        self._build_home = build_home

        # home = os_utils.getenv_required('HOME')
        # self._xnat_pbs_jobs_home = home + os.sep
        # self._xnat_pbs_jobs_home += 'pipeline_tools' + os.sep
        # self._xnat_pbs_jobs_home += 'xnat_pbs_jobs'

        self._xnat_pbs_jobs_home = os_utils.getenv_required('XNAT_PBS_JOBS')
        self._log_dir = os_utils.getenv_required('XNAT_PBS_JOBS_LOG_DIR')

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

    def build_working_directory_name(self, project, pipeline_name, subject_id, scan=None):
        current_seconds_since_epoch = int(time.time())
        wdir = self.build_home
        wdir += os.sep + project
        wdir += os.sep + pipeline_name
        wdir += '.' + subject_id
        if scan:
            wdir += '.' + scan
        wdir += '.' + str(current_seconds_since_epoch)
        return wdir

    def create_put_script(self, put_script_name, username, password, put_server, project, subject, session,
                          working_directory_name, output_resource_name, reason, leave_subject_id_level=False):

        """Create a script to put the working directory in the DB"""
        with contextlib.suppress(FileNotFoundError):
            os.remove(put_script_name)

        put_script = open(put_script_name, 'w')

        put_script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=12gb' + os.linesep)
        put_script.write('#PBS -q HCPput' + os.linesep)
        put_script.write('#PBS -o ' + self.log_dir + os.linesep)
        put_script.write('#PBS -e ' + self.log_dir + os.linesep)
        put_script.write(os.linesep)

        put_script.write(self.xnat_pbs_jobs_home + os.sep + 'WorkingDirPut' + os.sep + 'XNAT_working_dir_put.sh \\' + os.linesep)
        
        if leave_subject_id_level:
            put_script.write('  --leave-subject-id-level \\' + os.linesep)
            
        put_script.write('  --user="' + username + '" \\' + os.linesep)
        put_script.write('  --password="' + password + '" \\' + os.linesep)
        put_script.write('  --server="' + str_utils.get_server_name(put_server) + '" \\' + os.linesep)
        put_script.write('  --project="' + project + '" \\' + os.linesep)
        put_script.write('  --subject="' + subject + '" \\' + os.linesep)
        put_script.write('  --session="' + session + '" \\' + os.linesep)
        put_script.write('  --working-dir="' + working_directory_name + '" \\' + os.linesep)
        put_script.write('  --resource-suffix="' + output_resource_name + '" \\' + os.linesep)
        put_script.write('  --reason="' + reason + '"' + os.linesep)

        put_script.close()
        os.chmod(put_script_name, stat.S_IRWXU | stat.S_IRWXG)

