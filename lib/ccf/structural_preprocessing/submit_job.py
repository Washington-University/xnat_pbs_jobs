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
	
	CleanOutputFirst = sys.argv[6]
	ProcessingStage = sys.argv[7]
	WalltimeLimitHours = sys.argv[8]
	VmemLimitGbs = sys.argv[9]
	OutputResourceSuffix = sys.argv[10]
	BrainSize = sys.argv[11]
	UsePrescanNormalized = sys.argv[12]
		
	COMMAND = os.environ["XNAT_PBS_JOBS_REMOTE"] + "/StructuralPreprocessing/SubmitStructuralPreprocessingJobSubmitHPC" 
	HOST= os.environ["XNAT_PBS_JOBS_HOST"]
	proc = subprocess.Popen(["ssh", "-t" , HOST, COMMAND, os.environ["XNAT_PBS_JOBS_CONTROL_REMOTE"], database, project, subject, 
							classifier, CleanOutputFirst, ProcessingStage, WalltimeLimitHours, VmemLimitGbs, 
							OutputResourceSuffix, BrainSize, UsePrescanNormalized ],stdout=subprocess.PIPE, 
							stdin=subprocess.PIPE, stderr=subprocess.PIPE)
	outs, errs = proc.communicate((user + '\n' + passwd).encode())
	print(outs.decode())
	
	# #####   python submit_job.py USERID PASSWORD MR_TEST HCD0102210 V1_MR False GET_DATA 48 32 Structural_preproc 150 False

