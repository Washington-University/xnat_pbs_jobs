#!/usr/bin/env python3

"""hcp/pe_dirs.py: Enumerated type representing Phase Encoding Direction pairs"""

# import of built-in modules
from enum import Enum

# import of third party modules
# None

# import of local modules
# None

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


class PEDirs(Enum):
    RLLR = 1
    PAAP = 2


class PEDir(Enum):
    RL = 1
    LR = 2
    PA = 3
    AP = 4
