"""
BASICS

Simplifies file removal
"""


import os




# Removes empty directories, recursive
# Does not delete the original directory itself
# Based on https://gist.github.com/jacobtomlinson/9031697
# original_path (str): the original location, at start, both must be similar
def remove_empty_dirs(path, original_path):
    if not os.path.isdir(path):
        return

    # remove empty subfolders
    files = os.listdir(path)
    if len(files):
        for f in files:
            fullpath = os.path.join(path, f)
            if os.path.isdir(fullpath):
                remove_empty_dirs(fullpath, original_path)

    # if folder empty, delete it
    files = os.listdir(path)
    if (len(files) == 0) and (path != original_path):
        os.rmdir(path)
