#!/usr/bin/env python3

import sys
import subprocess
import os

if __name__ == '__main__':
   
	user = sys.argv[1]
	passwd = sys.argv[2]
	database = os.environ["XNAT_PBS_JOBS_REQUESTED_DB"]
	
	project = sys.argv[3]
	subject= sys.argv[4]
	classifier = sys.argv[5]
	scan = sys.argv[6]
	
	CleanOutputFirst = sys.argv[7]
	ProcessingStage = sys.argv[8]
	WalltimeLimitHours = sys.argv[9]
	VmemLimitGbs = sys.argv[10]
	OutputResourceSuffix = sys.argv[11]
		
	COMMAND = os.environ["XNAT_PBS_JOBS_REMOTE"] + "/FunctionalPreprocessing/SubmitFunctionalPreprocessingJobSubmitHPC" 
	HOST= os.environ["XNAT_PBS_JOBS_HOST"]
	proc = subprocess.Popen(["ssh", "-t" , HOST, COMMAND, os.environ["XNAT_PBS_JOBS_CONTROL_REMOTE"], database, project, subject, 
							classifier, scan, CleanOutputFirst, ProcessingStage, WalltimeLimitHours, VmemLimitGbs, 
							OutputResourceSuffix ],stdout=subprocess.PIPE, 
							stdin=subprocess.PIPE, stderr=subprocess.PIPE)
	outs, errs = proc.communicate((user + '\n' + passwd).encode())
	print(outs.decode())
	
	# #####   python submit_job.py USERID PASSWORD MR_TEST HCD0102210 V1_MR rfMRI_REST1_AP False GET_DATA 16 32 preproc

