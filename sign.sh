#!/bin/sh

sign() {
	codesign -s "$SIGN_CERTIFICATE" --entitlements geany.entitlements --deep --force --strict=all --options runtime -vvv $1
}
export -f sign

sign "./Geany.app/Contents/MacOS/geany-bin"
sign "./Geany.app/Contents/Resources/libexec/gnome-pty-helper"
find ./Geany.app \( -name "*.dylib" -or -name "*.so" \) -exec sh -c 'sign "$0"' {} \;
sign "./Geany.app"
