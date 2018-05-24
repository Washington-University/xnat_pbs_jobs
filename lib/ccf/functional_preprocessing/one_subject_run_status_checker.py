#!/usr/bin/env python3

# import of built-in modules
import os
import sys
# import of third-party modules

# import of local modules
import ccf.functional_preprocessing.one_subject_job_submitter as one_subject_job_submitter
import ccf.one_subject_run_status_per_scan_checker as one_subject_run_status_per_scan_checker
import ccf.subject as ccf_subject

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectRunStatusChecker(one_subject_run_status_per_scan_checker.OneSubjectRunStatusPerScanChecker):

	@property
	def PIPELINE_NAME(self):
		return one_subject_job_submitter.OneSubjectJobSubmitter.MY_PIPELINE_NAME()
	
if __name__ == "__main__":
	subject = ccf_subject.SubjectInfo(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
	status_checker = OneSubjectRunStatusChecker()	
	if status_checker.get_queued_or_running(subject):
		print("-----")
		print("project: " + subject.project)
		print("subject: " + subject.subject_id)
		print("session classifier: " + subject.classifier)
		print("session scan: " + subject.extra)
		print("JOB IS ALREADY QUEUED OR RUNNING")
	else:
		print ("-----")		
		print("project: " + subject.project)
		print("subject: " + subject.subject_id)
		print("session classifier: " + subject.classifier)
		print("session scan: " + subject.extra)
		print("JOB IS NOT RUNNING")