#!/usr/bin/env python3

import sys

# Quick and dirty script to remove all properties of the given name from a css file
# Usage example: remove_property.py gtk.css "-gtk-icon-shadow"

fname = sys.argv[1]
property = sys.argv[2]

with open(fname, 'r') as file:
    data = file.read()

pos1 = data.find(property)
while pos1 != -1:
	pos2 = data.find(';', pos1)
	removed_str = data[pos1:pos2]
	data = data[:pos1] + data[pos2+1:]
	if removed_str.find('/*') != -1:
		print('warning: comment inside removed string: ' + removed_str)
	pos1 = data.find(property)

with open(fname, "w") as file:
    file.write(data)
