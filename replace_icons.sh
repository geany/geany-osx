#!/bin/sh

SRC_PREFIX="Faience"
DEST_PREFIX="${PREFIX}/share/icons/hicolor"

perform_copy () {
	cp "${SRC_PREFIX}/actions/${1}/${SRC_NAME}" "${DEST_PREFIX}/${1}x${1}/actions/${DEST_NAME}"
} 

SRC_NAME=document-save-all.png
DEST_NAME=geany-save-all.png
perform_copy 16
perform_copy 24

SRC_NAME=mail-reply-all.png
DEST_NAME=geany-close-all.png
perform_copy 16
perform_copy 24

SRC_NAME=add-folder-to-archive.png
DEST_NAME=geany-build.png
perform_copy 16
perform_copy 24

