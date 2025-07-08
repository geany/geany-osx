#!/bin/bash

VERSION="2.2"

NAME="Geany"
ICONNAME="Geany.icns"
VOLNAME="${NAME} ${VERSION}"
DMGNAME="geany-${VERSION}_osx.dmg"
APPNAME="${NAME}.app"
TMPDIR="tmp-out"

FILE_TYPE=`file Geany.app/Contents/MacOS/geany`
if [[ "$FILE_TYPE" == *"arm64"* ]]; then
	DMGNAME="geany-${VERSION}_osx_arm64.dmg"
fi

mkdir "$TMPDIR"
cp -R "$APPNAME" "$TMPDIR"

test -f "$DMGNAME" && rm "$DMGNAME"
create-dmg \
--volname "$VOLNAME" \
--volicon "$ICONNAME" \
--window-pos 200 120 \
--window-size 700 350 \
--icon-size 128 \
--icon $APPNAME 180 150 \
--hide-extension "$APPNAME" \
--app-drop-link 520 150 \
--format UDBZ \
"$DMGNAME" \
"$TMPDIR"

rm -rf "${TMPDIR}"

if [ -n "$SIGN_CERTIFICATE" ]
then
	codesign -s "$SIGN_CERTIFICATE" --options runtime "$DMGNAME"
fi
