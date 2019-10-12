#!/bin/sh

sign() {
	codesign -s "$2" --entitlements geany.entitlements --deep --force --strict=all --options runtime -vvv "$1"
}
export -f sign

sign "./Geany.app/Contents/MacOS/geany-bin" "$SIGN_CERTIFICATE"
sign "./Geany.app/Contents/Resources/libexec/gnome-pty-helper" "$SIGN_CERTIFICATE"
find ./Geany.app \( -name "*.dylib" -or -name "*.so" \) -exec sh -c 'sign "$0" "$SIGN_CERTIFICATE"' {} \;
sign "./Geany.app" "$SIGN_CERTIFICATE"
