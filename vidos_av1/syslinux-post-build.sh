#!/bin/sh

set -e

BOARD_DIR=$(dirname "$0")

    cp -f "$BOARD_DIR/syslinux.cfg" "$BINARIES_DIR/syslinux.cfg"

    # Copy grub 1st stage to binaries, required for genimage
