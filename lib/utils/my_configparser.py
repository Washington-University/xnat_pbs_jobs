#!/usr/bin/env python3

# import of built-in modules
import configparser
import re

# import of third-party modules
# None

# import of local modules
# None

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


class MyConfigParser(configparser.ConfigParser):
	"""
	This subclass of ConfigParser provides a method for getting values
	for a non-existant section.
	"""

	def get_value(self, section, key, default_section='DEFAULT'):
		"""
		Returns the value for the specified key in the specified section.

		If the specified section does not exist, then the value from the
		default_section is returned. If the specified section does exist,
		then the value from that section is returned. Getting the 'value
		from that section' obeys the standard rules of a ConfigParser
		in that if the section exists, but the key does not exist
		in that section, the value corresponding to the key in the
		'DEFAULT' section.
		"""
		if self.has_section(section):
			section_to_use = section
		else:
			section_to_use = default_section

		return self[section_to_use][key]

	def get_bool_value(self, section, key, default_section='DEFAULT'):
		if self.get_value(section, key, default_section) == 'True':
			return True
		else:
			return False

	def get_int_value(self, section, key, default_section='DEFAULT'):
		return int(self.get_value(section, key, default_section))

	def get_values(self, section, key_re, default_section='DEFAULT'):
		if self.has_section(section):
			section_to_use = section
		else:
			section_to_use = default_section

		result = []
		compiled_re = re.compile(key_re)		
		dict_of_items = dict(self.items(section_to_use))

		for key in dict_of_items:
			if compiled_re.search(key):
				result.append(dict_of_items[key])

		return result
			
			
