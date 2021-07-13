#!/bin/sh

BUILDROOT_LATEST=buildroot-2021.05
VID_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $1 | grep -w codec_name | sed -n 1p)
AUD_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $1 | grep -w codec_name | sed -n 2p)

if [ $AUD_CODEC = "codec_name=opus" ]; then
	echo "audio passed"
else
	echo "Warning: audio is not encoded in opus, and will not play back!"
fi

if [ $VID_CODEC = "codec_name=av1" ]; then
	echo "video passed"
	cp $1 $BUILDROOT_LATEST/output/images/CD_root/video/video.mkv
	echo "installed $1 as new video"
	cd $BUILDROOT_LATEST/output/images/
	xorriso -as mkisofs -o output.iso -isohybrid-mbr isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
	CD_root
elif [ $VID_CODEC != "codec_name=av1" ]; then
	echo "Error: Video is not encoded in AV1, please try again!"
fi
