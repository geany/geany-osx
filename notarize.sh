#!/bin/sh
#
# Modified version of
# https://github.com/thommcgrath/Beacon/blob/master/Installers/Mac/Build.sh

DMGFILE="${1}"
APPLEID="${2}"
BUNDLEID="org.geany.geany"

# App-specific password, see https://support.apple.com/en-us/HT204397
stty -echo
printf "Password: "
read PASSWORD
stty echo
printf "\n"

echo "Uploading disk image for notarization. This can take a while.";
xcrun altool --notarize-app -f "${DMGFILE}" --primary-bundle-id "${BUNDLEID}" -u "${APPLEID}" -p "${PASSWORD}" > ${TMPDIR}notarize_output 2>&1 || { cat ${TMPDIR}notarize_output; rm -f ${TMPDIR}notarize_output; exit $?; };
cat ${TMPDIR}notarize_output;
REQUESTUUID=$(sed -n 's/RequestUUID = \(.*\)/\1/p' ${TMPDIR}notarize_output);
echo "Disk image has been uploaded. Request UUID is ${REQUESTUUID}. Checking status every 10 seconds:";
STATUS="in progress";
while [ "${STATUS}" = "in progress" ]; do
	sleep 10s;
	xcrun altool --notarization-info "${REQUESTUUID}" -u "${APPLEID}" -p "${PASSWORD}" > ${TMPDIR}notarize_output 2>&1 || { cat ${TMPDIR}notarize_output; rm -f ${TMPDIR}notarize_output; echo "Failed to check on notarization status."; exit $?; };
	STATUS=$(sed -ne 's/^[[:space:]]*Status: \(.*\)$/\1/p' ${TMPDIR}notarize_output);
	echo "Status: ${STATUS}"
done;
if [ "${STATUS}" = "success" ]; then
	echo "Stapling file.";
	xcrun stapler staple "${DMGFILE}";
else
	cat ${TMPDIR}notarize_output;
	rm -f ${TMPDIR}notarize_output;
	echo "Disk image WAS NOT NOTARIZED, status is ${STATUS}.";
	exit 1;
fi;
rm -f ${TMPDIR}notarize_output;
