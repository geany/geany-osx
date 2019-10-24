#!/usr/bin/env python3

import os, sys
from pathlib import Path


if len(sys.argv) != 3:
    print('Error: Incorrect number of arguments of the script (expected 2)')
    sys.exit(1)

rm_dir = sys.argv[1]
all_dir = sys.argv[2]

if not os.path.isdir(rm_dir) or not os.path.isdir(rm_dir):
    print('Error: Both arguments of the script have to be directories')
    sys.exit(1)

rm_dir = str(Path(rm_dir).resolve())
all_dir = str(Path(all_dir).resolve())

print('The script DELETES ALL FILES from "' + rm_dir + '" which are not symlinked from "' + all_dir + '"')
resp = input('Are you sure you want to continue? [Y/n]: ')
if resp != 'Y':
    sys.exit(1)

if not rm_dir.endswith('/'):
    rm_dir = rm_dir + '/'

for i in range(5):
    symlink_targets = set()
    for filename in Path(all_dir).glob('**/*'):
        if os.path.islink(filename):
            target = os.readlink(filename)
            if not os.path.isabs(target):
                target = os.path.join(os.path.dirname(filename), target)
            symlink_targets.add(os.path.normpath(target))

    for filename in Path(rm_dir).glob('**/*'):
        if not str(filename) in symlink_targets:
            try:
                os.remove(filename)
            except:
                pass

for filename in Path(rm_dir).glob('**/*'):
    if os.path.isdir(filename):
        try:
            os.rmdir(filename)
        except:
            pass
