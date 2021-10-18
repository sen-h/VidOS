#!/bin/bash
SUPPORTED_VID_CODECS=("av1" "vp8" "vp9")
IS_SUPPORTED=0
ARG_INVALID=0
STYLE_INVALID=0

function print_help(){
echo "VidOS build ultilty
usage: vobu -d directory -v [filename] -s [build style]
options:
-h help -- print this help text
-d directory -- path to iso filesystem root directory
-v filename -- path to video file
-s build style -- style of output build, can be one of: disk ram hybrid"
}

while getopts ":h:d:v:s:" opt; do
	case $opt in
		h)
			print_help
	        	exit 0
		;;
		d)
			DIR="$OPTARG"
		;;
		v)
			VIDEO="$OPTARG"
		;;
		s)
			STYLE="$OPTARG"
		;;
		*)
			echo "Invalid option -$OPTARG"
			print_help
			exit 2
		;;
	esac
done


if [ -z $STYLE ] || [ "-" == $STYLE ] ; then
        echo "error: no style specified, Please specify one of [disk] [ram] [hybrid]"
        ARG_INVALID=1
fi

test -e $DIR; DIR_EXISTS=$?
if [ -z $DIR ] || [ "-" == $DIR ] || [ $DIR_EXISTS -eq 1 ] ; then
        echo "error: invalid directory, Please specify directory with -d, video with -v and style with -s"
        ARG_INVALID=1

fi

test -e $VIDEO; VIDEO_EXISTS=$?
if [ -z $VIDEO ] || [ "-" == $VIDEO ] || [ $VIDEO_EXISTS -eq 1 ] ; then
        echo "error: invalid video, Please specify directory with -d, video with -v and style with -s"
        ARG_INVALID=1
fi

if [ $ARG_INVALID -eq 1 ] ; then
	exit 1
fi

VIDOS_ISO9660=$(ls $DIR | grep -m 1 "vidos_iso9660_*")

VIDEO_NAME=$(echo $VIDEO | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev )
VID_CODEC=$(ffprobe -v quiet -show_streams $VIDEO | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
AUD_CODEC=$(ffprobe -v quiet -show_streams $VIDEO | grep -w codec_name | sed -n 2p | cut -d'=' -f2)

for CODEC in "${SUPPORTED_VID_CODECS[@]}"
do
	if [ $VID_CODEC = $CODEC ]; then
		IS_SUPPORTED=1
	fi
done

if [[ $VID_CODEC = vp[8-9] ]]; then
	VID_CODEC="webm"
fi

if [ $AUD_CODEC = "opus" ]; then
	echo "audio passed"
else
	echo "Warning: audio is not encoded in opus, and will not play back!"
fi

if [ -z $VIDOS_ISO9660 ]; then
	echo "vidos iso9660 root filesystem not found."
	exit 1
elif [ $VIDOS_ISO9660 != "vidos_iso9660_"$VID_CODEC ] && [ $IS_SUPPORTED = 1 ]; then
	echo "video is not of correct type for currently built VidOS"
	echo "video requires "$VID_CODEC"_build"
	exit 1
fi

if [ $IS_SUPPORTED = 1 ]; then
	echo "video passed"

case $STYLE in

	(disk)
		cp $DIR/S03Video_disk $DIR/initramfs_overlay/etc/init.d/S03Video
		cp $VIDEO $DIR/$VIDOS_ISO9660/video/
		ls $DIR/$VIDOS_ISO9660/video/ | sed 's/^/\/media\/video\//' > playlist.txt
		mv playlist.txt $DIR/$VIDOS_ISO9660/video/
	;;

	(ram)
		cp $DIR/S03Video_ram $DIR/initramfs_overlay/etc/init.d/S03Video
		cp $VIDEO $DIR/initramfs_overlay/opt/
		ls $DIR/initramfs_overlay/opt/ | sed 's/^/\/opt\//' > playlist.txt
		mv playlist.txt $DIR/initramfs_overlay/opt/
	;;

	(hybrid)
		cp $DIR/S03Video_hybrid $DIR/initramfs_overlay/etc/init.d/S03Video

		echo "splitting video $VIDEO into chunks"

	 	ffmpeg -v quiet -i $VIDEO -codec copy -map 0 -f segment -segment_list_type m3u8 \
		-segment_list $DIR/initramfs_overlay/opt/playlist.m3u8 -segment_list_entry_prefix /media/video/ \
		-segment_list_flags +cache -segment_time 10 \
		$DIR/$VIDOS_ISO9660/video/$VIDEO_NAME%03d.mkv

		echo "updating playlist"
		sed -i '7d' $DIR/initramfs_overlay/opt/playlist.m3u8
		sed -i "6 a /opt/$VIDEO_NAME""000.mkv" $DIR/initramfs_overlay/opt/playlist.m3u8
		echo "moving first segment into initramfs"
		cp  $DIR/$VIDOS_ISO9660/video/"$VIDEO_NAME"000.mkv $DIR/initramfs_overlay/opt
	;;

	\?)
        	echo "error: invalid style, Please specify one of [disk] [ram] [hybrid]"&&
        	print_help
        	exit 1
	;;

esac
	cd $DIR/initramfs_overlay
	find . | LC_ALL=C sort | cpio --quiet -o -H  newc > ../$VIDOS_ISO9660/kernel/rootfs.cpio
	cd ../
	lz4 -l -9 -c $VIDOS_ISO9660/kernel/rootfs.cpio > $VIDOS_ISO9660/kernel/rootfs.cpio.lz4
	rm $VIDOS_ISO9660/kernel/rootfs.cpio
	echo "installed "$VIDEO" as a new video and rebuilt playlist"
	echo "rebuilding iso"
	xorriso -as mkisofs -quiet -o ../vidos_$VID_CODEC"_"$VIDEO_NAME.iso -isohybrid-mbr isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
	$VIDOS_ISO9660

	if [ -n "$(ls $VIDOS_ISO9660/video/)" ]; then
		rm $VIDOS_ISO9660/video/*
	elif [ -n "$(ls initramfs_overlay/opt/)" ]; then
		rm initramfs_overlay/opt/*
	fi
else
	echo "video is not of correct type for currently built VidOS"
        echo $VID_CODEC" is not a supported video format, please specify one of the following video formats: "${SUPPORTED_VID_CODECS[@]}
	exit 1
fi


