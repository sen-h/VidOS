#!/usr/bin/env bash
set -e

BOARD_DIR=$(dirname "$0")

echo "moving firmware dir"
mv $TARGET_DIR/lib/firmware $BINARIES_DIR &&
echo "creating links"
ln -s /media/firmware $TARGET_DIR/lib/firmware &&
echo "all done"
