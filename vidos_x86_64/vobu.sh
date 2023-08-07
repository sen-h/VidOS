#!/bin/bash
declare -A FORMAT_ARRAY=()
GIT_COMMIT_HASH=$(git log -1 --format=%h)
VOBU_VER="v1.0.0-"$GIT_COMMIT_HASH
VIDOS_COMP_VER="2.0.0-"$GIT_COMMIT_HASH
FIRMWARE_VERSION="20230625"
OPENH264_VERSION="2.3.1"
OPENH264_MD5="49e10a523a32e9a070c63366fc50b6af"
FDKAACFREE_VER="2.0.0"
FDKAACFREE_REL="10.fc38"
FDKAACFREE_MD5="ca20f1d6e77b8045a857b2531eca541c"
FORMAT_ARRAY=([av1]="av1" [vp8]="webm" [vp9]="webm" [h264]="avc")
SUPPORTED_VID_CODECS=( "av1" "vp8" "vp9" "h264")
SUPPORTED_VID_FORMATS=( "av1" "webm" "avc")
STYLE_ARRAY=( "disk" "ram" "hybrid" )
FIRMWARE_ARRAY=( "amdgpu" "radeon" "i915" "none" "all")
BOOTLOADER_ARRAY=( "efi" "bios" "both")
SUFFIX_REGEX=".*/*.webm$\|.*/*.mp4$\|.*/*.mkv$"
VID_SUPPORTED=1
ARG_VALID=0
STYLE_VALID=1
FIRMWARE_VALID=1
BOOTLOADER_VALID=1
FORMAT_SPECIFIED=1
START_DIR=$PWD

remove_ex_libs() {
        DIR=$(find /tmp ! -readable -prune -o -name vidos_components-$VIDOS_COMP_VER-* -print)
	if [ -e $DIR/.licenceAgreed ]; then
		rm -r $DIR/avc_external_lib/ $DIR/.licenceAgreed
		echo "Removed OpenH264 (OpenH264 Video Codec provided by Cisco Systems, Inc.) and fdk-aac-free"
	else
		echo "OpenH264 (OpenH264 Video Codec provided by Cisco Systems, Inc.) and fdk-aac-free are already not installed"
	fi
exit 0
}

print_help() {
echo -e "\nVidOS build utility $VOBU_VER
usage: vobu -d [directory] -v [video filename/dirname] -b [build style] -g [graphics drivers] -f [format] -r [remove codecs] -l [bootloader/manager]
options:\n-h help -- print this help text
-d directory -- path to vidos components dir, Default paths: /tmp, /opt, ./
-v video filename or directory -- path to video file or directory of video files, supported video codecs: [ "${SUPPORTED_VID_CODECS[@]}" ]
-b build style -- style of output build, one of: [ "${STYLE_ARRAY[@]}" ] Default: ram
-g graphics drivers -- binary blob graphics drivers, one or multiple of: [ "${FIRMWARE_ARRAY[@]}" ] Default: none
-f format  -- specific video format to use, if omitted one will be autodetected. one of: [ "${SUPPORTED_VID_FORMATS[@]}" ]
-r remove external codecs -- removes/disables OpenH264 and fdk-aac codecs, OpenH264 Video Codec provided by Cisco Systems, Inc.
-l bootloader/manager for firmware -- select bootloader depending on machine firmware. one of: [ "${BOOTLOADER_ARRAY[@]}" ] Default: bios"
exit $1
}

pickCodec(){
	if [ $FORMAT_SPECIFIED -eq 0 ]; then
		for item in "${SUPPORTED_VID_FORMATS[@]}"
		do
			if [ $item == $SELECTED_FORMAT ]; then
				FORMAT_VALID=0
				VID_SUPPORTED=0
				VID_FORMAT=$SELECTED_FORMAT
			fi
		done
	else
		DETECTED_VID_CODEC=$(ffprobe -v quiet -show_streams "$1" | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
		VID_FORMAT=${FORMAT_ARRAY[$DETECTED_VID_CODEC]}
		if  [ $VID_FORMAT ]; then VID_SUPPORTED=0; fi
		checkArg $VID_SUPPORTED "video" $DETECTED_VID_CODEC "codec" "${SUPPORTED_VID_CODECS[*]}"
	fi
	if [ -z $VID_FORMAT ]; then
		checkArg $VID_SUPPORTED "video" $SELECTED_FORMAT "format" "${SUPPORTED_VID_FORMATS[*]}"
	fi
	KERNEL_PATH=$(find $DIR -type d -name $VID_FORMAT"_kernel")
	if [ ! $KERNEL_PATH ]; then echo -e  "vidos" $VID_FORMAT"_kernel not found."; exit 1; fi;

	if [ $VID_FORMAT == "avc" ] && [ ! -e $DIR/.licenceAgreed ]; then
		echo -e "\nDue to various software patents, and an abundance of caution,
		\rthe pre-built binary libraries
		\rfdk-aac-free (a Third-Party Modified Version of the Fraunhofer FDK AAC Codec Library for Android)
		\rand OpenH264 (OpenH264 Video Codec provided by Cisco Systems, Inc.)
		\rmust be downloaded and installed for the decoding of AAC-LC and AVC(H.264/MPEG-4 Part 10)
		\rat build time in order to avoid paying licencing fees.
		\rPlease understand that these binary codecs are covered by the following licence agreements:
		\rOpenH264: https://www.openh264.org/BINARY_LICENSE.txt
		\rfdk-aac-free based on fdk-aac based on Fraunhofer FDK AAC Codec Library for Android ("FDK AAC Codec"):
		\rhttps://android.googlesource.com/platform/external/aac/+/master/NOTICE"
		read -p "Do you agree to the preceeding terms, Yes or no (y/n)? " -N 1 VAL
		sleep 1
		ifAVC
	elif [ $VID_FORMAT == "avc" ] && [ -e $DIR/.licenceAgreed ]; then
		VAL=y && ifAVC
	fi

}

ifAVC() {
	case $VAL in
		y)
			echo -e "\nOpenH264 and fdk-aac-free can be disabled/uninstalled at any time with the '-r' command line flag\n"
			touch $DIR/.licenceAgreed
			if [ ! -e $DIR/avc_external_lib ]; then
				mkdir $DIR/avc_external_lib && pushd $DIR/avc_external_lib
				echo -e "\ninstalling fdk-aac-free as libfdk_aac"
				wget -q -O - https://kojipkgs.fedoraproject.org//packages/fdk-aac-free/$FDKAACFREE_VER/$FDKAACFREE_REL/x86_64/fdk-aac-free-$FDKAACFREE_VER-$FDKAACFREE_REL.x86_64.rpm \
				| rpm2cpio | cpio --quiet -idmv
				mv usr/lib64/* usr/lib/ && pushd usr/lib/
				echo $FDKAACFREE_MD5"  libfdk-aac.so.2" | md5sum -c -
				if [ ! $? -eq 0 ]; then echo "bad download, please try again!"; remove_ex_libs; exit 1; fi
				ln -s libfdk-aac.so.2 libfdk-aac.so
				echo -e "\ninstalling libopenh264"
				wget -q -O - http://ciscobinary.openh264.org/libopenh264-$OPENH264_VERSION-linux64.7.so.\bz2 | \
				bunzip2 -c > libopenh264.so.$OPENH264_VERSION
                                echo $OPENH264_MD5"  libopenh264.so."$OPENH264_VERSION | md5sum -c -
				if [ ! $? -eq 0 ]; then echo "bad download, please try again!"; remove_ex_libs; exit 1; fi
				chmod +x libopenh264.so.$OPENH264_VERSION
				ln -s libopenh264.so.$OPENH264_VERSION libopenh264.so.7 && ln -s libopenh264.so.7 libopenh264.so
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
	if [ $3 ]; then echo $2":" $3; fi
	if [ $1 -ne 0 ]; then
		echo -e $3 "is not a supported $4 for $2!\
		\nsupported $4"s" for $2 are: [ $5 ]"
		print_help 2
	fi
}

while getopts ":rhd:v:b:g:f:l:" opt; do
	case "$opt" in
		r)
			remove_ex_libs
		;;
		h)
			print_help 0
		;;
		d)
			DIR="$OPTARG"
			echo "Deleting old comp dir in temp (if it exists)"
			if [ ! -d $DIR/vidos_iso9660 ]; then echo "not a valid vidos_components dir!"; exit 1; fi
			find /tmp ! -readable -prune -o -name vidos_components-$VIDOS_COMP_VER-* -print  2> /dev/null -exec rm -r "{}" \;
		;;
		v)
			VIDEO="$OPTARG"
				if [ -d "$VIDEO" ]; then VIDEO_DIR="$VIDEO"; VIDEO_NAME="dir"
				elif [ -f "$VIDEO" ]; then VIDEO_SELECTION+=("$VIDEO");
				fi
		;;
		b)
			STYLE="$OPTARG"
		;;
		g)
			FIRMWARE="$OPTARG";
		;;
		f)
			SELECTED_FORMAT="$OPTARG"
			FORMAT_SPECIFIED=0
		;;
		l)
			BOOTLOADER="$OPTARG";
		;;
	esac
done

if [ -z $DIR ]; then DIR=$(find /tmp ! -readable -prune -o -name vidos_components-$VIDOS_COMP_VER-*  -print); fi
if [ -z $DIR ]; then DIR=$(find /opt/vidos/ -type d -name vidos_components-$VIDOS_COMP_VER); fi
if [ -z $DIR ]; then DIR=$(find -maxdepth 1 -type d -name vidos_components-$VIDOS_COMP_VER); fi
echo $DIR | head -c 5 | grep -q "tmp"
if [ $? -ne 0 ]; then
	cp -r $DIR /tmp/vidos_components-$VIDOS_COMP_VER-$$
	DIR=/tmp/vidos_components-$VIDOS_COMP_VER-$$
fi

if [ -z $STYLE ]; then STYLE="ram"; fi
if [ -z $FIRMWARE ]; then FIRMWARE="none"; fi
if [ -z $BOOTLOADER ]; then BOOTLOADER="bios"; fi
FIRMWARE_SELECTION+=($FIRMWARE)

checkPaths() {
	if [ "$2" == "$3"  ]; then
	        echo "error:" -${1:0:1} "("$1") is unspecified, Please specify a valid" $1 "with -"${1:0:1}
	        ARG_VALID=1
	elif [[ "$1" = -*  ]]; then echo "error:" -${2:0:1} "("$2") is using [" $1 "] as an argument, argument should be a path to a" $2
	        ARG_VALID=1
	elif [ ! -e "$1" ] ; then
	        echo "error: can't find" -${2:0:1} "("$2") \"$1\", Please specify a valid $2 with -${2:0:1}"
		ARG_VALID=1
	fi
}

checkOpts() {
	if [[ "$1" = -*  ]]; then echo "error:" -${2:0:1} "("$2") is using [" $1 "] as an argument, argument should be one of: [" $3 "]"; ARG_VALID=1; fi
	if [ "$3" == "$4" ]; then echo "error:" -${1:0:1} "("$1") is unspecified, please specify one of: [" $2 "]"; ARG_VALID=1; fi
}

checkOpts $STYLE "build style" "${STYLE_ARRAY[*]}"
checkOpts $FIRMWARE "graphics drivers" "${FIRMWARE_ARRAY[*]}"
checkOpts $BOOTLOADER "bootloader" "${BOOTLOADER_ARRAY[*]}"
checkPaths $DIR "directory"
checkPaths "$VIDEO" "video or video dir"

if [ $ARG_VALID -eq 1 ]; then print_help 2; fi

disk_VID_PATH=$DIR/vidos_iso9660/video/
ram_VID_PATH=$DIR/initramfs_overlay/opt/
disk_SED_ARG='s/^/\/media\/video\//'
ram_SED_ARG='s/^/\/opt\//'

find $disk_VID_PATH -iregex $SUFFIX_REGEX -delete
find $ram_VID_PATH -iregex $SUFFIX_REGEX -delete

checkVid(){
	VIDEO_PASS=1
	SUPPORTED_VID_CODECS=( "av1" "vp8" "vp9" "h264")
	declare -A FORMAT_ARRAY=()
	FORMAT_ARRAY=([av1]="av1" [vp8]="webm" [vp9]="webm" [h264]="avc")
	VID_ENCODING=$(ffprobe -v quiet -show_streams "$1" | grep -w codec_name | sed -n 1p | cut -d'=' -f2)
	VID_NAME=$(echo $FIRST_VID_PATH | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev )
	if [ $VID_ENCODING ]; then
		for item in "${SUPPORTED_VID_CODECS[@]}"
		do
		        if [ $item = $VID_ENCODING ]; then
				VIDEO_PASS=0
				FOUND_FORMAT=${FORMAT_ARRAY[$VID_ENCODING]}
		        fi
        	done
	fi
	if [ $VIDEO_PASS -eq 0 ] && [ $FOUND_FORMAT == $2 ]; then
		cp "$1" $3 && echo $(echo $1 | rev | cut -d'/' -f1 | rev | sed $4 ) >> $6/playlist.txt
		echo "copied" $1
	fi
}

export -f checkVid


for BOOTLOADER_OPTION in "${BOOTLOADER_ARRAY[@]}"; do
        if [ $BOOTLOADER = $BOOTLOADER_OPTION ]; then
		BOOTLOADER_VALID=0
		XORRISO_CMD=$BOOTLOADER_OPTION"_XORRISO_CMD"
	fi
done

checkArg $BOOTLOADER_VALID "bootloader" $BOOTLOADER "option" "${BOOTLOADER_ARRAY[*]}"

for STYLE_OPTION in "${STYLE_ARRAY[@]}"; do
        if [ $STYLE = $STYLE_OPTION ]; then
		STYLE_VALID=0
		VID_PATH=$STYLE"_VID_PATH"
		SED_ARG=$STYLE"_SED_ARG"
		if [ $STYLE = "hybrid" ]; then VID_PATH="disk_VID_PATH"; SED_ARG="disk_SED_ARG"; fi
		cp $DIR/S03Video_$STYLE $DIR/initramfs_overlay/etc/init.d/S03Video
	fi
done

checkArg $STYLE_VALID "style" $STYLE "option" "${STYLE_ARRAY[*]}"

for i in "${FIRMWARE_SELECTION[@]}"; do
	for FIRMWARE_OPTION in "${FIRMWARE_ARRAY[@]}"
	do
	        if [ $i = $FIRMWARE_OPTION ]; then
			FIRMWARE_VALID=0
			FIRMWARES=$i
			if [ -h $DIR/firmware/$i ]; then FIRMWARES=$i/*; fi
			if [ $FIRMWARES != "none" ] && [ ! -e $DIR/firmware/$FIRMWARES ]; then
				echo "downloading linux-firmware-$FIRMWARE_VERSION package"
				if [ -e linux-firmware-$FIRMWARE_VERSION.tar.gz ]; then rm linux-firmware-$FIRMWARE_VERSION.tar.gz; fi;
				wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/snapshot/linux-firmware-$FIRMWARE_VERSION.tar.gz
				tar -xf linux-firmware-$FIRMWARE_VERSION.tar.gz linux-firmware-$FIRMWARE_VERSION/amdgpu linux-firmware-$FIRMWARE_VERSION/radeon linux-firmware-$FIRMWARE_VERSION/i915
				mv linux-firmware-$FIRMWARE_VERSION/* $DIR/firmware/
				rm -r linux-firmware-$FIRMWARE_VERSION linux-firmware-$FIRMWARE_VERSION.tar.gz
			fi
			cp -r $DIR/firmware/$FIRMWARES -t $DIR/initramfs_overlay/lib/firmware/
	        fi
	done
done

checkArg $FIRMWARE_VALID "graphics drivers" $i "option" "${FIRMWARE_ARRAY[*]}"

if [ $VIDEO_DIR ]; then
	FIRST_VID=$(find $VIDEO_DIR -type f | grep -m1 $SUFFIX_REGEX)
	pickCodec "$FIRST_VID"
	find $VIDEO_DIR -type f -iregex $SUFFIX_REGEX -exec bash -c 'checkVid "$0" "$1" "$2" "$3" "$4" "$5"' '{}' $VID_FORMAT ${!VID_PATH} ${!SED_ARG} $STYLE $ram_VID_PATH \;
else
	FIRST_VID="${VIDEO_SELECTION[0]}"
	pickCodec "$FIRST_VID"
	echo "format:" $VID_FORMAT
	for SELECTED_VID in "${VIDEO_SELECTION[@]}"; do
		checkVid "$SELECTED_VID" $VID_FORMAT ${!VID_PATH} ${!SED_ARG} $STYLE $ram_VID_PATH
	done
fi

FIRSTVID_NAME=$(echo $FIRST_VID | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev )

if [ $STYLE = "hybrid" ]; then
	read -r FIRST_VID_PATH<$ram_VID_PATH/playlist.txt
	FIRSTVID_NAME=$(echo $FIRST_VID_PATH | rev | cut -d'/' -f1 | cut -d'.' -f2 | rev )
	FIRSTVID_FULLNAME=$(echo $FIRST_VID_PATH | rev | cut -d'/' -f1 | rev )
	echo "splitting" $FIRSTVID_FULLNAME "into segments"
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

cp $KERNEL_PATH/bzImage $DIR/vidos_iso9660/kernel
pushd $DIR/initramfs_overlay
find . | LC_ALL=C sort | cpio --quiet -o -H  newc > $DIR/vidos_iso9660/kernel/rootfs.cpio
popd
lz4 -l -9 -c $DIR/vidos_iso9660/kernel/rootfs.cpio > $DIR/vidos_iso9660/kernel/rootfs.cpio.lz4
rm $DIR/vidos_iso9660/kernel/rootfs.cpio
echo "installed "$VIDEO" as a new video and rebuilt playlist"
echo "rebuilding iso"
pushd $DIR

build_esp(){
	COUNT=$(du -BM ESP/ | head -n 1 | cut -d "M" -f1 )
	dd if=/dev/zero of=vidos_iso9660/efi/efi.img bs=1M count=$COUNT
	mformat -i vidos_iso9660/efi/efi.img
	mcopy -s -i vidos_iso9660/efi/efi.img ESP/* ::
}

case $BOOTLOADER in
	efi)
		mv vidos_iso9660/kernel/* ESP/EFI/BOOT/
		build_esp
	;;

	bios)
		#do nothing here, because bios is default choice and image is setup for bios boot already. This will prolly change by v3.0.0
	;;

	both)
		cp $DIR/vidos_iso9660/kernel/* ESP/EFI/BOOT/
		build_esp
	;;
esac

ISO_NAME="$START_DIR/vidos_"$FIRSTVID_NAME""_"$VID_FORMAT"_""$(IFS=_ ; echo "${FIRMWARE_SELECTION[*]}")""_"$STYLE"_"$BOOTLOADER"_"$(date +%F).iso"

both_XORRISO_CMD="xorriso -as mkisofs -o $ISO_NAME -isohybrid-mbr isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4  -boot-info-table -eltorito-alt-boot -e efi/efi.img -no-emul-boot -append_partition 2 0xef vidos_iso9660/efi/efi.img vidos_iso9660"
efi_XORRISO_CMD="xorriso -as mkisofs -o $ISO_NAME -e efi/efi.img -no-emul-boot -append_partition 2 0xef vidos_iso9660/efi/efi.img vidos_iso9660"
bios_XORRISO_CMD="xorriso -as mkisofs -o $ISO_NAME -isohybrid-mbr isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4  -boot-info-table vidos_iso9660"

${!XORRISO_CMD}

cleanUp() {
	find $DIR -iregex $SUFFIX_REGEX -delete
	find $DIR -name "playlist.*" -delete
	find $DIR/initramfs_overlay -name "S03*" -delete
	rm -rf $DIR/initramfs_overlay/usr
	rm -rf $DIR/initramfs_overlay/lib/firmware/*
	rm -rf $DIR/vidos_iso9660/kernel/*
	rm -rf $DIR/vidos_iso9660/efi/*
	rm -rf $DIR/ESP/EFI/BOOT/bzImage
	rm -rf $DIR/ESP/EFI/BOOT/rootfs.cpio.lz4
}

cleanUp
echo "built" $ISO_NAME
