HCP 7T Diffusion Preprocessing
==============================

Directory: `${XNAT_PBS_JOBS}/7T/DiffusionPreprocessingHCP7T`

Documentation Date: 01 Nov 2016


XNAT-aware Processing
---------------------

* `DiffusionPreprocessingHCP7T_PreEddy.XNAT.sh`

	Executes first phase (pre-eddy) of Diffusion Preprocessing for 7T HCP data

* `DiffusionPreprocessingHCP7T_Eddy.XNAT.sh`

	Executes second phase (eddy) of Diffusion Preprocessing for 7T HCP data

* `DiffusionPreprocessingHCP7T_PostEddy.XNAT.sh`

	Executes third phase (post-eddy) of Diffusion Preprocessing for 7T HCP data


Submission of XNAT-aware Processing
-----------------------------------

* `SubmitDiffusionPreprocessingHCP7TBatch.py`

	* Uses `hcp.hcp7t.diffusion_preprocessing.one_subject_job_submitter.py` to
	  submit jobs for a batch of subjects listed in
	  `SubmitDiffusionPreprocessingHCP7TBatch.subject`
	* Lines in the subject file are of the form
	  `<project>:<structural-reference-project>:<subject-id>`
	  (e.g. `HCP_Staging_7T:HCP_500:102311`)
	* Takes care of distributing the "PUT" jobs across multiple shadow
	  servers.
	* Uses configuration file `SubmitDiffusionPreprocessingHCP7TBatch.ini`
	  to get subject-specific configuration of such things as:
		* Set up file
		* Wall time and virtual memory limits
	* Must activate python3 environment to run
		* `source ${XNAT_PBS_JOBS}/shlib/utils.shlib`
		* `set_g_python_environment`
	  	* `source activate ${g_python_environment}`

* `SubmitDiffusionPreprocessingHCP7TBatch.ini`

	* Configuration file for `SubmitDiffusionPreprocessingHCP7TBatch.py`
	* Contains subject-specific _and cross-subject default_ values for
	  such things as set up files and resource limits

* `SetUpHCPPipeline_DiffusionPreprocHCP7T.sh`

	* Set up file sourced by XNAT-aware processing scripts to set up environment
	  variables to point to tools used.


Checking for Diffusion Preprocessing Completion
-----------------------------------------------

* `CheckDiffusionPreprocessingHCP7TBatch.py`

	* Checks a batch of subjects listed in
	  `CheckDiffusionPreprocessingHCP7TBatch.subjects`
	  for completion status.
	* Lines in the subject list file take the form
	  `<project>:<structural-reference-project>:<subject-id>`
	* Generates status information in 2 status files separated into
	  subjects that are complete (`complete.status`) and subjects that
	  are incomplete (`incomplete.status`)
	* The status files are Tab Separated Values (TSV) files for eashy
	  copying and pasting into a spreadsheet program


Creating Packages
-----------------

* This code is TBW
