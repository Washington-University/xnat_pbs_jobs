#!/usr/bin/env python3

# import of built-in modules
import contextlib
import logging
import os
import stat

# import of third-party modules

# import of local modules
import ccf.one_subject_job_submitter as one_subject_job_submitter
import utils.debug_utils as debug_utils
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
module_logger.setLevel(logging.WARNING)  # Note: This can be overridden by log file configuration


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    def __init__(self, archive, build_home):
        super().__init__(archive, build_home)

    @property
    def PIPELINE_NAME(self):
        return "ReApplyFix"

    @property
    def WORK_NODE_COUNT(self):
        return 1

    @property
    def WORK_PPN(self):
        return 1

    @property
    def reg_name(self):
        return self._reg_name

    @reg_name.setter
    def reg_name(self, value):
        self._reg_name = value
        module_logger.debug(debug_utils.get_name() + ": set to " + str(value))

    def create_work_script(self):
        module_logger.debug(debug_utils.get_name())

        script_name = self.work_script_name

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        walltime_limit_str = str(self.walltime_limit_hours) + ':00:00'
        vmem_limit_str = str(self.vmem_limit_gbs) + 'gb'

        resources_line = '#PBS -l nodes=' + str(self.WORK_NODE_COUNT)
        resources_line += ':ppn=' + str(self.WORK_PPN)
        resources_line += ',walltime=' + walltime_limit_str
        resources_line += ',vmem=' + vmem_limit_str

        stdout_line = '#PBS -o ' + self.working_directory_name
        stderr_line = '#PBS -e ' + self.working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep
        script_line += self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT.sh'

        user_line = '  --user=' + self.username
        password_line = '  --password=' + self.password
        server_line = '  --server=' + str_utils.get_server_name(self.server)
        project_line = '  --project=' + self.project
        subject_line = '  --subject=' + self.subject
        session_line = '  --session=' + self.session
        scan_line = '  --scan=' + self.scan
        wdir_line = '  --working-dir=' + self.working_directory_name

        setup_line = '  --setup-script=' + self.xnat_pbs_jobs_home + os.sep + self.PIPELINE_NAME
        setup_line += os.sep + self.setup_script

        reg_name_line = '  --reg-name=' + self.reg_name

        with open(script_name, 'w') as script:
            script.write(resources_line + os.linesep)
            script.write(stdout_line + os.linesep)
            script.write(stderr_line + os.linesep)
            script.write(os.linesep)
            script.write(script_line + ' \\' + os.linesep)
            script.write(user_line + ' \\' + os.linesep)
            script.write(password_line + ' \\' + os.linesep)
            script.write(server_line + ' \\' + os.linesep)
            script.write(project_line + ' \\' + os.linesep)
            script.write(subject_line + ' \\' + os.linesep)
            script.write(session_line + ' \\' + os.linesep)
            script.write(scan_line + ' \\' + os.linesep)
            script.write(wdir_line + ' \\' + os.linesep)
            if self.reg_name != 'MSMSulc':
                script.write(reg_name_line + ' \\' + os.linesep)
            script.write(setup_line + os.linesep)

        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def output_resource_name(self):
        module_logger.debug(debug_utils.get_name())
        return self.scan + '_' + self.output_resource_suffix


