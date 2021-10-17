#!/usr/bin/env bash
set -e

BOARD_DIR=$(dirname "$0")

VIDOS_ISO9660=vidos_iso9660_$2

VIDOS_BUILD=$2_build

VIDOS_ISO9660_PATH=$BINARIES_DIR/$VIDOS_BUILD/$VIDOS_ISO9660

VIDOS_BUILD_PATH=$BINARIES_DIR/$VIDOS_BUILD/

export $(cat $PWD/boot/syslinux/syslinux.mk | grep "SYSLINUX_VERSION ="| sed 's: ::g')
export SYSLINUX=syslinux-$SYSLINUX_VERSION
export SYSLINUX_PATH=$BUILD_DIR/$SYSLINUX
echo "found syslinux version: "$SYSLINUX_PATH
mkdir -p $VIDOS_ISO9660_PATH/isolinux
mkdir -p $VIDOS_ISO9660_PATH/kernel
mkdir -p $VIDOS_ISO9660_PATH/video
echo "created $VIDOS_ISO9660 directory"

cp -r $BOARD_DIR/initramfs_overlay $VIDOS_BUILD_PATH
cp $BOARD_DIR/S03Video* $VIDOS_BUILD_PATH
cp $BOARD_DIR/vobu.sh $VIDOS_BUILD_PATH
cp $BOARD_DIR/isolinux.cfg $VIDOS_ISO9660_PATH/isolinux
cp $BOARD_DIR/video.mkv $VIDOS_ISO9660_PATH/video/video.mkv
ls $VIDOS_ISO9660_PATH/video/ > $BINARIES_DIR/playlist.txt
cp $BINARIES_DIR/playlist.txt $VIDOS_ISO9660_PATH/video/
cp $BINARIES_DIR/syslinux/isolinux.bin $VIDOS_ISO9660_PATH/isolinux
cp $SYSLINUX_PATH/bios/mbr/isohdpfx.bin $VIDOS_BUILD_PATH
cp $SYSLINUX_PATH/bios/com32/elflink/ldlinux/ldlinux.c32 $VIDOS_ISO9660_PATH/isolinux
cp $BINARIES_DIR/rootfs.cpio.lz4 $VIDOS_ISO9660_PATH/kernel
cp $BINARIES_DIR/bzImage $VIDOS_ISO9660_PATH/kernel
echo "copied files into $VIDOS_ISO9660 directory"

cd $BINARIES_DIR

xorriso -as mkisofs -o vidos_$2.iso -isohybrid-mbr isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  $VIDOS_ISO9660_PATH/

