#!/usr/bin/env python3

# import of built-in modules
import contextlib
import glob
import logging
import os
import shutil
import stat
import subprocess

# import of third-party modules

# import of local modules
import ccf.one_subject_job_submitter as one_subject_job_submitter
import ccf.processing_stage as ccf_processing_stage
import ccf.subject as ccf_subject
import utils.debug_utils as debug_utils
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
# Note: This can be overidden by log file configuration
module_logger.setLevel(logging.WARNING)


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    _SEVEN_MM_TEMPLATE_PROJECTS = ('HCP_500', 'HCP_900', 'HCP_1200')
    _SUPPRESS_FREESURFER_ASSESSOR_JOB = True
    
    @classmethod
    def MY_PIPELINE_NAME(cls):
        return 'StructuralPreprocessing'

    def __init__(self, archive, build_home):
        super().__init__(archive, build_home)
    
    @property
    def PIPELINE_NAME(self):
        return OneSubjectJobSubmitter.MY_PIPELINE_NAME()

    @property
    def WORK_NODE_COUNT(self):
        return 1

    @property
    def WORK_PPN(self):
        return 1

    # @property
    # def FIELDMAP_TYPE_SPEC(self):
    #     return "SE"  # Spin Echo Field Maps

    # @property
    # def PHASE_ENCODING_DIR_SPEC(self):
    #   return "PA" # Posterior-to-Anterior and Anterior to Posterior

    @property
    def use_prescan_normalized(self):
        return self._use_prescan_normalized

    @use_prescan_normalized.setter
    def use_prescan_normalized(self, value):
        self._use_prescan_normalized = value
        module_logger.debug(debug_utils.get_name() + ": set to " + str(self._use_prescan_normalized))
    
    @property
    def brain_size(self):
        return self._brain_size

    @brain_size.setter
    def brain_size(self, value):
        self._brain_size = value
        module_logger.debug(debug_utils.get_name() + ": set to " +
                            str(self._brain_size))

    def _template_size_str(self):
        if self.project == None:
            raise ValueError("project attribute must be set before template size can be determined")

        if self.project in OneSubjectJobSubmitter._SEVEN_MM_TEMPLATE_PROJECTS:
            size_str = "0.7mm"
        else:
            size_str = "0.8mm"

        return size_str
    
    @property
    def T1W_TEMPLATE_NAME(self):
        return "MNI152_T1_" + self._template_size_str() + ".nii.gz"

    @property
    def T1W_TEMPLATE_BRAIN_NAME(self):
        return "MNI152_T1_" + self._template_size_str() + "_brain.nii.gz"

    @property
    def T1W_TEMPLATE_2MM_NAME(self):
        return "MNI152_T1_2mm.nii.gz"

    @property
    def T2W_TEMPLATE_NAME(self):
        return "MNI152_T2_" + self._template_size_str() + ".nii.gz"

    @property
    def T2W_TEMPLATE_BRAIN_NAME(self):
        return "MNI152_T2_" + self._template_size_str() + "_brain.nii.gz"

    @property
    def T2W_TEMPLATE_2MM_NAME(self):
        return "MNI152_T2_2mm.nii.gz"

    @property
    def TEMPLATE_MASK_NAME(self):
        return "MNI152_T1_" + self._template_size_str() + "_brain_mask.nii.gz"

    @property
    def TEMPLATE_2MM_MASK_NAME(self):
        return "MNI152_T1_2mm_brain_mask_dil.nii.gz"

    @property
    def FNIRT_CONFIG_FILE_NAME(self):
        return "T1_2_MNI152_2mm.cnf"

    @property
    def CONNECTOME_GDCOEFFS_FILE_NAME(self):
        return "coeff_SC72C_Skyra.grad"
    
    @property
    def PRISMA_3T_GDCOEFFS_FILE_NAME(self):
        return "Prisma_3T_coeff_AS82.grad"

    @property
    def TOPUP_CONFIG_FILE_NAME(self):
        return "b02b0.cnf"

    @property
    def freesurfer_assessor_script_name(self):
        module_logger.debug(debug_utils.get_name())
        return self.scripts_start_name + '.XNAT_CREATE_FREESURFER_ASSESSOR_job.sh'

    def create_get_data_job_script(self):
        """Create the script to be submitted to perform the get data job"""
        module_logger.debug(debug_utils.get_name())

        script_name = self.get_data_job_script_name

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')

        self._write_bash_header(script)
        script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
        script.write('#PBS -q HCPput' + os.linesep)
        script.write('#PBS -o ' + self.working_directory_name + os.linesep)
        script.write('#PBS -e ' + self.working_directory_name + os.linesep)
        script.write(os.linesep)
        script.write(self.get_data_program_path + ' \\' + os.linesep)
        script.write('  --project=' + self.project + ' \\' + os.linesep)
        script.write('  --subject=' + self.subject + ' \\' + os.linesep)
        script.write('  --classifier=' + self.classifier + ' \\' + os.linesep)

        if self.scan:
            script.write('  --scan=' + self.scan + ' \\' + os.linesep)
            
        script.write('  --working-dir=' + self.working_directory_name + ' \\' + os.linesep)

        if self.use_prescan_normalized:
            script.write('  --use-prescan-normalized' + ' \\' + os.linesep)
        
        script.write('  --delay-seconds=120' + os.linesep)
        
        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)


    def _get_first_t1w_resource_fullpath(self, subject_info):
        t1w_resource_paths = self.archive.available_t1w_unproc_dir_full_paths(subject_info)
        if len(t1w_resource_paths) > 0:
            return t1w_resource_paths[0]
        else:
            raise RuntimeError("Session has no T1w resources")
        
    def _has_spin_echo_field_maps(self, subject_info):
        first_t1w_resource_path = self._get_first_t1w_resource_fullpath(subject_info)
        path_expr = first_t1w_resource_path + os.sep + '*SpinEchoFieldMap*' + '.nii.gz'
        spin_echo_file_list = glob.glob(path_expr)
        return len(spin_echo_file_list) > 0

    def _get_fmap_phase_file_path(self, subject_info):
        first_t1w_resource_path = self._get_first_t1w_resource_fullpath(subject_info)
        path_expr = first_t1w_resource_path + os.sep + '*FieldMap_Phase*' + '.nii.gz'
        fmap_phase_list = glob.glob(path_expr)
        
        if len(fmap_phase_list) > 0:
            fmap_phase_file = fmap_phase_list[0]
        else:
            raise RuntimeError("First T1w has no Phase FieldMap: " + path_expr)

        return fmap_phase_file

    def _get_fmap_phase_file_name(self, subject_info):
        full_path = self._get_fmap_phase_file_path(subject_info)
        basename = os.path.basename(full_path)
        return basename
    
    def _get_fmap_mag_file_path(self, subject_info):
        first_t1w_resource_path = self._get_first_t1w_resource_fullpath(subject_info)
        path_expr = first_t1w_resource_path + os.sep + '*FieldMap_Magnitude*' + '.nii.gz'
        fmap_mag_list = glob.glob(path_expr)

        if len(fmap_mag_list) > 0:
            fmap_mag_file = fmap_mag_list[0]
        else:
            raise RuntimeError("First T1w has no Magnitude FieldMap: " + path_expr)

        return fmap_mag_file
        
    def _get_fmap_mag_file_name(self, subject_info):
        full_path = self._get_fmap_mag_file_path(subject_info)
        basename = os.path.basename(full_path)
        return basename

    def _get_positive_spin_echo_path(self, subject_info):
        first_t1w_resource_path = self._get_first_t1w_resource_fullpath(subject_info)
        path_expr = first_t1w_resource_path + os.sep + '*SpinEchoFieldMap*' + self.PAAP_POSITIVE_DIR + '.nii.gz'
        positive_spin_echo_file_list = glob.glob(path_expr)

        if len(positive_spin_echo_file_list) > 0:
            positive_spin_echo_file = positive_spin_echo_file_list[0]
        else:
            raise RuntimeError("First T1w resource/scan has no positive spin echo field map")

        return positive_spin_echo_file

    def _get_positive_spin_echo_file_name(self, subject_info):
        full_path = self._get_positive_spin_echo_path(subject_info)
        basename = os.path.basename(full_path)
        return basename

    def _get_negative_spin_echo_path(self, subject_info):
        first_t1w_resource_path = self._get_first_t1w_resource_fullpath(subject_info)
        path_expr = first_t1w_resource_path + os.sep + '*SpinEchoFieldMap*' + self.PAAP_NEGATIVE_DIR + '.nii.gz'
        negative_spin_echo_file_list = glob.glob(path_expr)

        if len(negative_spin_echo_file_list) > 0:
            negative_spin_echo_file = negative_spin_echo_file_list[0]
        else:
            raise RuntimeError("First T1w resource/scan has no negative spin echo field map")

        return negative_spin_echo_file

    def _get_negative_spin_echo_file_name(self, subject_info):
        full_path = self._get_negative_spin_echo_path(subject_info)
        basename = os.path.basename(full_path)
        return basename

    def _get_first_t1w_name(self, subject_info):
        t1w_unproc_names = self.archive.available_t1w_unproc_names(subject_info)
        if len(t1w_unproc_names) > 0:
            first_t1w_name = t1w_unproc_names[0]
        else:
            raise RuntimeError("Session has no available T1w scans")

        return first_t1w_name

    def _get_first_t1w_norm_name(self, subject_info):
        non_norm_name = self._get_first_t1w_name(subject_info)
        vNav_loc = non_norm_name.find('vNav')
        norm_name = non_norm_name[:vNav_loc] + 'vNav' + '_Norm' + non_norm_name[vNav_loc+4:]
        return norm_name
    
    def _get_first_t1w_directory_name(self, subject_info):
        first_t1w_name = self._get_first_t1w_name(subject_info)
        return first_t1w_name
    
    def _get_first_t1w_resource_name(self, subject_info):
        return self._get_first_t1w_name(subject_info) + self.archive.NAME_DELIMITER + self.archive.UNPROC_SUFFIX
    
    def _get_first_t1w_file_name(self, subject_info):
        if self.use_prescan_normalized:
            return self.session + self.archive.NAME_DELIMITER + self._get_first_t1w_norm_name(subject_info) + '.nii.gz'
        else:
            return self.session + self.archive.NAME_DELIMITER + self._get_first_t1w_name(subject_info) + '.nii.gz'

    def _get_first_t2w_name(self, subject_info):
        t2w_unproc_names = self.archive.available_t2w_unproc_names(subject_info)
        if len(t2w_unproc_names) > 0:
            first_t2w_name = t2w_unproc_names[0]
        else:
            raise RuntimeError("Session has no available T2w scans")
        
        return first_t2w_name

    def _get_first_t2w_norm_name(self, subject_info):
        non_norm_name = self._get_first_t2w_name(subject_info)
        vNav_loc = non_norm_name.find('vNav')
        norm_name = non_norm_name[:vNav_loc] + 'vNav' + '_Norm' + non_norm_name[vNav_loc+4:]
        return norm_name
    
    def _get_first_t2w_directory_name(self, subject_info):
        first_t2w_name = self._get_first_t2w_name(subject_info)
        return first_t2w_name
    
    def _get_first_t2w_resource_name(self, subject_info):
        return self._get_first_t2w_name(subject_info) + self.archive.NAME_DELIMITER + self.archive.UNPROC_SUFFIX

    def _get_first_t2w_file_name(self, subject_info):
        if self.use_prescan_normalized:
            return self.session + self.archive.NAME_DELIMITER + self._get_first_t2w_norm_name(subject_info) + '.nii.gz'
        else:
            return self.session + self.archive.NAME_DELIMITER + self._get_first_t2w_name(subject_info) + '.nii.gz'

    def create_process_data_job_script(self):
        module_logger.debug(debug_utils.get_name())

        # copy the .XNAT_PROCESS script to the working directory
        processing_script_source_path = self.xnat_pbs_jobs_home
        processing_script_source_path += os.sep + self.PIPELINE_NAME
        processing_script_source_path += os.sep + self.PIPELINE_NAME
        processing_script_source_path += '.XNAT_PROCESS'

        processing_script_dest_path = self.working_directory_name
        processing_script_dest_path += os.sep + self.PIPELINE_NAME
        processing_script_dest_path += '.XNAT_PROCESS'

        shutil.copy(processing_script_source_path, processing_script_dest_path)
        os.chmod(processing_script_dest_path, stat.S_IRWXU | stat.S_IRWXG)

        # write the process data job script (that calls the .XNAT_PROCESS script)

        subject_info = ccf_subject.SubjectInfo(self.project, self.subject, self.classifier)

        script_name = self.process_data_job_script_name

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        walltime_limit_str = str(self.walltime_limit_hours) + ':00:00'
        vmem_limit_str = str(self.vmem_limit_gbs) + 'gb'

        resources_line = '#PBS -l nodes=' + str(self.WORK_NODE_COUNT)
        resources_line += ':ppn=' + str(self.WORK_PPN)
        resources_line += ',walltime=' + walltime_limit_str
        resources_line += ',mem=' + vmem_limit_str

        stdout_line = '#PBS -o ' + self.working_directory_name
        stderr_line = '#PBS -e ' + self.working_directory_name

        script_line    = processing_script_dest_path
        user_line      = '  --user=' + self.username
        password_line  = '  --password=' + self.password
        server_line    = '  --server=' + str_utils.get_server_name(self.server)
        project_line   = '  --project=' + self.project
        subject_line   = '  --subject=' + self.subject
        session_line   = '  --session=' + self.session
        session_classifier_line = '  --session-classifier=' + self.classifier

        if self._has_spin_echo_field_maps(subject_info):
            fieldmap_type_line = '  --fieldmap-type=' + 'SpinEcho'
        else:
            fieldmap_type_line = '  --fieldmap-type=' + 'SiemensGradientEcho' 
            
        first_t1w_directory_name_line = '  --first-t1w-directory-name=' + self._get_first_t1w_directory_name(subject_info)
        first_t1w_resource_name_line  = '  --first-t1w-resource-name=' + self._get_first_t1w_resource_name(subject_info)
        first_t1w_file_name_line      = '  --first-t1w-file-name=' + self._get_first_t1w_file_name(subject_info)
        
        first_t2w_directory_name_line = '  --first-t2w-directory-name=' + self._get_first_t2w_directory_name(subject_info)
        first_t2w_resource_name_line  = '  --first-t2w-resource-name=' + self._get_first_t2w_resource_name(subject_info)
        first_t2w_file_name_line      = '  --first-t2w-file-name=' + self._get_first_t2w_file_name(subject_info)
        
        brain_size_line               = '  --brainsize=' + str(self.brain_size)

        t1template_line      = '  --t1template=' + self.T1W_TEMPLATE_NAME
        t1templatebrain_line = '  --t1templatebrain=' + self.T1W_TEMPLATE_BRAIN_NAME
        t1template2mm_line   = '  --t1template2mm=' + self.T1W_TEMPLATE_2MM_NAME
        t2template_line      = '  --t2template=' + self.T2W_TEMPLATE_NAME
        t2templatebrain_line = '  --t2templatebrain=' + self.T2W_TEMPLATE_BRAIN_NAME
        t2template2mm_line   = '  --t2template2mm=' + self.T2W_TEMPLATE_2MM_NAME
        templatemask_line    = '  --templatemask=' + self.TEMPLATE_MASK_NAME
        template2mmmask_line = '  --template2mmmask=' + self.TEMPLATE_2MM_MASK_NAME

        fnirtconfig_line     = '  --fnirtconfig=' + self.FNIRT_CONFIG_FILE_NAME


        if subject_info.project == 'HCP_1200':
            gdcoeffs_line = '  --gdcoeffs=' + self.CONNECTOME_GDCOEFFS_FILE_NAME
        else:
            gdcoeffs_line = '  --gdcoeffs=' + self.PRISMA_3T_GDCOEFFS_FILE_NAME


        topupconfig_line     = '  --topupconfig=' + self.TOPUP_CONFIG_FILE_NAME

        if self._has_spin_echo_field_maps(subject_info):
            se_phase_pos_line = '  --se-phase-pos=' + self._get_positive_spin_echo_file_name(subject_info)
            se_phase_neg_line = '  --se-phase-neg=' + self._get_negative_spin_echo_file_name(subject_info)
            # mag_line = None
            # phase_line = None
        else:
            se_phase_pos_line = None
            se_phase_neg_line = None
            # mag_line   = '  --fmapmag=' + self._get_fmap_mag_file_name(subject_info)
            # phase_line = '  --fmapphase=' + self._get_fmap_phase_file_name(subject_info)
            
        wdir_line  = '  --working-dir=' + self.working_directory_name
        setup_line = '  --setup-script=' + self.setup_file_name

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
            script.write(session_classifier_line + ' \\' + os.linesep)
            script.write(fieldmap_type_line + ' \\' + os.linesep)
            script.write(first_t1w_directory_name_line + ' \\' + os.linesep)
            script.write(first_t1w_resource_name_line + ' \\' + os.linesep)
            script.write(first_t1w_file_name_line + ' \\' + os.linesep)
            script.write(first_t2w_directory_name_line + ' \\' + os.linesep)
            script.write(first_t2w_resource_name_line + ' \\' + os.linesep)
            script.write(first_t2w_file_name_line + ' \\' + os.linesep)
            script.write(brain_size_line + ' \\' + os.linesep)
            script.write(t1template_line + ' \\' + os.linesep)
            script.write(t1templatebrain_line + ' \\' + os.linesep)
            script.write(t1template2mm_line + ' \\' + os.linesep)
            script.write(t2template_line + ' \\' + os.linesep)
            script.write(t2templatebrain_line + ' \\' + os.linesep)
            script.write(t2template2mm_line + ' \\' + os.linesep)
            script.write(templatemask_line + ' \\' + os.linesep)
            script.write(template2mmmask_line + ' \\' + os.linesep)
            script.write(fnirtconfig_line + ' \\' + os.linesep)
            script.write(gdcoeffs_line + ' \\' + os.linesep)
            script.write(topupconfig_line + ' \\' + os.linesep)

            if (se_phase_pos_line): script.write(se_phase_pos_line + ' \\' + os.linesep)
            if (se_phase_neg_line): script.write(se_phase_neg_line + ' \\' + os.linesep)
            # if (mag_line): script.write(mag_line + ' \\' + os.linesep)
            # if (phase_line): script.write(phase_line + ' \\' + os.linesep)
            
            script.write(wdir_line + ' \\' + os.linesep)
            script.write(setup_line + os.linesep)

            os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def create_freesurfer_assessor_script(self):
        module_logger.debug(debug_utils.get_name())

        # copy the .XNAT_CREATE_FREESURFER_ASSESSOR script to the working directory
        freesurfer_assessor_source_path = self.xnat_pbs_jobs_home
        freesurfer_assessor_source_path += os.sep + self.PIPELINE_NAME
        freesurfer_assessor_source_path += os.sep + self.PIPELINE_NAME
        freesurfer_assessor_source_path += '.XNAT_CREATE_FREESURFER_ASSESSOR'

        freesurfer_assessor_dest_path = self.working_directory_name
        freesurfer_assessor_dest_path += os.sep + self.PIPELINE_NAME
        freesurfer_assessor_dest_path += '.XNAT_CREATE_FREESURFER_ASSESSOR'

        shutil.copy(freesurfer_assessor_source_path, freesurfer_assessor_dest_path)
        os.chmod(freesurfer_assessor_dest_path, stat.S_IRWXU | stat.S_IRWXG)

        # write the freesurfer assessor submission script (that calls the .XNAT_CREATE_FREESURFER_ASSESSOR script)

        script_name = self.freesurfer_assessor_script_name

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')

        self._write_bash_header(script)
        script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
        script.write('#PBS -o ' + self.working_directory_name + os.linesep)
        script.write('#PBS -e ' + self.working_directory_name + os.linesep)
        script.write(os.linesep)

        script_line    = freesurfer_assessor_dest_path
        user_line      = '  --user='        + self.username
        password_line  = '  --password='    + self.password
        server_line    = '  --server='      + str_utils.get_server_name(self.server)
        project_line   = '  --project='     + self.project
        subject_line   = '  --subject='     + self.subject
        session_line   = '  --session='     + self.session
        session_classifier_line = '  --session-classifier=' + self.classifier
        wdir_line      = '  --working-dir=' + self.working_directory_name

        script.write(script_line   + ' \\' + os.linesep)
        script.write(user_line     + ' \\' + os.linesep)
        script.write(password_line + ' \\' + os.linesep)
        script.write(server_line + ' \\' + os.linesep)
        script.write(project_line + ' \\' + os.linesep)
        script.write(subject_line + ' \\' + os.linesep)
        script.write(session_line + ' \\' + os.linesep)
        script.write(session_classifier_line + ' \\' + os.linesep)
        script.write(wdir_line + os.linesep)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def create_scripts(self, stage):
        module_logger.debug(debug_utils.get_name())
        super().create_scripts(stage)

        if stage >= ccf_processing_stage.ProcessingStage.PREPARE_SCRIPTS:
            self.create_freesurfer_assessor_script()

    def submit_process_data_jobs(self, stage, prior_job=None):
        module_logger.debug(debug_utils.get_name())

        # go ahead and submit the standard process data job and then
        # submit an additional freesurfer assessor job

        standard_process_data_jobno, all_process_data_jobs = super().submit_process_data_jobs(stage, prior_job)

        if OneSubjectJobSubmitter._SUPPRESS_FREESURFER_ASSESSOR_JOB or stage >= ccf_processing_stage.ProcessingStage.PROCESS_DATA:
            if standard_process_data_jobno:
                fs_submit_cmd = 'qsub -W depend=afterok:' + standard_process_data_jobno + ' ' + self.freesurfer_assessor_script_name
            else:
                fs_submit_cmd = 'qsub ' + self.freesurfer_assessor_script_name

            completed_submit_process = subprocess.run(
                fs_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
            fs_job_no = str_utils.remove_ending_new_lines(completed_submit_process.stdout)
            all_process_data_jobs.append(fs_job_no)
            return fs_job_no, all_process_data_jobs

        else:
            module_logger.info("freesurfer assessor job not submitted")
            return standard_process_data_jobno, all_process_data_jobs

    def mark_running_status(self, stage):
        module_logger.debug(debug_utils.get_name())

        if stage > ccf_processing_stage.ProcessingStage.PREPARE_SCRIPTS:
            mark_cmd = self._xnat_pbs_jobs_home
            mark_cmd += os.sep + self.PIPELINE_NAME 
            mark_cmd += os.sep + self.PIPELINE_NAME
            mark_cmd += '.XNAT_MARK_RUNNING_STATUS' 
            mark_cmd += ' --project=' + self.project
            mark_cmd += ' --subject=' + self.subject
            mark_cmd += ' --classifier=' + self.classifier
            mark_cmd += ' --queued'

            completed_mark_cmd_process = subprocess.run(
                mark_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
            print(completed_mark_cmd_process.stdout)
            
            return
