#!/bin/bash

BUILDROOT_LATEST=buildroot-2021.05
VIDEO=$1
VIDEO_NAME=$(echo $VIDEO | cut -d'/' -f2 | cut -d'.' -f1)
VID_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $VIDEO | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
AUD_CODEC=$(./ffprobe -hide_banner -loglevel 0 -show_streams $VIDEO | grep -w codec_name | sed -n 2p | cut -d'=' -f2)
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

if [ $VID_CODEC = "vp8" ] || [ $VID_CODEC = "vp9" ]; then
	VID_CODEC="webm"
fi
VIDOS_DIST=$BUILDROOT_LATEST/output

VIDOS_ROOTFS=$(ls $VIDOS_DIST/images/ | grep -m 1 "vidos_rootfs_*")

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


	echo $VIDEO_NAME
	rm $VIDOS_DIST/images/$VIDOS_ROOTFS/video/*
	rm $VIDOS_DIST/images/$VIDOS_ROOTFS/kernel/rootfs.cpio.lz4
	rm -r $VIDOS_DIST/images/extract/opt
	mkdir -p $VIDOS_DIST/images/extract/opt


	ffmpeg -i $VIDEO -codec copy -map 0 -f segment -segment_list_type m3u8 \
	-segment_list $VIDOS_DIST/images/extract/opt/playlist.m3u8 -segment_list_entry_prefix /media/video/ \
	-segment_list_flags +cache -segment_time 10 \
	$VIDOS_DIST/images/$VIDOS_ROOTFS/video/$VIDEO_NAME%03d.mkv


	sed -i '7d' $VIDOS_DIST/images/extract/opt/playlist.m3u8
	sed -i "6 a /opt/$VIDEO_NAME""000.mkv" $VIDOS_DIST/images/extract/opt/playlist.m3u8
	cp  $VIDOS_DIST/images/$VIDOS_ROOTFS/video/"$VIDEO_NAME"000.mkv $VIDOS_DIST/images/extract/opt
	cd $VIDOS_DIST/images/extract
	lz4cat ../rootfs.cpio.lz4 | cpio -idmv
	cd ..
	find extract/ | cpio -ov -c | lz4 -l -9 - $VIDOS_ROOTFS/kernel/rootfs.cpio.lz4
	echo "installed "$VIDEO" as a new video and rebuilt playlist"
	echo "rebuilding iso"
	xorriso -as mkisofs -o vidos_$VID_CODEC.iso -isohybrid-mbr isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
	$VIDOS_ROOTFS
else
	echo "video is not of correct type for currently built VidOS"
        echo $VID_CODEC" is not a supported video format, please specify one of the following video formats: "${SUPPORTED_VID_CODECS[@]}
	exit 1
fi
