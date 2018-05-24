#!/usr/bin/env python3

# import of built-in modules
import platform
import os
import sys
# import of third-party modules

# import of local modules
import ccf.subject as ccf_subject
import ccf.one_subject_run_status_checker as one_subject_run_status_checker
import ccf.structural_preprocessing.one_subject_job_submitter as one_subject_job_submitter

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectRunStatusChecker(one_subject_run_status_checker.OneSubjectRunStatusChecker):
	"""Determine run status of CCF Structural Preprocessing."""
	
	@property
	def PIPELINE_NAME(self):
		return one_subject_job_submitter.OneSubjectJobSubmitter.MY_PIPELINE_NAME()
	
	def get_run_status(self, subject_info):

		session_name = subject_info.subject_id + '_' + subject_info.classifier
		
		USER = os.getenv('USER')
		if not USER:
			raise RuntimeError("Environment variable USER must be set")

		qstat_running_cmd = 'qstat -u ' + USER
		qstat_running_cmd += ' | grep ' + subject_info.subject_id + '.Struc'
		qstat_running_cmd += ' | grep " R "'

		qstat_stream = platform.popen(qstat_running_cmd, "r")
		qstat_results = qstat_stream.readline()
		qstat_stream.close()

		if qstat_results:
			return 'R'

		qstat_queued_cmd = 'qstat -u ' + USER
		qstat_queued_cmd += ' | grep ' + subject_info.subject_id + '.Struc'
		qstat_queued_cmd += ' | grep " Q "'
		
		qstat_stream = platform.popen(qstat_queued_cmd, "r")
		qstat_results = qstat_stream.readline()
		qstat_stream.close()

		if qstat_results:
			return 'Q'

		return None
		
if __name__ == "__main__":
	subject = ccf_subject.SubjectInfo(sys.argv[1], sys.argv[2], sys.argv[3])
	status_checker = OneSubjectRunStatusChecker()	
	if status_checker.get_queued_or_running(subject):
		print("-----")
		print("project: " + subject.project)
		print("subject: " + subject.subject_id)
		print("session classifier: " + subject.classifier)
		print("JOB IS ALREADY QUEUED OR RUNNING")
	else:
		print ("-----")		
		print("project: " + subject.project)
		print("subject: " + subject.subject_id)
		print("session classifier: " + subject.classifier)
		print("JOB IS NOT RUNNING")
  	
