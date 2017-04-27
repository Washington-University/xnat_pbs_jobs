#!/usr/bin/env python3

# import of built-in modules
import getpass
import logging
import logging.config
import os

# import of third party modules

# import of local modules
import ccf.archive as ccf_archive
import ccf.batch_submitter as batch_submitter
import ccf.reapplyfix.one_subject_job_submitter as one_subject_job_submitter
import ccf.subject as ccf_subject
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
module_logger.setLevel(logging.WARNING)  # can be overridden by configuration file


class BatchSubmitter(batch_submitter.BatchSubmitter):

	def __init__(self, tesla_spec):
		super().__init__(ccf_archive.CcfArchive(tesla_spec))

	def submit_jobs(self, username, password, subject_list, config):

		# submit jobs for the listed subjects
		for subject in subject_list:

			submitter = one_subject_job_submitter.OneSubjectJobSubmitter(
				self._archive, self._archive.build_home)
			
			put_server = 'http://db-shadow' + str(self.get_and_inc_shadow_number()) + '.nrg.mir:8080'



			# ici



			
			# get information for the subject from the configuration
			setup_file = config.get_value(subject.subject_id, 'SetUpFile')
			clean_output_first = config.get_bool_value(subject.subject_id, 'CleanOutputFirst')
			processing_stage_str = config.get_value(subject.subject_id, 'ProcessingStage')
			processing_stage = one_subject_job_submitter.ProcessingStage.from_string(processing_stage_str)
			walltime_limit_hrs = config.get_value(subject.subject_id, 'WalltimeLimitHours')
			vmem_limit_gbs = config.get_value(subject.subject_id, 'VmemLimitGbs')
			reg_name = config.get_value(subject.subject_id, 'RegName')
			output_resource_suffix = config.get_value(subject.subject_id, 'OutputResourceSuffix')

			scan = subject.extra

			submitter = one_subject_job_submitter.OneSubjectJobSubmitter(self._archive, self._archive.build_home)

			logger.info("-----")
			logger.info(" Submitting " + submitter.PIPELINE_NAME + " jobs for:")
			logger.info("                project: " + subject.project)
			logger.info("                subject: " + subject.subject_id)
			logger.info("                   scan: " + scan)
			logger.info("             put_server: " + put_server)
			logger.info("             setup_file: " + setup_file)
			logger.info("     clean_output_first: " + str(clean_output_first))
			logger.info("       processing_stage: " + str(processing_stage))
			logger.info("     walltime_limit_hrs: " + str(walltime_limit_hrs))
			logger.info("         vmem_limit_gbs: " + str(vmem_limit_gbs))
			logger.info("               reg_name: " + str(reg_name))
			logger.info(" output_resource_suffix: " + str(output_resource_suffix))
			logger.info("-----")

			submitter.username = username
			submitter.password = password
			submitter.server = 'https://db.humanconnectome.org'

			submitter.project = subject.project
			submitter.subject = subject.subject_id
			submitter.session = subject.subject_id + '_3T'
			submitter.scan = scan

			submitter.reg_name = reg_name
			submitter.output_resource_suffix = output_resource_suffix

			submitter.setup_script = setup_file
			submitter.clean_output_resource_first = clean_output_first
			submitter.put_server = put_server
			submitter.walltime_limit_hours = walltime_limit_hrs
			submitter.vmem_limit_gbs = vmem_limit_gbs

			submitter.submit_jobs(processing_stage)

if __name__ == '__main__':

	# get ConnectomeDB credentials
	userid = input("Connectome DB Username: ")
	password = getpass.getpass("Connectome DB Password: ")

	# read the configuration file
	config_file_name = file_utils.get_config_file_name(__file__)
	logger.info("Reading configuration from file: " + config_file_name)
	config = my_configparser.MyConfigParser()
	config.read(config_file_name)

	# get list of subjects to process
	subject_file_name = file_utils.get_subjects_file_name(__file__)
	logger.info("Retrieving subject list from: " + subject_file_name)
	subject_list = hcp3t_subject.read_subject_info_list(subject_file_name, separator=':')

	# process the subjects in the list
	batch_submitter = BatchSubmitter()
	batch_submitter.submit_jobs(userid, password, subject_list, config)
