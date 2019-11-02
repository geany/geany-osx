#!/bin/sh

~/.local/bin/gtk-mac-bundler geany.bundle
cp -R Papirus Papirus-Dark ./Geany.app/Contents/Resources/share/icons
