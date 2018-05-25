#!/usr/bin/env python3

"""
ccf/archive.py: Provides direct access to a CCF project archive.
"""

# import of built-in modules
import glob
import logging
import os

# import of third-party modules

# import of local modules
import xnat.xnat_archive as xnat_archive

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
module_logger.setLevel(logging.WARNING)  # Note: This can be overidden by log file configuration
module_logger.setLevel(logging.DEBUG)  # Note: This can be overidden by log file configuration


class CcfArchive(object):
	"""
	This class provides access to a CCF project data archive.

	This access goes 'behind the scenes' and uses the actual underlying file
	system and assumes a particular organization of directories, resources, and
	file naming conventions. Because of this, a change in XNAT implementation
	or a change in conventions could cause this code to no longer be correct.
	"""

	def __init__(self):
		"""
		Initialize a CcfArchive object.
		"""
		self._xnat_archive = xnat_archive.XNAT_Archive()

	@property
	def NAME_DELIMITER(self):
		"""
		Character used in resource directory names to delimit sections of the resource name.
		For example, in tfMRI_MOVIE1_AP_unproc, the underscore character separates the
		prefix indicating the scan modality, 'tfMRI' = task functional MRI, from the
		section of the name indicating what type of activity the subject was engaged in,
		'MOVIE1' = MOVIE watching task number 1. Similarly the another underscore separates
		the subject activity from the phase encoding indication, 'AP' = Anterior to Posterior.
		Finally, another underscore separates the phase encoding indication from the
		suffix that marks the resource as containing unprocessed data, 'unproc')
		"""
		return '_'

	@property
	def xnat_archive(self):
		"""
		An XNAT_Archive object that provides direct access
		to an XNAT data archive on the file system.
		"""
		return self._xnat_archive

	@property
	def build_home(self):
		"""
		The temporary build/processing space directory root
		"""
		return self._xnat_archive.build_space_root

	@property
	def UNPROC_SUFFIX(self):
		"""
		Suffix to a resource directory name to indicate that the resource contains unprocessed
		data
		"""
		return 'unproc'

	@property
	def PREPROC_SUFFIX(self):
		"""
		Suffix to a resource directory name to indicate that the resource contains preprocessed
		data
		"""
		return "preproc"

	@property
	def FUNCTIONAL_SCAN_MARKER(self):
		"""
		Marker within a resource directory name used to indicate that the resource contains
		functional MRI data
		"""
		return 'fMRI'

	@property
	def RESTING_STATE_SCAN_MARKER(self):
		"""
		Prefix to a resource directory name that indicates that the resource is for a resting
		state functional MRI
		"""
		return 'r' + self.FUNCTIONAL_SCAN_MARKER

	@property
	def TASK_SCAN_MARKER(self):
		"""
		Prefix to a resource directory name that indicates that the resources is for a task
		functional MRI
		"""
		return 't' + self.FUNCTIONAL_SCAN_MARKER

	@property
	def FIX_PROCESSED_SUFFIX(self):
		"""
		Suffix to a resource directory name to indicate that the resource contains FIX processed
		data
		"""
		return "FIX"

	@property
	def RSS_PROCESSED_SUFFIX(self):
		"""
		Suffix to a resource directory name to indicate that the resource contains RSS
		(Resting State Stats) processed data
		"""
		return "RSS"

	@property
	def POSTFIX_PROCESSED_SUFFIX(self):
		"""
		Suffix to a resource directory name to indicate that the resource contains PostFix
		processed data
		"""
		return "PostFix"

	@property
	def REAPPLY_FIX_SUFFIX(self):
		"""
		Suffix to a resource directory name to indicate that the resource contains ReApplyFix
		processed data
		"""
		return "ReApplyFix"

	def session_name(self, subject_info):
		"""
		The conventional session name for a subject in this project archive
		"""
		return subject_info.subject_id + self.NAME_DELIMITER + subject_info.classifier

	def session_dir_full_path(self, subject_info):
		"""
		The full path to the conventional session directory for a subject
		in this project archive
		"""
		session_dir = self.xnat_archive.project_archive_root(subject_info.project)
		session_dir += os.sep + self.session_name(subject_info)
		return session_dir

	def subject_resources_dir_full_path(self, subject_info):
		"""
		The full path to the conventional subject-level resources
		directory for a subject in this project archive
		"""
		return self.session_dir_full_path(subject_info) + os.sep + 'RESOURCES'

	def project_resources_dir_full_path(self, project_id):
		"""
		The full path to the project-level resources directory
		for the specified project
		"""
		return self.xnat_archive.project_resources_root(project_id)

	# scan name property checking methods

	def is_resting_state_scan_name(self, scan_name):
		"""
		Return an indication of whether the specified name is for a
		resting state scan
		"""
		return scan_name.startswith(self.RESTING_STATE_SCAN_MARKER)

	def is_task_scan_name(self, scan_name):
		"""
		Return an indication of whethe the specified name is for a
		task scan
		"""
		return scan_name.startswith(self.TASK_SCAN_MARKER)

	# Unprocessed data paths and names

	def available_structural_unproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resources containing unprocessed structural scans
		for the specified subject
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + 'T[12]w' + self.NAME_DELIMITER + '*' + self.UNPROC_SUFFIX
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_structural_unproc_names(self, subject_info):
		"""
		List of names (not full paths) of structural unprocessed scans
		"""
		dir_list = self.available_structural_unproc_dir_full_paths(subject_info)
		name_list = self._get_scan_names_from_full_paths(dir_list)
		return name_list

	def available_t1w_unproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resources containing unprocessed T1w scans
		for the specified subject
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + 'T1w' + self.NAME_DELIMITER + '*' + self.UNPROC_SUFFIX
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_t1w_unproc_names(self, subject_info):
		"""
		List of names (not full paths) of T1w unprocessed scans
		"""
		dir_list = self.available_t1w_unproc_dir_full_paths(subject_info)
		name_list = self._get_scan_names_from_full_paths(dir_list)
		return name_list

	def available_t2w_unproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resources containing unprocessed T2w scans
		for the specified subject
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + 'T2w' + self.NAME_DELIMITER + '*' + self.UNPROC_SUFFIX
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_t2w_unproc_names(self, subject_info):
		"""
		List of names (not full paths) of T2w unprocessed scans
		"""
		dir_list = self.available_t2w_unproc_dir_full_paths(subject_info)
		name_list = self._get_scan_names_from_full_paths(dir_list)
		return name_list

	def available_functional_unproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resources containing unprocessed functional scans
		for the specified subject
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + '*' + self.FUNCTIONAL_SCAN_MARKER + '*' + self.UNPROC_SUFFIX
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_functional_unproc_names(self, subject_info):
		"""
		List of names (not full paths) of functional scans

		If the full paths available are:

		/HCP/hcpdb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/rfMRI_REST1_PA_unproc
		/HCP/hcpdb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/rfMRI_REST2_AP_unproc
		/HCP/hcpdb/archive/HCP_Staging_7T/arc001/102311_7T/RESOURCES/tfMRI_RETCCW_AP_unproc

		then the scan names available are:

		rfMRI_REST1_PA
		rfMRI_REST2_AP
		tfMRI_RETCCW_AP
		"""
		dir_list = self.available_functional_unproc_dir_full_paths(subject_info)
		name_list = self._get_scan_names_from_full_paths(dir_list)
		return name_list

	def diffusion_unproc_dir_full_path(self, subject_info):
		"""
		Full path to the unprocessed diffusion data resource directory
		"""
		path = self.subject_resources_dir_full_path(subject_info)
		path += os.sep + 'Diffusion' + self.NAME_DELIMITER + self.UNPROC_SUFFIX
		return path

	def available_diffusion_unproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resources containing unprocessing diffusion scans
		for the specified subject
		"""
		dir_list = glob.glob(self.diffusion_unproc_dir_full_path(subject_info))
		return sorted(dir_list)

	def available_diffusion_unproc_names(self, subject_info):
		"""
		List of names (not full paths) of diffusion scan resources
		"""
		dir_list = self.available_diffusion_unproc_dir_full_paths(subject_info)
		name_list = self._get_scan_names_from_full_paths(dir_list)
		return name_list
		
	def running_status_dir_full_path(self, subject_info):
		"""
		Full path to the running status resource directory
		"""
		path = self.subject_resources_dir_full_path(subject_info)
		path += os.sep + 'RunningStatus'
		return path		
 
	def available_running_status_dir_full_paths(self, subject_info):
		"""
		List of full paths to the running status directories
		"""
		dir_list = glob.glob(self.running_status_dir_full_path(subject_info))
		return sorted(dir_list)	
		
	# preprocessed data paths and names

	def structural_preproc_dir_full_path(self, subject_info):
		"""
		Full path to structural preproc resource directory
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info) + os.sep
		path_expr += self.structural_preproc_dir_name(subject_info)
		return path_expr

	def structural_preproc_dir_name(self, subject_info):
		name = 'Structural' + self.NAME_DELIMITER + self.PREPROC_SUFFIX
		return name
	
	def available_structural_preproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing preprocessed structural data
		for the specified subject
		"""
		path_expr = self.structural_preproc_dir_full_path(subject_info)
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def supplemental_structural_preproc_dir_full_path(self, subject_info):
		"""
		Full path to supplemental structural preproc resource directory
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + 'Structural' + self.NAME_DELIMITER + self.PREPROC_SUFFIX
		path_expr += os.sep + 'supplemental'
		return path_expr

	def available_supplemental_structural_preproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing supplemental preprocessed structural
		data for the specified subject
		"""
		path_expr = self.supplemental_structural_preproc_dir_full_path(subject_info)
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def diffusion_preproc_dir_full_path(self, subject_info):
		"""
		Full path to diffusion preproc resource directory
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info) + os.sep
		path_expr += self.diffusion_preproc_dir_name(subject_info)
		return path_expr

	def diffusion_preproc_dir_name(self, subject_info):
		name = 'Diffusion' + self.NAME_DELIMITER + self.PREPROC_SUFFIX
		return name

	def available_diffusion_preproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing preprocessed diffusion data
		for the specified subject
		"""
		path_expr = self.diffusion_preproc_dir_full_path(subject_info)
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_functional_preproc_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing preprocessed functional data
		for the specified subject
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + '*' + self.FUNCTIONAL_SCAN_MARKER + '*' + self.PREPROC_SUFFIX
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_functional_preproc_names(self, subject_info):
		"""
		List of names (not full paths) of functional scans that have been preprocessed
		"""
		dir_list = self.available_functional_preproc_dir_full_paths(subject_info)
		name_list = self._get_scan_names_from_full_paths(dir_list)
		return name_list

	def functional_preproc_dir_full_path(self, subject_info):
		"""
		Full path to functional preprocessed resource for the specified subject 
		(including the specified scan in the subject_info.extra field)
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + self.functional_preproc_dir_name(subject_info)
		return path_expr

	def functional_preproc_dir_name(self, subject_info):
		"""
		Name of functional preprocessed resource for the specified subject
		(including the specified scan in the subject_info.extra field)
		"""
		name = subject_info.extra + '_' + self.PREPROC_SUFFIX
		return name
	
	# processed data paths and names

	def msmall_registration_dir_full_path(self, subject_info):
		"""
		Full path to MSM All registration resource directory
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + 'MSMAllReg'
		return path_expr

	def available_msmall_registration_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing msmall registration results
		data for the specified subject
		"""
		path_expr = self.msmall_registration_dir_full_path(subject_info)
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_fix_processed_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing FIX processed results data
		for the specified subject
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + '*' + self.FIX_PROCESSED_SUFFIX
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def dedrift_and_resample_dir_full_path(self, subject_info):
		"""
		Full path to MSM All DeDrift and Resample resource directory
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + 'MSMAllDeDrift'
		return path_expr

	def available_msmall_dedrift_and_resample_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing msmall dedrift and resample results
		data for the specified subject
		"""
		path_expr = self.dedrift_and_resample_dir_full_path(subject_info)
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_rss_processed_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing RestingStateStats processed results data
		for the specified subject
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + '*' + self.RSS_PROCESSED_SUFFIX
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_postfix_processed_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing PostFix processed results data
		for the specified subject
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + '*' + self.POSTFIX_PROCESSED_SUFFIX
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_task_processed_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing Task Analysis processed results data
		for the specified subject
		"""
		dir_list = []

		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + self.TASK_SCAN_MARKER + '*'
		first_dir_list = glob.glob(path_expr)

		for directory in first_dir_list:
			lastsepindex = directory.rfind(os.sep)
			basename = directory[lastsepindex + 1:]
			index = basename.find(self.NAME_DELIMITER)
			rindex = basename.rfind(self.NAME_DELIMITER)
			if index == rindex:
				dir_list.append(directory)

		return sorted(dir_list)

	def bedpostx_dir_full_path(self, subject_info):
		"""
		Full path to bedpostx processed resource directory
		"""
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + 'Diffusion_bedpostx'
		return path_expr

	def available_bedpostx_processed_dir_full_paths(self, subject_info):
		"""
		List of full paths to any resource containing bedpostx processed results data
		for the specified subject
		"""
		path_expr = self.bedpostx_dir_full_path(subject_info)
		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def reapplyfix_dir_full_path(self, subject_info, scan_name, reg_name=None):
		path_expr = self.subject_resources_dir_full_path(subject_info) + os.sep + scan_name
		path_expr += self.NAME_DELIMITER + self.REAPPLY_FIX_SUFFIX
		if reg_name:
			path_expr += reg_name

		return path_expr

	def available_reapplyfix_dir_full_paths(self, subject_info, reg_name=None):
		path_expr = self.subject_resources_dir_full_path(subject_info)
		path_expr += os.sep + '*' + self.REAPPLY_FIX_SUFFIX
		if reg_name:
			path_expr += reg_name

		dir_list = glob.glob(path_expr)
		return sorted(dir_list)

	def available_reapplyfix_names(self, subject_info, reg_name=None):
		dir_list = self.available_reapplyfix_dir_full_paths(subject_info, reg_name)
		name_list = []
		for directory in dir_list:
			name_list.append(self._get_scan_name_from_path(directory))
		return name_list

	# Internal utility methods

	def _get_scan_names_from_full_paths(self, dir_list):
		name_list = []
		for directory in dir_list:
			name_list.append(self._get_scan_name_from_path(directory))
		return name_list

	def _get_scan_name_from_path(self, path):
		short_path = os.path.basename(path)
		last_char = short_path.rfind(self.NAME_DELIMITER)
		name = short_path[:last_char]
		return name
