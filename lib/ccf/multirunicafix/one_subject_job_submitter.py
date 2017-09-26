#!/usr/bin/env python3

# import of built-in modules
import contextlib
import logging
import os
import stat
import time

# import of third-party modules

# import of local modules
import ccf.one_subject_job_submitter as one_subject_job_submitter
import utils.debug_utils as debug_utils
import utils.delete_resource as delete_resource
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
module_logger.setLevel(logging.WARNING)  # Note: This can be overidden by log file configuration


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    def __init__(self, archive, build_home):
        super().__init__(archive, build_home)

    @property
    def PIPELINE_NAME(self):
        return "MultiRunICAFIX"

    @property
    def groups(self):
        return self._groups

    @groups.setter
    def groups(self, value):
        self._groups = value
        module_logger.debug(debug_utils.get_name() + ": set to " + str(self._groups))

    def _add_mri_prefix(self, scan_name):
        if scan_name.startswith('REST'):
            return 'rfMRI_' + scan_name
        else:
            return 'tfMRI_' + scan_name

    def _expand(self, group):
        original_scan_name_list = group.split(sep=' ')
        new_scan_name_list = []
        for scan_name in original_scan_name_list:
            new_scan_name = self._add_mri_prefix(scan_name)
            new_scan_name_list.append(new_scan_name)

        result = ''
        for scan_name in new_scan_name_list:
            result += scan_name + '@'

        return result.strip('@')

    def _concat(self, group):
        scan_name_list = group.split(sep='@')
        core_names = []
        for scan_name in scan_name_list:
            parts = scan_name.split(sep='_')
            if parts[1] not in core_names:
                core_names.append(parts[1])

        concat_name = "_".join(core_names)

        if "REST" in concat_name:
            concat_name = "rfMRI_" + concat_name + "_RL_LR"
        else:
            concat_name = "tfMRI_" + concat_name + "_RL_LR"

        return concat_name

    @property
    def WORK_NODE_COUNT(self):
        return 1

    @property
    def WORK_PPN(self):
        return 1

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
        wdir_line = '  --working-dir=' + self.working_directory_name
        setup_line = '  --setup-script=' + self.xnat_pbs_jobs_home + os.sep + self.PIPELINE_NAME + os.sep + self.setup_script

        script = open(script_name, 'w')

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

        for group in self._group_list:
            script.write('  --group=' + group + ' \\' + os.linesep)

        for name in self._concat_name_list:
            script.write('  --concat-name=' + name + ' \\' + os.linesep)

        script.write(wdir_line + ' \\' + os.linesep)
        script.write(setup_line + os.linesep)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def submit_jobs(self, processing_stage=one_subject_job_submitter.ProcessingStage.PUT_DATA):
        module_logger.debug(debug_utils.get_name() + ": processing_stage: " + str(processing_stage))

        module_logger.info("-----")
        module_logger.info("Submitting " + self.PIPELINE_NAME + " jobs for")
        module_logger.info("  Project: " + self.project)
        module_logger.info("  Subject: " + self.subject)
        module_logger.info("  Session: " + self.session)
        module_logger.info("    Stage: " + str(processing_stage))

        # make sure working directories do not have the same name based on
        # the same start time by sleeping a few seconds
        time.sleep(5)

        # build the working directory name
        os.makedirs(name=self.working_directory_name)

        # determine output resource name
        self._output_resource_name = self.output_resource_suffix
        module_logger.info("Output Resource Name: " + self._output_resource_name)

        # clean output resource if requested
        if self.clean_output_resource_first:
            module_logger.info("Deleting resource: " + self._output_resource_name + " for:")
            module_logger.info("  project: " + self.project)
            module_logger.info("  subject: " + self.subject)
            module_logger.info("  session: " + self.session)

            delete_resource.delete_resource(
                self.username, self.password,
                str_utils.get_server_name(self.server),
                self.project, self.subject, self.session,
                self._output_resource_name)

        # build list of groups
        self._group_list = []
        for group in self.groups:
            self._group_list.append(self._expand(group))

        module_logger.debug("self._group_list: " + str(self._group_list))

        # build list of concat names
        self._concat_name_list = []
        for group in self._group_list:
            self._concat_name_list.append(self._concat(group))

        # create scripts for various stages of processing
        if processing_stage >= one_subject_job_submitter.ProcessingStage.PREPARE_SCRIPTS:
            self.create_get_data_job_script()
            self.create_work_script()
            self.create_clean_data_script()
            self.create_put_data_script()

        # Submit the job to get the data
        if processing_stage >= one_subject_job_submitter.ProcessingStage.GET_DATA:
            get_data_job_no = self.submit_get_data_job()
            module_logger.info("get_data_job_no: " + str(get_data_job_no))
        else:
            module_logger.info("Get data job not submitted")

        # Submit the job to process the data (do the work)
        if processing_stage >= one_subject_job_submitter.ProcessingStage.PROCESS_DATA:
            work_job_no = self.submit_process_data_job(get_data_job_no)
            module_logger.info("work_job_no: " + str(work_job_no))
        else:
            module_logger.info("Process data job not submitted")

        # Submit job to clean the data
        if processing_stage >= one_subject_job_submitter.ProcessingStage.CLEAN_DATA:
            clean_job_no = self.submit_clean_data_job(work_job_no)
            module_logger.info("clean_job_no: " + str(clean_job_no))
        else:
            module_logger.info("Clean data job not submitted")

        # Submit job to put the resulting data in the DB
        if processing_stage >= one_subject_job_submitter.ProcessingStage.PUT_DATA:
            put_job_no = self.submit_put_data_job(clean_job_no)
            module_logger.info("put_job_no: " + str(put_job_no))
        else:
            module_logger.info("Put data job not submitted")
