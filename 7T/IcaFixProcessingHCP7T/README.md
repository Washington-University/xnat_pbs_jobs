# xnat_pbs_jobs/7T/IcaFixProcessingHCP7T

Contains code to run ICA+FIX processing on HCP 7T data

The "main" script to run to submit jobs is `SubmitIcaFixProcessingHCP7TBatch.py`. 
This Python 3 script expects to be run in a Conda configured Python 3 environment
with a particular set of libraries available.

In the Washington University CHPC login environment (the HCPpipeline account), 
the typical way to create the appropriate environment is to enter the command
`source activate <env>`, where <env> is the name of a Conda configured 
Python 3 environment.