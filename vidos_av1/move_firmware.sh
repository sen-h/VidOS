#!/usr/bin/env bash
set -e

BOARD_DIR=$(dirname "$0")

echo "removing firmware"
rm -r $TARGET_DIR/lib/firmware &&
echo "creating links"
ln -s /media/firmware $TARGET_DIR/lib/firmware &&
echo "all done"
