#!/usr/bin/env python3

# import of built-in modules
import contextlib
import logging
import os
import shutil
import stat
import subprocess
import random
import sys

# import of third-party modules

# import of local modules
import ccf.one_subject_job_submitter as one_subject_job_submitter
import ccf.processing_stage as ccf_processing_stage
import ccf.subject as ccf_subject
import utils.debug_utils as debug_utils
import utils.str_utils as str_utils
import utils.os_utils as os_utils
import utils.user_utils as user_utils
import ccf.archive as ccf_archive

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
# Note: This can be overidden by log file configuration
module_logger.setLevel(logging.WARNING)


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

	@classmethod
	def MY_PIPELINE_NAME(cls):
		return 'FunctionalPreprocessing'

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

		subject_info = ccf_subject.SubjectInfo(self.project, self.subject,
											   self.classifier, self.scan)

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

		xnat_pbs_setup_line = 'source ' + self._get_xnat_pbs_setup_script_path() + ' ' + self._get_db_name()

		script_line	  = processing_script_dest_path
		user_line		= '  --user=' + self.username
		password_line	= '  --password=' + self.password
		server_line	  = '  --server=' + str_utils.get_server_name(self.server)
		project_line	 = '  --project=' + self.project
		subject_line	 = '  --subject=' + self.subject
		session_line	 = '  --session=' + self.session
		scan_line		= '  --scan=' + self.scan
		session_classifier_line = '  --session-classifier=' + self.classifier
		dcmethod_line	= '  --dcmethod=TOPUP'
		topupconfig_line = '  --topupconfig=b02b0.cnf'
		gdcoeffs_line	= '  --gdcoeffs=Prisma_3T_coeff_AS82.grad'
	
		wdir_line  = '  --working-dir=' + self.working_directory_name
		setup_line = '  --setup-script=' + self.setup_file_name
		
		with open(script_name, 'w') as script:
			script.write(resources_line + os.linesep)
			script.write(stdout_line + os.linesep)
			script.write(stderr_line + os.linesep)
			script.write(os.linesep)
			script.write(xnat_pbs_setup_line + os.linesep)
			script.write(os.linesep)
			script.write(script_line +	  ' \\' + os.linesep)
			script.write(user_line +		' \\' + os.linesep)
			script.write(password_line +	' \\' + os.linesep)
			script.write(server_line +	  ' \\' + os.linesep)
			script.write(project_line +	 ' \\' + os.linesep)
			script.write(subject_line +	 ' \\' + os.linesep)
			script.write(session_line +	 ' \\' + os.linesep)
			script.write(scan_line +		' \\' + os.linesep)
			script.write(session_classifier_line + ' \\' + os.linesep)
			script.write(dcmethod_line +	' \\' + os.linesep)
			script.write(topupconfig_line + ' \\' + os.linesep)
			script.write(gdcoeffs_line +	' \\' + os.linesep)
			script.write(wdir_line + ' \\' + os.linesep)
			script.write(setup_line + os.linesep)
			
			os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)
			
	def mark_running_status(self, stage):
		module_logger.debug(debug_utils.get_name())

		if stage > ccf_processing_stage.ProcessingStage.PREPARE_SCRIPTS:
			mark_cmd = self._xnat_pbs_jobs_home
			mark_cmd += os.sep + self.PIPELINE_NAME
			mark_cmd += os.sep + self.PIPELINE_NAME
			mark_cmd += '.XNAT_MARK_RUNNING_STATUS'
			mark_cmd += ' --user=' + self.username
			mark_cmd += ' --password=' + self.password
			mark_cmd += ' --server=' + str_utils.get_server_name(self.put_server)
			mark_cmd += ' --project=' + self.project
			mark_cmd += ' --subject=' + self.subject
			mark_cmd += ' --classifier=' + self.classifier
			mark_cmd += ' --scan=' + self.scan
			mark_cmd += ' --resource=RunningStatus'
			mark_cmd += ' --queued'

			completed_mark_cmd_process = subprocess.run(
				mark_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
			print(completed_mark_cmd_process.stdout)

			return

if __name__ == "__main__":
	import ccf.functional_preprocessing.one_subject_run_status_checker as one_subject_run_status_checker
	xnat_server = os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER')
	username, password = user_utils.get_credentials(xnat_server)
	archive = ccf_archive.CcfArchive()	
	subject = ccf_subject.SubjectInfo(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
	submitter = OneSubjectJobSubmitter(archive, archive.build_home)	
		
	run_status_checker = one_subject_run_status_checker.OneSubjectRunStatusChecker()
	
	if run_status_checker.get_queued_or_running(subject):
		print("-----")
		print("NOT SUBMITTING JOBS FOR")
		print("project: " + subject.project)
		print("subject: " + subject.subject_id)
		print("session classifier: " + subject.classifier)
		print("scan: " + subject.extra)
		print("JOBS ARE ALREADY QUEUED OR RUNNING")
		print ('Process terminated')
		sys.exit()	

	min_shadow_str = os_utils.getenv_required("XNAT_PBS_JOBS_MIN_SHADOW")
	max_shadow_str = os_utils.getenv_required("XNAT_PBS_JOBS_MAX_SHADOW")
	random_shadow = (random.randint(int(min_shadow_str), int(max_shadow_str)))
	
	job_submitter=OneSubjectJobSubmitter(archive, archive.build_home)	
	put_server = 'http://intradb-shadow'
	put_server += str(random_shadow)
	put_server += '.nrg.mir:8080'

	clean_output_first = eval(sys.argv[5])
	processing_stage_str = sys.argv[6]
	processing_stage = submitter.processing_stage_from_string(processing_stage_str)
	walltime_limit_hrs = sys.argv[7]
	vmem_limit_gbs = sys.argv[8]
	output_resource_suffix = sys.argv[9]
	
	print("-----")
	print("\tSubmitting", submitter.PIPELINE_NAME, "jobs for:")
	print("\t			   project:", subject.project)
	print("\t			   subject:", subject.subject_id)
	print("\t				  scan:", subject.extra)
	print("\t	session classifier:", subject.classifier)
	print("\t			put_server:", put_server)
	print("\t	clean_output_first:", clean_output_first)
	print("\t	  processing_stage:", processing_stage)
	print("\t	walltime_limit_hrs:", walltime_limit_hrs)
	print("\t		vmem_limit_gbs:", vmem_limit_gbs)
	print("\toutput_resource_suffix:", output_resource_suffix)	

	
	# configure one subject submitter
			
	# user and server information
	submitter.username = username
	submitter.password = password
	submitter.server = 'https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER')	
	
	# subject and project information
	submitter.project = subject.project
	submitter.subject = subject.subject_id
	submitter.classifier = subject.classifier
	submitter.session = subject.subject_id + '_' + subject.classifier
	submitter.scan = subject.extra

	# job parameters
	submitter.clean_output_resource_first = clean_output_first
	submitter.put_server = put_server
	submitter.walltime_limit_hours = walltime_limit_hrs
	submitter.vmem_limit_gbs = vmem_limit_gbs
	submitter.output_resource_suffix = output_resource_suffix

	# submit jobs
	submitted_job_list = submitter.submit_jobs(processing_stage)

	print("\tsubmitted jobs:", submitted_job_list)
	print("-----")