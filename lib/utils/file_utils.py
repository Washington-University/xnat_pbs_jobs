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
    config_file_name = source_file_name
    if config_file_name.endswith('.py'):
        config_file_name = config_file_name[:-3]
    config_file_name += '.ini'
    return config_file_name


def get_subjects_file_name(source_file_name):
    subjects_file_name = source_file_name
    if subjects_file_name.endswith('.py'):
        subjects_file_name = subjects_file_name[:-3]
    subjects_file_name += '.subjects'
    return subjects_file_name


def get_logging_config_file_name(source_file_name):
    logging_config_file_name = source_file_name
    if logging_config_file_name.endswith('.py'):
        logging_config_file_name = logging_config_file_name[:-3]
    logging_config_file_name += '.logging.conf'
    return logging_config_file_name


def get_logger_name(source_file_name):
    logger_name = source_file_name
    
    xnat_pbs_jobs = os.getenv('XNAT_PBS_JOBS')
    if not xnat_pbs_jobs:
        print("Environment variable XNAT_PBS_JOBS must be set!")
        exit(1)

    if logger_name.startswith(xnat_pbs_jobs + os.sep + 'lib'):
        logger_name = logger_name[len(xnat_pbs_jobs + os.sep + 'lib'):]

    if logger_name.endswith('.py'):
        logger_name = logger_name[:-3]

    if logger_name.startswith('.' + os.sep):
        logger_name = logger_name[2:]

    if logger_name.startswith(os.sep):
        logger_name = logger_name[1:]

    logger_name = logger_name.replace(os.sep, '.')

    return logger_name


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
