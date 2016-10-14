#!/usr/bin/env python3

"""os_utils.py: Some simple and hopefully useful os utilities."""


# import of built-in modules
import os
import logging


# import of third party modules
pass


# import of local modules
pass


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


# create and configure a module logger
log = logging.getLogger(__file__)
log.setLevel(logging.WARNING)
sh = logging.StreamHandler()
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(sh)


def getenv_required(var_name):
    value = os.getenv(var_name)
    if value == None:
        raise ValueError("Environment variable " + var_name + " is required, but is not set!")
    return value


def lndir(src, dst, show_log=False, ignore_existing_dst_files=False):

    if not os.path.isdir(src):
        raise OSError("ERROR: %s is not a valid directory." % src)

    if not os.path.isdir(dst) and os.path.exists(dst):
        raise OSError("ERROR: %s exists but is not a valid directory." % dst)

    if not os.path.exists(dst):
        os.mkdir(dst)


    for root, dirs, files in os.walk(src):
        log.debug("root:  " + root)

        for filename in files:
            log.debug("filename: " + filename)
            try:
                src_filename = '%s/%s' % (root, filename)
                dst_filename = '%s%s/%s' % (dst, root.replace(src, ''), filename)
                print("linking: %s --> %s" % (dst_filename, src_filename))
                os.symlink(src_filename, dst_filename)

            except FileExistsError as e:
                if not ignore_existing_dst_files:
                    raise e

        for dirname in dirs:
            log.debug("dirname: " + dirname)
            try:
                os.mkdir('%s%s/%s' % (dst, root.replace(src, ''), dirname))
            except OSError:
                pass


if __name__ == "__main__":
    lndir('/home/HCPpipeline/usr', '/home/HCPpipeline/usr1', show_log=True, ignore_existing_dst_files=True)




        
