#!/usr/bin/env python3

# import of built-in modules
import enum

# import of third-party modules

# import of local modules
import utils.ordered_enum as ordered_enum

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility (CCF)"
__maintainer__ = "Timothy B. Brown"

@enum.unique
class ProcessingStage(ordered_enum.OrderedEnum):
    PREPARE_SCRIPTS = 0
    GET_DATA = 1
    PROCESS_DATA = 2
    CLEAN_DATA = 3
    PUT_DATA = 4
    CHECK_DATA = 5
