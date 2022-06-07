#!/bin/sh

DMGFILE="${1}"
APPLEID="${2}"
TEAMID=$(echo $SIGN_CERTIFICATE | sed -n 's/Developer ID Application: .* (\(.*\))/\1/p')

# App-specific password, see https://support.apple.com/en-us/HT204397
stty -echo
printf "Password: "
read PASSWORD
stty echo
printf "\n"

xcrun notarytool submit "${DMGFILE}" --wait --apple-id "${APPLEID}" --password "${PASSWORD}" --team-id "${TEAMID}" && xcrun stapler staple "${DMGFILE}";

