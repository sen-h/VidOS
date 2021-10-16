#!/usr/bin/env bash
set -e

BOARD_DIR=$(dirname "$0")

VIDOS_ROOTFS=vidos_rootfs_$2

export $(cat $PWD/boot/syslinux/syslinux.mk | grep "SYSLINUX_VERSION ="| sed 's: ::g')
export SYSLINUX=syslinux-$SYSLINUX_VERSION
export SYSLINUX_PATH=$BUILD_DIR/$SYSLINUX
echo "found syslinux version: "$SYSLINUX_PATH
mkdir -p $BINARIES_DIR/$VIDOS_ROOTFS/isolinux
mkdir -p $BINARIES_DIR/$VIDOS_ROOTFS/kernel
mkdir -p $BINARIES_DIR/$VIDOS_ROOTFS/video
echo "created $VIDOS_ROOTFS directory"
cp $BOARD_DIR/isolinux.cfg $BINARIES_DIR/$VIDOS_ROOTFS/isolinux
cp $BOARD_DIR/video.mkv $BINARIES_DIR/$VIDOS_ROOTFS/video/video.mkv
ls $BINARIES_DIR/$VIDOS_ROOTFS/video/ > $BINARIES_DIR/playlist.txt
cp $BINARIES_DIR/playlist.txt $BINARIES_DIR/$VIDOS_ROOTFS/video/
cp $BINARIES_DIR/syslinux/isolinux.bin $BINARIES_DIR/$VIDOS_ROOTFS/isolinux
cp $SYSLINUX_PATH/bios/mbr/isohdpfx.bin $BINARIES_DIR
cp $SYSLINUX_PATH/bios/com32/elflink/ldlinux/ldlinux.c32 $BINARIES_DIR/$VIDOS_ROOTFS/isolinux
cp $BINARIES_DIR/bzImage $BINARIES_DIR/$VIDOS_ROOTFS/kernel
echo "copied files into $VIDOS_ROOTFS directory"
cd $BINARIES_DIR

xorriso -as mkisofs -o vidos_$2.iso -isohybrid-mbr isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  $VIDOS_ROOTFS/

