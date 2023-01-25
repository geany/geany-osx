#!/bin/sh

rm -rf ./Geany.app
iconutil -c icns ./iconbuilder.iconset --output Geany.icns
~/.new_local/bin/gtk-mac-bundler geany.bundle
cp -R Papirus Papirus-Dark ./Geany.app/Contents/Resources/share/icons
