# xnat_pbs_jobs/lib
Library of Python 3 modules that are not specific to any pipeline, project, or study

The `xnat_access.py` module provides utilities and classes for interacting with an 
XNAT installation generally through the XNAT REST interface

The `xnat_archive.py` module provides utilities and classes for interacting with
an XNAT data archive, bypassing the XNAT REST interface and going directly to the 
file system where XNAT stores its data archive.  The `xnat_archive.py` violates
the software engineering principle of information hiding. As such a change in the
implemenation of XNAT could very easily cause this module to stop working.
