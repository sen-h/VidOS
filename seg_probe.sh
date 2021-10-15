#!/bin/bash

BUILDROOT_LATEST=buildroot-2021.08
VIDOS_DIST=$BUILDROOT_LATEST/output
VIDOS_ROOTFS=$(ls $VIDOS_DIST/images/ | grep -m 1 "vidos_rootfs_*")
SUPPORTED_VID_CODECS=("av1" "vp8" "vp9")
IS_SUPPORTED=0

function print_help(){
echo "VidOS build ultilty
usage: vobu -v [filename] -s [build style]
options:
-h help -- print this help text
-v filename -- path to video file
-s build style -- style of output build, can be one of: disk ram hybrid"
}

while getopts ":v:s:h" opt; do
case $opt in
    v)
	VIDEO="$OPTARG"
    ;;
    s)
	STYLE="$OPTARG"
    ;;
    h)
	print_help
        exit 0
    ;;
    *)
	echo "Invalid option -$OPTARG"
	print_help
	exit 2
    ;;
  esac
done

test -e $VIDEO; VIDEO_EXISTS=$?
if [ -z $VIDEO ] || [ "-" == $VIDEO ] || [ $VIDEO_EXISTS -eq 1 ] ; then
        echo "error: invalid file, Please specify file with -v and style with -s"&&
        print_help
        exit 1
fi

if [ -z $STYLE ] || [ "-" == $STYLE ] ; then
        echo "error: no style specified, Please specify one of [disk] [ram] [hybrid]"&&
        print_help
        exit 1
fi

VIDEO_NAME=$(echo $VIDEO | cut -d'/' -f2 | cut -d'.' -f1)
VID_CODEC=$(./ffprobe -v quiet -show_streams $VIDEO | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
AUD_CODEC=$(./ffprobe -v quiet -show_streams $VIDEO | grep -w codec_name | sed -n 2p | cut -d'=' -f2)

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

case $STYLE in

	(disk)
		cp $BUILDROOT_LATEST/board/vidos_av1/S03Video_disk $VIDOS_DIST/images/target/etc/init.d/S03Video
		cp $VIDEO $VIDOS_DIST/images/$VIDOS_ROOTFS/video/
		ls $VIDOS_DIST/images/$VIDOS_ROOTFS/video/ | sed 's/^/\/media\/video\//' > playlist.txt
		mv playlist.txt $VIDOS_DIST/images/$VIDOS_ROOTFS/video/
	;;

	(ram)
		cp $BUILDROOT_LATEST/board/vidos_av1/S03Video_ram $VIDOS_DIST/images/target/etc/init.d/S03Video
		cp $VIDEO $VIDOS_DIST/images/target/opt/
		ls $VIDOS_DIST/images/target/opt/ | sed 's/^/\/opt\//' > playlist.txt
		mv playlist.txt $VIDOS_DIST/images/target/opt/
	;;

	(hybrid)
		cp $BUILDROOT_LATEST/board/vidos_av1/S03Video_hybrid $VIDOS_DIST/images/target/etc/init.d/S03Video

	 	ffmpeg -v quiet -i $VIDEO -codec copy -map 0 -f segment -segment_list_type m3u8 \
		-segment_list $VIDOS_DIST/images/target/opt/playlist.m3u8 -segment_list_entry_prefix /media/video/ \
		-segment_list_flags +cache -segment_time 10 \
		$VIDOS_DIST/images/$VIDOS_ROOTFS/video/$VIDEO_NAME%03d.mkv

		echo "updating playlist"
		sed -i '7d' $VIDOS_DIST/images/target/opt/playlist.m3u8
		sed -i "6 a /opt/$VIDEO_NAME""000.mkv" $VIDOS_DIST/images/target/opt/playlist.m3u8
		echo "moving first segment into initramfs"
		cp  $VIDOS_DIST/images/$VIDOS_ROOTFS/video/"$VIDEO_NAME"000.mkv $VIDOS_DIST/images/target/opt
	;;

	\?)
        	echo "error: invalid style, Please specify one of [disk] [ram] [hybrid]"&&
        	print_help
        	exit 1
	;;

esac
	cd $VIDOS_DIST/images/target
	find . | LC_ALL=C sort | cpio --quiet -o -H  newc > ../$VIDOS_ROOTFS/kernel/rootfs.cpio
	cd ../
	lz4 -l -9 -c $VIDOS_ROOTFS/kernel/rootfs.cpio > $VIDOS_ROOTFS/kernel/rootfs.cpio.lz4
	rm $VIDOS_ROOTFS/kernel/rootfs.cpio
	echo "installed "$VIDEO" as a new video and rebuilt playlist"
	echo "rebuilding iso"
	xorriso -as mkisofs -quiet -o vidos_$VID_CODEC.iso -isohybrid-mbr isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
	$VIDOS_ROOTFS

else
	echo "video is not of correct type for currently built VidOS"
        echo $VID_CODEC" is not a supported video format, please specify one of the following video formats: "${SUPPORTED_VID_CODECS[@]}
	exit 1
fi
