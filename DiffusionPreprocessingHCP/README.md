HCP 3T Diffusion Preprocessing
==============================

Directory: `${XNAT_PBS_JOBS}/DiffusionPreprocessingHCP`

Documentation Date: 01 Nov 2016


XNAT-aware Processing
---------------------

* `DiffusionPreprocessingHCP_PreEddy.XNAT.sh` 
  
	Executes first phase (pre-eddy) of Diffusion Preprocessing for 3T HCP data

* `DiffusionPreprocessingHCP_Eddy.XNAT.sh`

	Executes second phase (eddy) of Diffusion Preprocessing for 3T HCP data

* `DiffusionPreprocessingHCP_PostEddy.XNAT.sh`

	Executes third phase (post-eddy) of Diffusion Preprocessing for 3T HCP data


Submission of XNAT-aware Processing
-----------------------------------

* `SubmitDiffusionPreprocessingHCP.OneSubject.sh`

	* Submits all PBS jobs necessary for HCP 3T Diffusion Preprocessing for 1 subject. 
	* Takes care of creating a working directory and writing a subject-specific
	  script file for each phase of processing. 
	* Submits the created script files to the PBS job scheduler with appropriate 
	  job dependencies: pre-eddy phase must complete successfully before eddy phase
	  can be run, etc. 
	* Submits the jobs to the appropriate queue so that eddy phase will run on a GPU
	  node.
	* Writes and submits a "PUT" script to push the results into ConnectomeDB			

* `SubmitDiffusionPreprocessingHCP.HCP_500.Batch.sh`

	* Uses `SubmitDiffusionPreprocessingHCP.OneSubject.sh` to submit jobs for a 
	  batch of subjects from the HCP_500 project listed in 
	  `HCP_500.DiffusionPreprocessingHCP.Batch.subjects`
	* Lines in the subject file contain just the subject number, e.g. 100307
	* Takes care of distributing "PUT" jobs across multiple shadow servers

* `SubmitDiffusionPreprocessingHCP.HCP_900.Batch.sh`

	* Like `SubmitDiffusionPreprocessingHCP.HCP_500.Batch.sh` except used for
	  subjects in the HCP_900 project. 
	* Uses subject file `HCP_900.DiffusionPreprocessingHCP.Batch.subjects`

* `SubmitDiffusionPreprocessingHCP.HCP_Staging.Batch.sh`

	* Like `SubmitDiffusionPreprocessingHCP.HCP_500.Batch.sh` except used for
	  subjects in the HCP_Staging project. 
	* Uses subject file `HCP_Staging.DiffusionPreprocessingHCP.Batch.subjects`


The CopyEddyLogs Patch
----------------------

After all (or almost all) of the Diffusion Preprocessing was completely re-run
for all HCP 3T subjects, a decision was made to put some log files generated
by the eddy processing into the packages but in a different location in the
CinaB-style directory hierarchy than the location at which they were generated.

To prevent having files in different places in the CinaB-style packages than
they are placed when the pipelines are run, the actual underlying script files
(from the HCP Pipeline Scripts) were modified to make copies of the log files
into the directory they were to be when placed in packages. 

To avoid having to again re-run all the subjects through Diffusion Preprocessing,
a "patch" pipeline was created: the CopyEddyLogs patch.

Since the actual HCP Pipeline Scripts script files were modified, it should not
be necessary to run the CopyEddyLogs patch on subjects run through the Diffusion
Preprocessing anytime after about 21 Oct 2016.

* `CopyEddyLogsPatchHCP.XNAT.sh`

	* The XNAT-aware script that performs the actual work of getting starting point
	  data and then copying the appropriate eddy logs to a new location.

* `SubmitCopyEddyLogsPatchHCP.OneSubject.sh`

	* Submits all PBS jobs necessary for the CopyEddyLogs patch for 1 subject. 
	* Takes care of creating a working directory and writing a subject-specific
	  script file to perform the patch.
	* Submits the created script file to the PBS job scheduler with appropriate 
	  job dependencies: patch processing must succeed before data is pushed
	  into the database.
	* Writes and submits a "PUT" script to push the results into ConnectomeDB
	  in such a way that updates a database resource instead of overwriting it.

* `SubmitCopyEddyLogsPatchHCP.Batch.sh`

	* Uses `SubmitCopyEddyLogsPatchHCP.OneSubject.sh` to submit jobs for a 
	  batch of subjects listed in `SubmitCopyEddyLogsPatchHCP.Batch.subjects`
	* Lines in the subject file contain the project name and the subject number, 
	  e.g. `HCP_Staging:102109`
	* Takes care of distributing "PUT" jobs across multiple shadow servers


Checking for Diffusion Preprocessing Completion
-----------------------------------------------

* `CheckDiffusionPreprocessingHCPBatch.py`

	* Checks a batch of subjects listed in the local file 
	  `CheckDiffusionPreprocessingHCPBatch.subjects` for completion status.
	* Lines in subject list file take the form `<project>:<subject-id>:None`, 
	  e.g. `HCP_Staging:102109:None`
	* The `None` part is required as the code for reading in subject information 
	  expects a standard 3T subject specification of `<project>:<subject-id>:<processing-directive>`
	* Generates status information in 2 status files separated into subjects that are
	  complete (`complete.status`) and subjects that are incomplete (`incomplete.status`)
	* The status files are Tab Separated Values (TSV) files for easy copying and pasting into 
	  a spreadsheet program


Creating Packages
-----------------

Scripts for package creation have been placed in this pipeline specific directory.
Other previously used package creation mechanisms are now obsolete.

* `DiffusionPackagingHCP.sh`

	* Main script for creating Diffusion Preproc package for one subject.
	* Can be run interactively or submitted to PBS job scheduler.
	* Takes care of getting data out of database, copying files that 
	  belong in the package to a separate location, creating the package zip 
	  file, creating the MD5 checksum, and placing the package file and checksum
	  file in the appropriate pre-release location.

* `SubmitDiffusionPackagingHCP.OneSubject.sh`

	* Submits all PBS jobs necessary for creating a Diffusion Preproc package
	  for one subject.
	* Takes care of creating a working directory
	* Writes a subject-specific script to run `DiffusionPackagingHCP.sh` for the
	  subject.

* `SubmitDiffusionPackagingHCP.HCP_500.Batch.sh`

	* Uses `SubmitDiffusionPackagingHCP.OneSubject.sh` to submit jobs for a
	  batch of subjects from the HCP_500 project listed in
	  `HCP_500.DiffusionPackagingHCP.subjects`
	* Lines in the subject file contain just the subject number, e.g. 100307

* `SubmitDiffusionPackagingHCP.HCP_900.Batch.sh`

	* Like `SubmitDiffusionPackagingHCP.HCP_500.Batch.sh` but for the
	  HCP_900 project. 
	* Uses subject file `HCP_900.DiffusionPackagingHCP.subjects`

* `SubmitDiffusionPackagingHCP.HCP_Staging.Batch.sh`

	* Like `SubmitDiffusionPackagingHCP.HCP_500.Batch.sh` but for the
	  HCP_Staging project. 
	* Uses subject file `HCP_Staging.DiffusionPackagingHCP.subjects`

* `ReleaseNotes.txt`

	* Contains the Release Notes that will be included in the created
	  packages


Generating a Package Report 
---------------------------

A package report for the Diffusion_preproc packages can be generated.

The package report generated is in TSV format and contains information
such as the path to the expected package, an indication of whether the
expected package file exists, the package file's size, etc.

* `GenerateDiffusionPreprocessingPackageReport.py`

	* Creates a package report for a batch of subjects listed in the local
	  file `GenerateDiffusionPreprocessingPackageReport.subjects`
	* Lines in subject list file take the form `<project>:<subject-id>:None`, 
	  e.g. `HCP_Staging:102109:None`


Running the Processing without Submitting Jobs to a Scheduler
-------------------------------------------------------------

Several subjects had to have their processing run on the "old" version of the
CHPC cluster (CHPC1) to maintain compatibility with previously run processing.

However, this had to happen after the CHPC1 cluster had be officially
shut down. Part of this shut down was the loss of the license to use the 
job scheduler on CHPC1. So the `RunDiffusionPreprocessingHCP.OneSubject.sh`
script was written to run the processing without submitting any jobs to 
a job scheduler. It still created individual scripts to do work for 
a specific subject, but then used `ssh` to log in to a particular node
and run the processing instead of submitting the jobs to a scheduler.

Some example individual subject scripts (that use the 
`RunDiffusionPreprocessingHCP.OneSubject.sh` script) are in the OneSubjectRuns
sub-directory. 

These scripts, along with the `RunDiffusionPreprocessingHCP.OneSubject.sh` 
script should be obsolete. They are being kept _temporarily_ for reference.

