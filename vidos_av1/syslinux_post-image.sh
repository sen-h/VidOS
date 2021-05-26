#!/usr/bin/env bash
set -e

BOARD_DIR=$(dirname "$0")

export $(cat $PWD/boot/syslinux/syslinux.mk | grep "SYSLINUX_VERSION ="| sed 's: ::g')
export SYSLINUX=syslinux-$SYSLINUX_VERSION
export SYSLINUX_PATH=$BUILD_DIR/$SYSLINUX
echo "found syslinux version: "$SYSLINUX_PATH
mkdir -p $BINARIES_DIR/CD_root/isolinux
mkdir -p $BINARIES_DIR/CD_root/kernel
echo "created CD_root directory"
cp $BOARD_DIR/isolinux.cfg $BINARIES_DIR/CD_root/isolinux
cp $BINARIES_DIR/syslinux/isolinux.bin $BINARIES_DIR/CD_root/isolinux
cp $SYSLINUX_PATH/bios/com32/elflink/ldlinux/ldlinux.c32 $BINARIES_DIR/CD_root/isolinux
cp $BINARIES_DIR/bzImage $BINARIES_DIR/CD_root/kernel
echo "copied files into CD_root directory"
cd $BINARIES_DIR

xorriso -as mkisofs -o output.iso -isohybrid-mbr $SYSLINUX_PATH/bios/mbr/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  CD_root


