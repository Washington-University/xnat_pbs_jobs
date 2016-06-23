# xnat_pbs_jobs/7T/lib
Library of Python 3 modules that are specific to the HCP 7T project, but not
specific to running any particular pipeline as part of that project.

The `hcp7t_archive.py` module provides utilities and classes for interacting
with an XNAT data archive that conforms to the HCP 7T resources and naming
standards. This bypasses the XNAT REST interface.

The `hcp7t_subject.py` module provides utilities and classes for working with
the necessary information to fully specify and find information about an 
HCP 7T subject.  This includes reading and writing files containing these
subject specifications.
