#!/bin/sh

VERSION="1.28"

NAME="Geany"
ICONNAME="Geany.icns"
VOLNAME="${NAME} ${VERSION}"
DMGNAME="geany-${VERSION}_osx.dmg"
APPNAME="${NAME}.app"
TMPDIR="tmp-out"

mkdir "$TMPDIR"
cp -r "$APPNAME" "$TMPDIR"

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
"$DMGNAME" \
"$TMPDIR"

rm -rf "${TMPDIR}"

if [ -n "$APPLICATION_CERT" ]
then
	codesign -s "$APPLICATION_CERT" "$DMGNAME"
fi
