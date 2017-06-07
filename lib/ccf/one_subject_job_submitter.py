#!/usr/bin/env python3

"""
ccf/one_subject_job_submitter.py: Abstract base class for an object
that submits jobs for a pipeline for one subject.
"""

# import of built-in modules
import abc
import contextlib
import enum
import logging
import os
import shutil
import stat
import subprocess
import time

# import of third-party modules

# import of local modules
import utils.debug_utils as debug_utils
import utils.delete_resource as delete_resource
import utils.file_utils as file_utils
import utils.ordered_enum as ordered_enum
import utils.os_utils as os_utils
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility (CCF)"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
module_logger.setLevel(logging.WARNING)  # Note: This can be overidden by log file configuration


@enum.unique
class ProcessingStage(ordered_enum.OrderedEnum):
	PREPARE_SCRIPTS = 0
	GET_DATA = 1
	PROCESS_DATA = 2
	CLEAN_DATA = 3
	PUT_DATA = 4


class OneSubjectJobSubmitter(abc.ABC):
	"""
	This class is an abstract base class for classes that are used to submit jobs
	for one pipeline for one subject.
	"""

	def __init__(self, archive, build_home):
		"""
		Initialize a OneSubjectJobSubmitter
		"""
		self._archive = archive
		self._build_home = build_home

		self._xnat_pbs_jobs_home = os_utils.getenv_required('XNAT_PBS_JOBS')
		self._log_dir = os_utils.getenv_required('XNAT_PBS_JOBS_LOG_DIR')

		self._scan = None
		self._working_directory_name = None

	def processing_stage_from_string(self, str_value):
		return ProcessingStage.from_string(str_value)

	@property
	@abc.abstractmethod
	def PIPELINE_NAME(self):
		raise NotImplementedError()

	@property
	def archive(self):
		"""
		Returns the archive with which this submitter is to work.
		"""
		return self._archive

	@property
	def build_home(self):
		"""
		Returns the temporary (e.g. build space) root directory.
		"""
		return self._build_home

	@property
	def xnat_pbs_jobs_home(self):
		"""
		Returns the home directory for the XNAT PBS job scripts.
		"""
		return self._xnat_pbs_jobs_home

	@property
	def log_dir(self):
		"""
		Returns the directory in which to place PUT logs.
		"""
		return self._log_dir

	@property
	def username(self):
		return self._username

	@username.setter
	def username(self, value):
		self._username = value
		module_logger.debug(debug_utils.get_name() + ": set to: " + str(value))

	@property
	def password(self):
		return self._password

	@password.setter
	def password(self, value):
		self._password = value

	@property
	def server(self):
		return self._server

	@server.setter
	def server(self, value):
		self._server = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(self._server))

	@property
	def project(self):
		return self._project

	@project.setter
	def project(self, value):
		self._project = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(self._project))

	@property
	def subject(self):
		return self._subject

	@subject.setter
	def subject(self, value):
		self._subject = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(self._subject))

	@property
	def session(self):
		return self._session

	@session.setter
	def session(self, value):
		self._session = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(self._session))

	@property
	def scan(self):
		return self._scan

	@scan.setter
	def scan(self, value):
		self._scan = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(self._scan))

	@property
	def clean_output_resource_first(self):
		return self._clean_output_resource_first

	@clean_output_resource_first.setter
	def clean_output_resource_first(self, value):
		self._clean_output_resource_first = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(self._clean_output_resource_first))

	@property
	def put_server(self):
		return self._put_server

	@put_server.setter
	def put_server(self, value):
		self._put_server = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(self._put_server))

	@property
	def walltime_limit_hours(self):
		return self._walltime_limit_hours

	@walltime_limit_hours.setter
	def walltime_limit_hours(self, value):
		self._walltime_limit_hours = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(value))

	@property
	def vmem_limit_gbs(self):
		return self._vmem_limit_gbs

	@vmem_limit_gbs.setter
	def vmem_limit_gbs(self, value):
		self._vmem_limit_gbs = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(value))

	@property
	def output_resource_suffix(self):
		return self._output_resource_suffix

	@output_resource_suffix.setter
	def output_resource_suffix(self, value):
		self._output_resource_suffix = value
		module_logger.debug(debug_utils.get_name() + ": set to " + str(value))

	@property
	def working_directory_name(self):
		# Since the working directory name contains a timestamp, it is
		# important to only build the working directory name one time.
		# The first time it is requested, self._working_directory_name
		# will have a value of None. In that case, build the name, store
		# it and return it. For any subsequent requests, simply return
		# the previously built name.
		if self._working_directory_name is None:
			current_seconds_since_epoch = int(time.time())
			wdir = self.build_home
			wdir += os.sep + self.project
			wdir += os.sep + self.PIPELINE_NAME
			wdir += '.' + self.subject
			if self.scan:
				wdir += '.' + self.scan
			wdir += '.' + str(current_seconds_since_epoch)
			self._working_directory_name = wdir

		return self._working_directory_name

	@property
	def scripts_start_name(self):
		start_name = self.working_directory_name
		start_name += os.sep + self.subject
		start_name += '.' + self.PIPELINE_NAME
		if self.scan:
			start_name += '_' + self.scan
		start_name += '.' + self.project
		start_name += '.' + self.session
		return start_name

	@property
	def get_data_script_name(self):
		module_logger.debug(debug_utils.get_name())
		return self.scripts_start_name + '.XNAT_GET_DATA_job.sh'

	def _write_bash_header(self, script):
		bash_line = '#PBS -S /bin/bash'
		file_utils.wl(script, bash_line)
		file_utils.wl(script, '')

	def create_get_data_script(self):
		module_logger.debug(debug_utils.get_name())

		script_name = self.get_data_script_name

		with contextlib.suppress(FileNotFoundError):
			os.remove(script_name)

		script = open(script_name, 'w')

		self._write_bash_header(script)
		script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
		script.write('#PBS -q HCPput' + os.linesep)
		script.write('#PBS -o ' + self.working_directory_name + os.linesep)
		script.write('#PBS -e ' + self.working_directory_name + os.linesep)
		script.write(os.linesep)
		script.write(self.xnat_pbs_jobs_home + os.sep + self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT_GET.sh \\' + os.linesep)
		script.write('  --project=' + self.project + ' \\' + os.linesep)
		script.write('  --subject=' + self.subject + ' \\' + os.linesep)
		script.write('  --working-dir=' + self.working_directory_name + os.linesep)

		script.close()
		os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

	@property
	def put_data_script_name(self):
		module_logger.debug(debug_utils.get_name())
		return self.scripts_start_name + '.XNAT_PUT_DATA_job.sh'

	def create_put_data_script(self):
		module_logger.debug(debug_utils.get_name())

		script_name = self.put_data_script_name

		with contextlib.suppress(FileNotFoundError):
			os.remove(script_name)

		script = open(script_name, 'w')

		script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=12gb' + os.linesep)
		script.write('#PBS -q HCPput' + os.linesep)
		script.write('#PBS -o ' + self.log_dir + os.linesep)
		script.write('#PBS -e ' + self.log_dir + os.linesep)
		script.write(os.linesep)

		script.write(self.xnat_pbs_jobs_home + os.sep + 'WorkingDirPut' + os.sep + 'XNAT_working_dir_put.sh \\' + os.linesep)
		script.write('  --leave-subject-id-level \\' + os.linesep)
		script.write('  --user="' + self.username + '" \\' + os.linesep)
		script.write('  --password="' + self.password + '" \\' + os.linesep)
		script.write('  --server="' + str_utils.get_server_name(self.put_server) + '" \\' + os.linesep)
		script.write('  --project="' + self.project + '" \\' + os.linesep)
		script.write('  --subject="' + self.subject + '" \\' + os.linesep)
		script.write('  --session="' + self.session + '" \\' + os.linesep)
		script.write('  --working-dir="' + self.working_directory_name + '" \\' + os.linesep)

		if self.scan:
			script.write('  --resource-suffix="' + self.scan + '_' + self.output_resource_suffix + '" \\' + os.linesep)
		else:
			script.write('  --resource-suffix="' + self.output_resource_suffix + '" \\' + os.linesep)

		script.write('  --reason="' + self.PIPELINE_NAME + '"' + os.linesep)

		script.close()
		os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

	@property
	def clean_data_script_name(self):
		module_logger.debug(debug_utils.get_name())
		return self.scripts_start_name + '.CLEAN_DATA_job.sh'

	@property
	def starttime_file_name(self):
		module_logger.debug(debug_utils.get_name())
		starttime_file_name = self.working_directory_name
		starttime_file_name += os.path.sep
		starttime_file_name += self.PIPELINE_NAME
		starttime_file_name += '.starttime'
		return starttime_file_name

	def create_clean_data_script(self):
		module_logger.debug(debug_utils.get_name())

		script_name = self.clean_data_script_name

		with contextlib.suppress(FileNotFoundError):
			os.remove(script_name)

		script = open(script_name, 'w')

		self._write_bash_header(script)
		script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
		script.write('#PBS -o ' + self.working_directory_name + os.linesep)
		script.write('#PBS -e ' + self.working_directory_name + os.linesep)
		script.write(os.linesep)
		script.write('echo "Newly created or modified files:"' + os.linesep)
		script.write('find ' + self.working_directory_name + os.path.sep + self.subject)
		script.write(' -type f -newer ' + self.starttime_file_name + os.linesep)
		script.write(os.linesep)
		script.write('echo "Removing NOT newly created or modified files."' + os.linesep)
		script.write('find ' + self.working_directory_name + os.path.sep + self.subject)
		script.write(' -not -newer ' + self.starttime_file_name + ' -delete')
		script.write(os.linesep)
		script.write('echo "Removing any XNAT catalog files still around."' + os.linesep)
		script.write('find ' + self.working_directory_name + ' -name "*_catalog.xml" -delete')
		script.write(os.linesep)
		script.write('echo "Remaining files:"' + os.linesep)
		script.write('find ' + self.working_directory_name + os.path.sep + self.subject + os.linesep)

		script.close()
		os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

	@property
	def work_script_name(self):
		module_logger.debug(debug_utils.get_name())
		return self.scripts_start_name + '.PROCESS_DATA_job.sh'

	@property
	def setup_file_name(self):
		module_logger.debug(debug_utils.get_name())
		return self.scripts_start_name + '.SETUP.sh'

	def create_setup_file(self):
		module_logger.debug(debug_utils.get_name())

		setup_source_file_name = self.PIPELINE_NAME + '.SetUp.sh'
		
		xnat_pbs_jobs_control = os.getenv('XNAT_PBS_JOBS_CONTROL')
		if xnat_pbs_jobs_control:
			setup_source_file_name = xnat_pbs_jobs_control + os.sep + setup_source_file_name

		shutil.copyfile(setup_source_file_name, self.setup_file_name)
		os.chmod(self.setup_file_name, stat.S_IRWXU | stat.S_IRWXG)
		
	def submit_get_data_job(self, prior_job=None):
		module_logger.debug(debug_utils.get_name())
		if prior_job:
			get_data_submit_cmd = 'qsub -W depend=afterok:' + prior_job + ' ' + self.get_data_script_name
		else:
			get_data_submit_cmd = 'qsub ' + self.get_data_script_name

		completed_get_data_submit_process = subprocess.run(
			get_data_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
		get_data_job_no = str_utils.remove_ending_new_lines(completed_get_data_submit_process.stdout)
		module_logger.debug(debug_utils.get_name() + ": get_data_job_no = " + str(get_data_job_no))
		return get_data_job_no

	def submit_process_data_job(self, prior_job=None):
		module_logger.debug(debug_utils.get_name())
		if prior_job:
			work_submit_cmd = 'qsub -W depend=afterok:' + prior_job + ' ' + self.work_script_name
		else:
			work_submit_cmd = 'qsub ' + self.work_script_name

		completed_work_submit_process = subprocess.run(
			work_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
		work_job_no = str_utils.remove_ending_new_lines(completed_work_submit_process.stdout)
		module_logger.debug(debug_utils.get_name() + ": work_job_no = " + str(work_job_no))
		return work_job_no

	def submit_clean_data_job(self, prior_job=None):
		module_logger.debug(debug_utils.get_name())
		if prior_job:
			clean_submit_cmd = 'qsub -W depend=afterok:' + prior_job + ' ' + self.clean_data_script_name
		else:
			clean_submit_cmd = 'qsub ' + self.clean_data_script_name

		completed_clean_submit_process = subprocess.run(
			clean_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
		clean_job_no = str_utils.remove_ending_new_lines(completed_clean_submit_process.stdout)
		module_logger.debug(debug_utils.get_name() + ": clean_job_no = " + str(clean_job_no))
		return clean_job_no

	def submit_put_data_job(self, prior_job=None):
		module_logger.debug(debug_utils.get_name())
		if prior_job:
			put_submit_cmd = 'qsub -W depend=afterok:' + prior_job + ' ' + self.put_data_script_name
		else:
			put_submit_cmd = 'qsub ' + self.put_data_script_name

		completed_put_submit_process = subprocess.run(
			put_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
		put_job_no = str_utils.remove_ending_new_lines(completed_put_submit_process.stdout)
		module_logger.debug(debug_utils.get_name() + ": put_job_no = " + str(put_job_no))
		return put_job_no

	@abc.abstractmethod
	def create_work_script(self):
		module_logger.debug(debug_utils.get_name())
		raise NotImplementedError()

	@abc.abstractmethod
	def output_resource_name(self):
		module_logger.debug(debug_utils.get_name())
		raise NotImplementedError()
	
	def submit_jobs(self, processing_stage=ProcessingStage.PUT_DATA):
		module_logger.debug(debug_utils.get_name() + ": processing_stage: " + str(processing_stage))

		module_logger.info("-----")

		module_logger.info("Submitting " + self.PIPELINE_NAME + " jobs for")
		module_logger.info("  Project: " + self.project)
		module_logger.info("  Subject: " + self.subject)
		module_logger.info("  Session: " + self.session)
		module_logger.info("	Stage: " + str(processing_stage))

		# make sure working directories do not have the same name based on
		# the same start time by sleeping a few seconds
		time.sleep(5)

		# build the working directory name
		os.makedirs(name=self.working_directory_name)
		
		# determine output resource name
		module_logger.info("Output Resource Name: " + self.output_resource_name())
		
		# clean output resource if requested
		if self.clean_output_resource_first:
			module_logger.info("Deleting resource: " + self.output_resource_name() + " for:")
			module_logger.info("  project: " + self.project)
			module_logger.info("  subject: " + self.subject)
			module_logger.info("  session: " + self.session)
		
			delete_resource.delete_resource(
				self.username, self.password,
				str_utils.get_server_name(self.server),
				self.project, self.subject, self.session,
				self.output_resource_name())
	
		# create scripts for various stages of processing
		if processing_stage >= ProcessingStage.PREPARE_SCRIPTS:
			self.create_get_data_script()
			self.create_setup_file()
			self.create_work_script()
			self.create_clean_data_script()
			self.create_put_data_script()
			
		# Submit the job to get the data
		if processing_stage >= ProcessingStage.GET_DATA:
			get_data_job_no = self.submit_get_data_job()
			module_logger.info("get_data_job_no: " + str(get_data_job_no))
		else:
			module_logger.info("Get data job not submitted")

		# Submit the job to process the data (do the work)
		if processing_stage >= ProcessingStage.PROCESS_DATA:
			work_job_no = self.submit_process_data_job(get_data_job_no)
			module_logger.info("work_job_no: " + str(work_job_no))
		else:
			module_logger.info("Process data job not submitted")

		# Submit job to clean the data
		if processing_stage >= ProcessingStage.CLEAN_DATA:
			clean_job_no = self.submit_clean_data_job(work_job_no)
			module_logger.info("clean_job_no: " + str(clean_job_no))
		else:
			module_logger.info("Clean data job not submitted")

		# Submit job to put the resulting data in the DB
		if processing_stage >= ProcessingStage.PUT_DATA:
			put_job_no = self.submit_put_data_job(clean_job_no)
			module_logger.info("put_job_no: " + str(put_job_no))
		else:
			module_logger.info("Put data job not submitted")
