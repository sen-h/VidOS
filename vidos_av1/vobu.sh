#!/bin/bash
SUPPORTED_VID_CODECS=( "av1" "vp8" "vp9" "h264")
STYLE_ARRAY=( "disk" "ram" "hybrid" )
FIRMWARE_ARRAY=( "amdgpu" "radeon" "i915" "none" "all")
VID_SUPPORTED=1
ARG_VALID=0
STYLE_VALID=1
FIRMWARE_SELECTION=()

print_help() {
echo -e "\nVidOS build ultilty
usage: vobu -d directory -v [filename] -s [build style] -f [firmware]
options:\n-h help -- print this help text
-d directory -- path to iso filesystem root directory
-v filename -- path to video file, supported video codecs: [ "${SUPPORTED_VID_CODECS[@]}" ]
-s build style -- style of output build, one of: [ "${STYLE_ARRAY[@]}" ]
-f firmware -- binary graphics drivers, one or multiple of: [ "${FIRMWARE_ARRAY[@]}" ]"
exit $1
}

while getopts ":hd:v:s:f:" opt; do
	case $opt in
		h)
			print_help 0
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
		f)
			FIRMWARE="$OPTARG"; FIRMWARE_SELECTION+=($FIRMWARE)
		;;
	esac
done

checkArg() {
	if [ $3 ]; then echo $2 "is" $3; fi
	if [ $1 -ne 0 ]; then
		echo -e $3 "is not supported as an option/argument for $2!\
		\nsupported options/arguments for $2 are: [ $4 ]"
		print_help 2
	fi
}

checkPaths() {
	if [ "$2" == "$3"  ]; then
	        echo "error:" -${1:0:1} "("$1") is unspecified, Please specify a valid" $1 "with -"${1:0:1}
	        ARG_VALID=1
	elif [[ "$1" = -*  ]]; then echo "error:" -${2:0:1} "("$2") is using [" $1 "] as an argument, argument should be a path to a" $2
	        ARG_VALID=1
	elif [ ! -e $1 ] ; then
	        echo "error: can't find" -${2:0:1} "("$2") \"$1\", Please specify a valid $2 with -${2:0:1}"
		ARG_VALID=1
	fi
}

checkOpts() {
	if [[ "$1" = -*  ]]; then echo "error:" -${2:0:1} "("$2") is using [" $1 "] as an argument, argument should be one of: [" $3 "]"; ARG_VALID=1; fi
	if [ "$3" == "$4" ]; then echo "error:" -${1:0:1} "("$1") is unspecified, please specify one of: [" $2 "]"; ARG_VALID=1; fi
}

checkOpts $STYLE "style" "${STYLE_ARRAY[*]}"
checkOpts $FIRMWARE "firmware" "${FIRMWARE_ARRAY[*]}"
checkPaths $DIR "directory"
checkPaths $VIDEO "video"

if [ $ARG_VALID -eq 1 ]; then print_help 2; fi

VIDOS_ISO9660=$(ls $DIR | grep -m 1 "vidos_iso9660_*")

disk_VID_PATH=$DIR/$VIDOS_ISO9660/video/
ram_VID_PATH=$DIR/initramfs_overlay/opt/
disk_SED_ARG='s/^/\/media\/video\//'
ram_SED_ARG='s/^/\/opt\//'

VIDEO_NAME=$(echo $VIDEO | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev )
VID_CODEC=$(ffprobe -v quiet -show_streams $VIDEO | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
AUD_CODEC=$(ffprobe -v quiet -show_streams $VIDEO | grep -w codec_name | sed -n 2p | cut -d'=' -f2)

for CODEC in "${SUPPORTED_VID_CODECS[@]}"; do
	if [ $VID_CODEC = $CODEC ]; then VID_SUPPORTED=0 VID_FORMAT=$VID_CODEC
		if [[ $VID_CODEC = vp[8-9] ]]; then VID_FORMAT="webm"
		elif [ $VID_CODEC = "h264" ]; then VID_FORMAT="avc"
		fi
	fi
done

if [ $AUD_CODEC = "opus" ]; then echo "audio passed"; else
	echo "Warning: audio is" $AUD_CODEC", not opus, so it will not play back!"
fi

if [ -z $VIDOS_ISO9660 ]; then echo "vidos iso9660 root filesystem not found."
	exit 1
elif [ $VIDOS_ISO9660 != "vidos_iso9660_"$VID_FORMAT ] && [ $VID_SUPPORTED = 0 ]; then
	echo "video is not of correct type for currently built VidOS"
	echo "video requires "$VID_FORMAT"_build"
	exit 1
fi

checkArg $VID_SUPPORTED "video" $VID_CODEC "${SUPPORTED_VID_CODECS[*]}"

for STYLE_OPTION in "${STYLE_ARRAY[@]}"; do
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

checkArg $STYLE_VALID "style" $STYLE "${STYLE_ARRAY[*]}"

for i in "${FIRMWARE_SELECTION[@]}"; do
	FIRMWARE_VALID=1
	for FIRMWARE_OPTION in "${FIRMWARE_ARRAY[@]}"
	do
	        if [ $i = $FIRMWARE_OPTION ]; then
			FIRMWARE_VALID=0
			FIRMWARES=$i
			if [ -h $DIR/firmware/$i ]; then FIRMWARES=$i/*; fi
			cp -r $DIR/firmware/$FIRMWARES -t $DIR/initramfs_overlay/lib/firmware/
	        fi
	done
			checkArg $FIRMWARE_VALID "firmware" $i "${FIRMWARE_ARRAY[*]}"
done

delete_stuff(){
	DELETE_ARRAY=( "initramfs_overlay/usr/*" "initramfs_overlay/lib/firmware/*" )
	echo "removing files"
	for FILE in ${DELETE_ARRAY[@]}; do
		if [ -e $FILE ]; then rm -r $FILE
			echo "removed file:" $FILE
		else
			echo $FILE "was already removed"
		fi
	done

	if [ -n "$(ls $VIDOS_ISO9660/video/)" ]; then rm $VIDOS_ISO9660/video/*
	elif [ -n "$(ls initramfs_overlay/opt/)" ]; then rm initramfs_overlay/opt/*; fi

}

cd $DIR/initramfs_overlay
if [ $VID_CODEC = "h264" ]; then
	echo "due to various software patents, pre-built binary libraries for the AAC-LC and AVC(H.264/MPEG-4 Part 10)"
	echo "software decoders must be downloaded and installed at build time in order to avoid paying licencing fees"
	echo "please read and agree to the following terms of the licence agreement for the OpenH264 Video Codec:"
	read -p "[ press enter to read, press q when finished ]"
	curl http://www.openh264.org/BINARY_LICENSE.txt | less
	read -p "Do you agree to the preceeding terms, Yes or no (y/n)? " -n 1 VAL
	if [ $VAL = y ]; then
		echo
		echo "installing libfdk_aac"
		wget -q -O - https://kojipkgs.fedoraproject.org//packages/fdk-aac-free/2.0.0/7.fc35/x86_64/fdk-aac-free-2.0.0-7.fc35.x86_64.rpm | rpm2cpio | cpio -idmv
		mv usr/lib64/* usr/lib/
		pushd usr/lib/
		ln -s libfdk-aac.so.2 libfdk-aac.so
		echo "installing libopenh264"
		wget -q -O - http://ciscobinary.openh264.org/libopenh264-2.1.1-linux64.6.so.bz2 | bunzip2 -c > libopenh264.so.2.1.1
		ln -s libopenh264.so.2.1.1 libopenh264.so.6 && ln -s libopenh264.so.6 libopenh264.so
		echo "finished installing external libs"
		popd
	else
		echo
		echo "thats alright, please select a different video and build style that does not require external binary libraries"
		delete_stuff
		exit 0
	fi
fi

find . | LC_ALL=C sort | cpio --quiet -o -H  newc > ../$VIDOS_ISO9660/kernel/rootfs.cpio
cd ../
lz4 -l -9 -c $VIDOS_ISO9660/kernel/rootfs.cpio > $VIDOS_ISO9660/kernel/rootfs.cpio.lz4
rm $VIDOS_ISO9660/kernel/rootfs.cpio
echo "installed "$VIDEO" as a new video and rebuilt playlist"
echo "rebuilding iso"
xorriso -as mkisofs -quiet -o ../vidos_$VID_CODEC"_""$(IFS=_ ; echo "${FIRMWARE_SELECTION[*]}")""_"$VIDEO_NAME.iso -isohybrid-mbr isohdpfx.bin \
-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
$VIDOS_ISO9660

delete_stuff
