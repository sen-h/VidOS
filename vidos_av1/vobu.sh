#!/bin/bash
SUPPORTED_VID_CODECS=( "av1" "vp8" "vp9" )
STYLE_ARRAY=( "disk" "ram" "hybrid" )
FIRMWARE_ARRAY=( "amdgpu" "radeon" "i915" )
VID_SUPPORTED=1
ARG_VALID=0
STYLE_VALID=1
FIRMWARE_VALID=1

print_help() {
echo "VidOS build ultilty
usage: vobu -d directory -v [filename] -s [build style] -f [firmware]
options:
-h help -- print this help text
-d directory -- path to iso filesystem root directory
-v filename -- path to video file, supported video codecs: "${SUPPORTED_VID_CODECS[@]}"
-s build style -- style of output build: "${STYLE_ARRAY[@]}"
-f firmware -- binary graphics drivers: "${FIRMWARE_ARRAY[@]}""
}

checkArg() {
	if [ $3 ]; then
		echo $2 "is" $3
	fi
	if [ $1 -ne 0 ]; then
		echo $3 "is not supported as an option for "$2"!"
		echo -e "supported options for" $2 "are:" $4"\n"
		print_help
		exit 2
	fi
}

checkPaths() {
	test -e $1; FILE_EXISTS=$?
	if [ -z $1 ] || [ "-" = $1 ] || [ $FILE_EXISTS -eq 1 ] ; then
	        echo "error: invalid "$2", Please specify directory with -d, video with -v, style with -s and firmware with -f"
	        ARG_VALID=1
	fi
}

checkOpts() {
	if [ -z $1 ] || [ "-" = $1 ] ; then
	        echo "invalid option"
	        ARG_VALID=1
	fi
}

while getopts ":h:d:v:s:f:" opt; do
	case $opt in
		h)
			print_help
	        	exit 0
		;;
		d)
			DIR="$OPTARG"
			checkPaths $DIR "directory"
		;;
		v)
			VIDEO="$OPTARG"
			checkPaths $VIDEO "video"
		;;
		s)
			STYLE="$OPTARG"
			checkOpts $STYLE "style"
		;;
		f)
			FIRMWARE="$OPTARG"
			checkOpts $FIRMWARE "firmware"
		;;
		*)
			echo "Either empty or invalid option: $OPTARG"
			print_help
			exit 2
		;;
	esac
done

checkArg $ARG_VALID "argument"

VIDOS_ISO9660=$(ls $DIR | grep -m 1 "vidos_iso9660_*")

disk_VID_PATH=$DIR/$VIDOS_ISO9660/video/
ram_VID_PATH=$DIR/initramfs_overlay/opt/
disk_SED_ARG='s/^/\/media\/video\//'
ram_SED_ARG='s/^/\/opt\//'

VIDEO_NAME=$(echo $VIDEO | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev )
VID_CODEC=$(ffprobe -v quiet -show_streams $VIDEO | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
AUD_CODEC=$(ffprobe -v quiet -show_streams $VIDEO | grep -w codec_name | sed -n 2p | cut -d'=' -f2)

for CODEC in "${SUPPORTED_VID_CODECS[@]}"
do
	if [ $VID_CODEC = $CODEC ]; then
		VID_SUPPORTED=0
		VID_FORMAT=$VID_CODEC
		if [[ $VID_CODEC = vp[8-9] ]]; then
			VID_FORMAT="webm"
		fi
	fi
done

if [ $AUD_CODEC = "opus" ]; then
	echo "audio passed"
else
	echo "Warning: audio is" $AUD_CODEC", not opus, so it will not play back!"
fi

if [ -z $VIDOS_ISO9660 ]; then
	echo "vidos iso9660 root filesystem not found."
	exit 1
elif [ $VIDOS_ISO9660 != "vidos_iso9660_"$VID_FORMAT ] && [ $VID_SUPPORTED = 0 ]; then
	echo "video is not of correct type for currently built VidOS"
	echo "video requires "$VID_FORMAT"_build"
	exit 1
fi

checkArg $VID_SUPPORTED "video" $VID_CODEC "${SUPPORTED_VID_CODECS[*]}"


for STYLE_OPTION in "${STYLE_ARRAY[@]}"
do
        if [ $STYLE = $STYLE_OPTION ]; then
		STYLE_VALID=0
		if [ $STYLE = "hybrid" ];then
	                ffmpeg -v quiet -i $VIDEO -codec copy -map 0 -f segment -segment_list_type m3u8 \
	                -segment_list $ram_VID_PATH/playlist.m3u8 -segment_list_entry_prefix /media/video/ \
	                -segment_list_flags +cache -segment_time 10 \
	                $disk_VID_PATH/$VIDEO_NAME%03d.mkv
	                echo "updating playlist"
	                sed -i '7d' $ram_VID_PATH/playlist.m3u8
	                sed -i "6 a /opt/$VIDEO_NAME""000.mkv" $ram_VID_PATH/playlist.m3u8
	                echo "moving first segment into initramfs"
	                cp  $disk_VID_PATH/"$VIDEO_NAME"000.mkv $ram_VID_PATH
		else
			VID_PATH=$STYLE"_VID_PATH"
			SED_ARG=$STYLE"_SED_ARG"
			cp $DIR/S03Video_$STYLE $DIR/initramfs_overlay/etc/init.d/S03Video
			cp $VIDEO ${!VID_PATH}
			ls ${!VID_PATH} | sed ${!SED_ARG} > playlist.txt
			mv playlist.txt ${!VID_PATH}
		fi
        fi
done

checkArg $STYLE_VALID "style" $STYLE

for FIRMWARE_OPTION in "${FIRMWARE_ARRAY[@]}"
do
        if [ $FIRMWARE = $FIRMWARE_OPTION ]; then
		FIRMWARE_VALID=0
		cp -r $DIR/firmware/$FIRMWARE $DIR/initramfs_overlay/firmware
        fi
done

checkArg $FIRMWARE_VALID "firmware" $FIRMWARE "${FIRMWARE_ARRAY[*]}"

	cd $DIR/initramfs_overlay
	find . | LC_ALL=C sort | cpio --quiet -o -H  newc > ../$VIDOS_ISO9660/kernel/rootfs.cpio
	cd ../
	lz4 -l -9 -c $VIDOS_ISO9660/kernel/rootfs.cpio > $VIDOS_ISO9660/kernel/rootfs.cpio.lz4
	rm $VIDOS_ISO9660/kernel/rootfs.cpio
	echo "installed "$VIDEO" as a new video and rebuilt playlist"
	echo "rebuilding iso"
	xorriso -as mkisofs -quiet -o ../vidos_$VID_CODEC"_"$FIRMWARE"_"$VIDEO_NAME.iso -isohybrid-mbr isohdpfx.bin \
	-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
	$VIDOS_ISO9660

	if [ -n "$(ls $VIDOS_ISO9660/video/)" ]; then
		rm $VIDOS_ISO9660/video/*
	elif [ -n "$(ls initramfs_overlay/opt/)" ]; then
		rm initramfs_overlay/opt/*
	elif [ -n "$(ls initramfs_overlay/firmware/)" ]; then
		rm initramfs_overlay/firmware/*
	fi


