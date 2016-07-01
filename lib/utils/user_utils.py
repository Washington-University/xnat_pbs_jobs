#!/usr/bin/env python3

"""user_utils.py: Some simple and hopefully useful utilities for interacting with the user."""

# import of built-in modules
pass

# import of third party modules
pass

# path changes and import of local modules
pass

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def should_proceed():
    proceed = input("Proceed? [n]: ").lower()
    return proceed == 'y' or proceed == 'yes'
