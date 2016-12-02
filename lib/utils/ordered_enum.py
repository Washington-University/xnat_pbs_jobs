#!/usr/bin/env python3

"""See https://docs.python.org/3/library/enum.html section 8.13.13.2. OrderedEnum"""

# import of built-in modules
import enum

# import of third-party modules
# None

# import of local modules
# None

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


class OrderedEnum(enum.Enum):

    def __ge__(self, other):
        if self.__class__ is other.__class__:
            return self.value >= other.value
        return NotImplemented

    def __gt__(self, other):
        if self.__class__ is other.__class__:
            return self.value > other.value
        return NotImplemented

    def __le__(self, other):
        if self.__class__ is other.__class__:
            return self.value <= other.value
        return NotImplemented

    def __lt__(self, other):
        if self.__class__ is other.__class__:
            return self.value < other.value
        return NotImplemented

    @classmethod
    def from_string(cls, string_value):
        for val in cls:
            if val.name == string_value:
                return val

        error_msg = "'" + string_value + "'" \
            " does not correspond to one of the define values for " + str(cls)
        raise ValueError(error_msg)
