#!/usr/bin/env python3

"""utils/file_utils.py: Some simple and hopefully useful file related utilities."""

# import of built-in modules
import os

# import of third party modules
pass

# import of local modules
pass

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def writeln(file, line):
    file.write(line + os.linesep)

wl = writeln

def get_config_file_name(source_file_name):
    config_file_name = os.path.basename(source_file_name)
    if config_file_name.endswith('.py'):
        config_file_name = config_file_name[:-3]
    config_file_name += '.ini'
    return config_file_name
