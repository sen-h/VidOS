#!/bin/env bash
SUPPORTED_VID_CODECS=( "av1" "vp8" "vp9" "h264")
STYLE_ARRAY=( "disk" "ram" "hybrid" )
FIRMWARE_ARRAY=( "amdgpu" "radeon" "i915" "none" "all")
VID_SUPPORTED=1
ARG_VALID=0
STYLE_VALID=1

print_help() {
echo -e "\nVidOS build ultilty
usage: vobu -d directory -v [filename/dirname] -s [build style] -f [firmware] -c [codec]
options:\n-h help -- print this help text
-d directory -- path to vidos resource dir
-v filename or directory -- path to video file or directory of video files, supported video codecs: [ "${SUPPORTED_VID_CODECS[@]}" ]
-s build style -- style of output build, one of: [ "${STYLE_ARRAY[@]}" ] Default: ram
-f firmware -- binary graphics drivers, one or multiple of: [ "${FIRMWARE_ARRAY[@]}" ] Default: none
-c codec -- specific video codec to use, if omitted one will be autodetected. one of : [ "${SUPPORTED_VID_CODECS[@]}" ]"
exit $1
}

pickCodec(){
	VID_CODEC=$(ffprobe -v quiet -show_streams $1 | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
	if [ -z $VID_CODEC ];then
		echo "video" $1 "is broken, please specify a different video or remove it from the specified dir";
		exit 1
	else
		SELECTED_CODEC=${CODEC:-$VID_CODEC}
		for CODEC in "${SUPPORTED_VID_CODECS[@]}"; do
			if [ $SELECTED_CODEC = $CODEC ]; then VID_SUPPORTED=0 VID_FORMAT=$SELECTED_CODEC
				if [[ $SELECTED_CODEC = vp[8-9] ]]; then VID_FORMAT="webm"
				elif [ $SELECTED_CODEC = "h264" ] || [ $SELECTED_CODEC = "avc" ]; then VID_FORMAT="avc"
				fi
			fi
		done

		checkArg $VID_SUPPORTED "video" $SELECTED_CODEC "${SUPPORTED_VID_CODECS[*]}"
		KERNEL_PATH=$(find vidos_full_release/ -type d -name "$VID_FORMAT""_kernel")
		if [ ! $KERNEL_PATH ]; then echo "vidos" $VID_FORMAT"_kernel not found.";  exit 1; fi;
	fi

	if [ $VID_FORMAT = "avc" ] && [ ! -e $DIR/.licenceAgreed ]; then
		echo -e "\ndue to various software patents, pre-built binary libraries for the AAC-LC and AVC(H.264/MPEG-4 Part 10)\r
		\rsoftware decoders must be downloaded and installed at build time in order to avoid paying licencing fees
		\rplease read and agree to the following terms of the licence agreement for the OpenH264 Video Codec:"
		read -p "[ press enter to read, press q when finished ]"
		curl http://www.openh264.org/BINARY_LICENSE.txt | less
		read -p "Do you agree to the preceeding terms, Yes or no (y/n)? " -N 1 VAL
		ifAVC
	elif [ $VID_FORMAT = "avc" ] && [ -e $DIR/.licenceAgreed ]; then
		VAL=y && ifAVC
	fi
}

ifAVC() {
	case $VAL in
		y)
			touch $DIR/.licenceAgreed
			if [ ! -e $DIR/avc_external_lib ]; then
				mkdir $DIR/avc_external_lib && pushd $DIR/avc_external_lib
				echo -e "\ninstalling libfdk_aac"
				wget -q -O - https://kojipkgs.fedoraproject.org//packages/fdk-aac-free/2.0.0/7.fc35/x86_64/fdk-aac-free-2.0.0-7.fc35.x86_64.rpm | rpm2cpio | cpio --quiet -idmv
				mv usr/lib64/* usr/lib/ && pushd usr/lib/
				ln -s libfdk-aac.so.2 libfdk-aac.so
				echo -e "\ninstalling libopenh264"
				wget -q -O - http://ciscobinary.openh264.org/libopenh264-2.1.1-linux64.6.so.bz2 | bunzip2 -c > libopenh264.so.2.1.1
				ln -s libopenh264.so.2.1.1 libopenh264.so.6 && ln -s libopenh264.so.6 libopenh264.so
				echo "finished installing external libs"
				popd
				popd
			fi
			cp -r $DIR/avc_external_lib/usr $DIR/initramfs_overlay
		;;
		n)
			echo -e "\nThat's alright, please select a different video and build style that does not require external binary libraries."
			exit 0
		;;
		*)
			echo -e "\r"
			read -p "Do you agree to the preceeding terms, Yes or no (y/n)? " -N 1 VAL
			ifAVC
		;;
	esac
}

checkArg() {
	if [ $3 ]; then echo $2 "is" $3; fi
	if [ $1 -ne 0 ]; then
		echo -e $3 "is not supported as an option/argument for $2!\
		\nsupported options/arguments for $2 are: [ $4 ]"
		print_help 2
	fi
}

while getopts ":hd:v:s:f:c:" opt; do
	case $opt in
		h)
			print_help 0
		;;
		d)
			DIR="$OPTARG"
		;;
		v)
			VIDEO="$OPTARG"
				if [ -d $VIDEO ]; then VIDEO_DIR=$VIDEO; VIDEO_NAME="dir"
				elif [ -f $VIDEO ]; then VIDEO_SELECTION+=($VIDEO);
				fi
		;;
		s)
			STYLE="$OPTARG"
		;;
		f)
			FIRMWARE="$OPTARG";
		;;
		c)
			CODEC="$OPTARG"
		;;
	esac
done

if [ -z $STYLE ]; then STYLE="ram"; fi
if [ -z $FIRMWARE ]; then FIRMWARE="none"; fi
FIRMWARE_SELECTION+=($FIRMWARE)

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

disk_VID_PATH=$DIR/vidos_iso9660/video/
ram_VID_PATH=$DIR/initramfs_overlay/opt/
disk_SED_ARG='s/^/\/media\/video\//'
ram_SED_ARG='s/^/\/opt\//'

checkVid(){
	VID_ENCODING=$(ffprobe -v quiet -show_streams "$1" | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
	VID_NAME=$(echo $FIRST_VID_PATH | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev )
	if [ $VID_ENCODING ] && [ $VID_ENCODING = $2 ]; then
		cp "$1" $3 && echo $(echo $1 | rev | cut -d'/' -f1 | rev | sed $4 ) >> $6/playlist.txt
		echo "copied" $1
	fi
}

export -f checkVid

for STYLE_OPTION in "${STYLE_ARRAY[@]}"; do
        if [ $STYLE == $STYLE_OPTION ]; then
		STYLE_VALID=0
		VID_PATH=$STYLE"_VID_PATH"
		SED_ARG=$STYLE"_SED_ARG"
		if [ $STYLE = "hybrid" ]; then VID_PATH="disk_VID_PATH"; SED_ARG="disk_SED_ARG"; fi
		cp $DIR/S03Video_$STYLE $DIR/initramfs_overlay/etc/init.d/S03Video
	fi
done

if [ $VIDEO_DIR ]; then
	FIRST_VID=$(find $VIDEO_DIR -type f | grep -m1 ".*/*.webm$\|.*/*.mp4$\|.*/*.mkv$")
	pickCodec $FIRST_VID
	find $VIDEO_DIR -type f -iregex ".*/*.webm$\|.*/*.mp4$\|.*/*.mkv$" -exec bash -c 'checkVid "$0" "$1" "$2" "$3" "$4" "$5"' '{}' $SELECTED_CODEC ${!VID_PATH} ${!SED_ARG} $STYLE $ram_VID_PATH \;
else
	FIRST_VID="${VIDEO_SELECTION[0]}"
	pickCodec $FIRST_VID
	echo "using codec" $SELECTED_CODEC
	for SELECTED_VID in "${VIDEO_SELECTION[@]}"; do
		checkVid $SELECTED_VID $SELECTED_CODEC ${!VID_PATH} ${!SED_ARG} $STYLE $ram_VID_PATH
	done
fi

checkArg $STYLE_VALID "style" $STYLE "${STYLE_ARRAY[*]}"

if [ $STYLE = "hybrid" ]; then
	echo "dir" $DIR
	read -r FIRST_VID_PATH<$ram_VID_PATH/playlist.txt
	FIRSTVID_NAME=$(echo $FIRST_VID_PATH | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev )
	FIRSTVID_FULLNAME=$(echo $FIRST_VID_PATH | rev | cut -d'/' -f1 | rev )
	ffmpeg -v quiet -i $disk_VID_PATH/$FIRSTVID_FULLNAME -codec copy -map 0 -f segment -segment_list_type m3u8 \
	-segment_list $ram_VID_PATH/playlist.m3u8 -segment_list_entry_prefix /media/video/ \
	-segment_list_flags +cache -segment_time 10 \
	$disk_VID_PATH/$FIRSTVID_NAME"_segment"%03d.mkv
	echo "updating playlist"
	sed -i '7d' $ram_VID_PATH/playlist.m3u8
	sed -i "6 a /opt/$FIRSTVID_NAME""_segment000.mkv" $ram_VID_PATH/playlist.m3u8
	echo "moving first segment into initramfs"
	mv  $disk_VID_PATH/"$FIRSTVID_NAME"_segment000.mkv $ram_VID_PATH
        sed -i '1s/.*/\/opt\/playlist.m3u8/' $ram_VID_PATH/playlist.txt
	rm $disk_VID_PATH/$FIRSTVID_FULLNAME
fi

for i in "${FIRMWARE_SELECTION[@]}"; do
	FIRMWARE_VALID=1
	for FIRMWARE_OPTION in "${FIRMWARE_ARRAY[@]}"
	do
	        if [ $i = $FIRMWARE_OPTION ]; then
			FIRMWARE_VALID=0
			FIRMWARES=$i
			if [ -h $DIR/firmware/$i ]; then FIRMWARES=$i/*; fi
			if [ $FIRMWARES != "none" ] && [ $(du -c $DIR/firmware/$FIRMWARES | grep "total" | cut -d "t" -f1) -eq 0 ]; then
				echo "downloading linux-firmware package"
				if [ -e linux-firmware-20211027.tar.gz ]; then rm linux-firmware-20211027.tar.gz; fi;
				wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/snapshot/linux-firmware-20211027.tar.gz
				tar -xf linux-firmware-20211027.tar.gz linux-firmware-20211027/amdgpu linux-firmware-20211027/radeon linux-firmware-20211027/i915
				mv linux-firmware-20211027/* $DIR/firmware/
				rm -r linux-firmware-20211027 linux-firmware-20211027.tar.gz
			fi
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
	find vidos_iso9660/video/  -type f -exec rm {} \;
	find initramfs_overlay/opt/ -type f -exec rm {} \;
}

cp $KERNEL_PATH/bzImage $DIR/vidos_iso9660/kernel
cd $DIR/initramfs_overlay
find . | LC_ALL=C sort | cpio --quiet -o -H  newc > ../vidos_iso9660/kernel/rootfs.cpio
cd ../
lz4 -l -9 -c vidos_iso9660/kernel/rootfs.cpio > vidos_iso9660/kernel/rootfs.cpio.lz4
rm vidos_iso9660/kernel/rootfs.cpio
echo "installed "$VIDEO" as a new video and rebuilt playlist"
echo "rebuilding iso"
xorriso -as mkisofs -quiet -o ../vidos_$SELECTED_CODEC"_""$(IFS=_ ; echo "${FIRMWARE_SELECTION[*]}")""_"$VIDEO_NAME.iso -isohybrid-mbr isohdpfx.bin \
-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
vidos_iso9660

delete_stuff
