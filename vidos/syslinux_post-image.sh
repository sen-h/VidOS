
#!/usr/bin/env bash
set -e
echo "binaries dir" $BINARIES_DIR
BOARD_DIR=$(dirname "$0")

VIDOS_ISO9660=vidos_iso9660

VIDOS_BUILD=$2_build

VIDOS_RELEASE_PATH=$BINARIES_DIR/vidos_release/
VIDOS_BUILD_PATH=$BINARIES_DIR/vidos_release/$VIDOS_BUILD/
VIDOS_ISO9660_PATH=$BINARIES_DIR/vidos_release/$VIDOS_BUILD/$VIDOS_ISO9660

export $(cat $PWD/boot/syslinux/syslinux.mk | grep "SYSLINUX_VERSION ="| sed 's: ::g')
export SYSLINUX=syslinux-$SYSLINUX_VERSION
export SYSLINUX_PATH=$BUILD_DIR/$SYSLINUX
echo "found syslinux version: "$SYSLINUX_PATH
mkdir -p $VIDOS_ISO9660_PATH/isolinux
mkdir -p $VIDOS_ISO9660_PATH/efi
mkdir -p $VIDOS_ISO9660_PATH/kernel
mkdir -p $VIDOS_ISO9660_PATH/video
mkdir -p $VIDOS_BUILD_PATH/firmware
mkdir -p $VIDOS_BUILD_PATH/$2_kernel
echo "created $VIDOS_ISO9660 directory"

cp -r $BOARD_DIR/initramfs_overlay $VIDOS_BUILD_PATH
cp -r $BOARD_DIR/ESP $VIDOS_BUILD_PATH

rm $VIDOS_BUILD_PATH/initramfs_overlay/opt/.gitkeep
rm $VIDOS_BUILD_PATH/initramfs_overlay/etc/init.d/.gitkeep
rm $VIDOS_BUILD_PATH/initramfs_overlay/lib/firmware/.gitkeep

cp $BOARD_DIR/S03Video* $VIDOS_BUILD_PATH
cp $BOARD_DIR/vobu.sh $VIDOS_RELEASE_PATH

if [ -e efi/images/efi-part/EFI/ ]; then
	echo "efi found!"
	cp -r efi/images/efi-part/EFI/ $VIDOS_BUILD_PATH/ESP
fi

cp $BOARD_DIR/isolinux.cfg $VIDOS_ISO9660_PATH/isolinux
cp $BINARIES_DIR/syslinux/isolinux.bin $VIDOS_ISO9660_PATH/isolinux
cp $SYSLINUX_PATH/bios/mbr/isohdpfx.bin $VIDOS_BUILD_PATH
cp $SYSLINUX_PATH/bios/com32/elflink/ldlinux/ldlinux.c32 $VIDOS_ISO9660_PATH/isolinux

pushd $VIDOS_BUILD_PATH/firmware/
if [ ! -L all ]; then ln -s . all; fi
touch none
popd
cp $BINARIES_DIR/rootfs.cpio.lz4 $VIDOS_BUILD_PATH/$2_kernel
cp $BINARIES_DIR/bzImage $VIDOS_BUILD_PATH/$2_kernel
echo "copied files into $VIDOS_ISO9660 directory"

yes | $VIDOS_RELEASE_PATH/vobu.sh -d $VIDOS_RELEASE_PATH/$VIDOS_BUILD/ -v $BOARD_DIR/test_vids/$2_video.*
