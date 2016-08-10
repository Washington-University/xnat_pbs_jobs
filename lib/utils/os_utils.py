#!/usr/bin/env python3

"""os_utils.py: Some simple and hopefully useful os utilities."""

# import of built-in modules
import os

# import of third party modules
pass

# path changes and import of local modules
pass

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def getenv_required(var_name):
    value = os.getenv(var_name)
    if value == None:
        raise ValueError("Environment variable " + var_name + " is required, but is not set!")
    return value
