#!/bin/bash

BUILDROOT_LATEST=buildroot-2021.05
VID_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $1 | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
AUD_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $1 | grep -w codec_name | sed -n 2p | cut -d'=' -f2)
SUPPORTED_VID_CODECS=("av1" "vp8" "vp9")
IS_SUPPORTED=0

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

if [ $IS_SUPPORTED = 1 ]; then
	echo "video passed"
	cp $1 $BUILDROOT_LATEST/output/images/CD_root/video/
	ls $BUILDROOT_LATEST/output/images/CD_root/video/ > $BUILDROOT_LATEST/output/images/playlist.txt
	cp $BUILDROOT_LATEST/output/images/playlist.txt $BUILDROOT_LATEST/output/images/CD_root/video/
	echo "installed "$1" as a new video and rebuilt playlist"
	cd $BUILDROOT_LATEST/output/images/
	echo "rebuilding iso"
	xorriso -as mkisofs -o output.iso -isohybrid-mbr isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
	CD_root
else
	echo "Error: video is encoded in "$VID_CODEC", which is not supported!"
	echo "Please use a video encoded in one of the following formats: "${SUPPORTED_VID_CODECS[@]}
fi
