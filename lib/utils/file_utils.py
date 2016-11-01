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

def human_readable_byte_size(size, factor=1024.0):
    num = size

    if abs(num) < factor:
        return str(num)
    else:
        num /= factor

        for unit in ['K', 'M', 'G', 'T', 'P', 'E', 'Z']:
            if abs(num) < 1024.0:
                return "%3.1f%s" % (num, unit)
            num /= factor

        return "%.1f%s" % (num, 'Y')


if __name__ == '__main__':

    x = 1
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x))
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x, 1000.0))

    x = 1000
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x))
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x, 1000.0))

    x = 1024
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x))
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x, 1000.0))

    x = 1124500
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x))
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x, 1000.0))

    x = 1309265515
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x))
    print("x = " + str(x) + '\thuman readable bytes = ' + human_readable_byte_size(x, 1000.0))
