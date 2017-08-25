#!/usr/bin/env python3

"""utils/file_utils.py: Some simple and hopefully useful file related utilities."""

# import of built-in modules
import datetime
import os
import shutil
import sys

# import of third-party modules

# import of local modules

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def writeln(file, line):
    file.write(line + os.linesep)


wl = writeln


def get_config_file_name(source_file_name, use_env_variable=True):
    if use_env_variable:
        config_file_name = os.path.basename(source_file_name)
    else:
        config_file_name = source_file_name

    if config_file_name.endswith('.py'):
        config_file_name = config_file_name[:-3]

    config_file_name += '.ini'

    if use_env_variable:
        xnat_pbs_jobs_control = os.getenv('XNAT_PBS_JOBS_CONTROL')
        if xnat_pbs_jobs_control:
            config_file_name = xnat_pbs_jobs_control + os.sep + config_file_name

    return config_file_name


def get_subjects_file_name(source_file_name, use_env_variable=True):
    if use_env_variable:
        subjects_file_name = os.path.basename(source_file_name)
    else:
        subjects_file_name = source_file_name

    if subjects_file_name.endswith('.py'):
        subjects_file_name = subjects_file_name[:-3]

    subjects_file_name += '.subjects'

    if use_env_variable:
        xnat_pbs_jobs_control = os.getenv('XNAT_PBS_JOBS_CONTROL')
        if xnat_pbs_jobs_control:
            subjects_file_name = xnat_pbs_jobs_control + os.sep + subjects_file_name

    return subjects_file_name


def get_logging_config_file_name(source_file_name, use_env_variable=True):

    if use_env_variable:
        logging_config_file_name = os.path.basename(source_file_name)
    else:
        logging_config_file_name = source_file_name

    if logging_config_file_name.endswith('.py'):
        logging_config_file_name = logging_config_file_name[:-3]

    logging_config_file_name += '.logging.conf'

    if use_env_variable:
        xnat_pbs_jobs_control = os.getenv('XNAT_PBS_JOBS_CONTROL')
        if xnat_pbs_jobs_control:
            logging_config_file_name = xnat_pbs_jobs_control + os.sep + logging_config_file_name

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


DEFAULT_DATE_FORMAT = '%Y-%m-%d %H:%M:%S'


def getmtime_str(path, date_format=DEFAULT_DATE_FORMAT):
    date = datetime.datetime.fromtimestamp(os.path.getmtime(path))
    return date.strftime(date_format)


def make_link_into_copy(full_path, verbose=False, output=sys.stdout):
    if os.path.islink(full_path):
        if verbose:
            print("Making: '" + full_path + "' a copy instead of a symbolic link", file=output)
        linked_to = os.readlink(full_path)
        os.remove(full_path)
        shutil.copy2(linked_to, full_path)


def rm_file_if_exists(full_path, verbose=False, output=sys.stdout):
    if os.path.isfile(full_path):
        if verbose:
            print("Removing file: '" + full_path + "'", file=output)
        os.remove(full_path)


def rm_dir_if_exists(full_path, verbose=False, output=sys.stdout):
    if os.path.isdir(full_path):
        if verbose:
            print("Removing directory: '" + full_path + "' and all its contents", file=output)
        shutil.rmtree(full_path)

def do_all_files_exist(file_name_list, verbose=False, output=sys.stdout, short_circuit=True):
    all_files_exist = True
    
    for file_name in file_name_list:
        if verbose:
            print("Checking for existence of: " + file_name, file=output)
        if os.path.exists(file_name):
            continue

        # If we get here, the most recently checked file does not exist
        print("FILE DOES NOT EXIST: " + file_name, file=output)
        all_files_exist = False

        # If we've been told to short circuit this test and have
        # found 1 file that doesn't exist, then since we know the
        # final return from this function is going to be False,
        # just go ahead and return that now.
        if short_circuit:
            return all_files_exist

    # If we get here, we've cycled through all the files
    return all_files_exist


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
