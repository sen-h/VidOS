#!/bin/bash

BUILDROOT_LATEST=buildroot-2021.05
VID_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $1 | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
AUD_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $1 | grep -w codec_name | sed -n 2p | cut -d'=' -f2)
SUPPORTED_VID_CODECS=("av1" "vp8" "vp9")
IS_SUPPORTED=0
VIDOS_ROOTFS=$(ls $BUILDROOT_LATEST/output/images/ | grep -m 1 "vidos_rootfs_*")
if [ $AUD_CODEC = "opus" ]; then
	echo "audio passed"
else
	echo "Warning: audio is not encoded in opus, and will not play back!"
fi

for CODEC in "${SUPPORTED_VID_CODECS[@]}"
do
	if [ $VID_CODEC = $CODEC ]; then
		IS_SUPPORTED=1
	fi
done

if [ -z $VIDOS_ROOTFS ]; then
	echo "vidos root filesystem has not been built! Please run build.sh."
	exit 1
elif [ $VIDOS_ROOTFS != "vidos_rootfs_"$VID_CODEC ] && [ $IS_SUPPORTED = 1 ]; then
	echo "video is not of correct type for currently built VidOS"
	echo "video requires vidos_"$VID_CODEC
	exit 1
fi

if [ $IS_SUPPORTED = 1 ]; then
	echo "video passed"
	cp $1 $BUILDROOT_LATEST/output/images/$VIDOS_ROOTFS/video/
	ls $BUILDROOT_LATEST/output/images/$VIDOS_ROOTFS/video/ > $BUILDROOT_LATEST/output/images/playlist.txt
	cp $BUILDROOT_LATEST/output/images/playlist.txt $BUILDROOT_LATEST/output/images/$VIDOS_ROOTFS/video/
	echo "installed "$1" as a new video and rebuilt playlist"
	cd $BUILDROOT_LATEST/output/images/
	echo "rebuilding iso"
	xorriso -as mkisofs -o vidos_$VID_CODEC.iso -isohybrid-mbr isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
	$VIDOS_ROOTFS
else
	echo "video is not of correct type for currently built VidOS"
        echo $VID_CODEC" is not a supported video format, please specify one of the following video formats: "${SUPPORTED_VID_CODECS[@]}
	exit 1
fi
