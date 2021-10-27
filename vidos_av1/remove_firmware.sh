#!/usr/bin/env bash
set -e

BOARD_DIR=$(dirname "$0")

DELETE_ARRAY=( "/lib/firmware/" "/usr/lib/libopenh264.so.2.1.1" "/usr/lib/libfdk-aac.so.2.0.1" )

echo "removing files"

for FILE in ${DELETE_ARRAY[@]}; do
	if [ -e $TARGET_DIR/$FILE ]; then rm -r $TARGET_DIR/$FILE
		echo "removed file:" $FILE
	else
		echo $FILE "was already removed"
	fi
done
echo "all done"
