#!/bin/bash

BUILDROOT=buildroot-2023.05.1
BUILDROOT_IMAGE_PATH=$BUILDROOT/$PLATFORM/$STYLE_OPTION/images/vidos_release
SUPPORTED_SYSTEM_TYPES=("av1" "webm" "avc" "efi")
IS_SUPPORTED=0
TOOLCHAIN=0
PREFIX=0
STYLE_SET=1
#declare -A STYLE_ARRAY=()
#STYLE_OPTION=$1

while getopts ":p:b:" opt; do
        case "$opt" in
                p)
			PLATFORM="$OPTARG";
			echo $PLATFORM
                ;;
                b)
			STYLE_SET=0
			STYLE="$OPTARG";
			STYLE_ARRAY+=($STYLE)
			echo $STYLE
                ;;

        esac
done

for STYLE_OPTION in "${STYLE_ARRAY[@]}"; do
echo "doin' stuff for" $STYLE_OPTION
echo "doin' stuff for" $STYLE_OPTION
	if [ $STYLE_SET -eq 1 ]; then
		echo "no configuration specifed, please specify one of the following system types: "${SUPPORTED_SYSTEM_TYPES[@]}&&
		exit 1
	fi

	BUILDROOT_SYSTEM_PATH=$BUILDROOT/$PLATFORM/$STYLE_OPTION/

#	for SYSTEM_TYPE in "${SUPPORTED_SYSTEM_TYPES[@]}"
#	do
#		for STYLE_OPTION in "${STYLE_ARRAY[@]}"; do
#			if [ $STYLE_OPTION = $SYSTEM_TYPE ]; then
#				IS_SUPPORTED=1
#			fi
#		done
#	done

echo "doin' stuff for" $STYLE_OPTION
#	if [ $IS_SUPPORTED = 0 ];then
#		echo $STYLE_OPTION" is not a supported configuration, please specify one of the follwing system types: "${SUPPORTED_SYSTEM_TYPES[@]}&&
#		exit 1
#	fi

#	test -e $BUILDROOT_IMAGE_PATH; BUILDROOT_IMAGE_PATH_EXISTS=$?
#	if [ $BUILDROOT_IMAGE_PATH_EXISTS -eq 0 ]; then
#		VIDOS_ROOTFS=$(ls $BUILDROOT_IMAGE_PATH/ | grep -m 1 "vidos_iso9660_*")
#		if [ "$VIDOS_ROOTFS" != "vidos_iso9660_"$STYLE_OPTION ]; then
#			yes | rm -r $BUILDROOT
#		else
#			echo "specified vidos distribution VidOS_"$STYLE_OPTION" has already been built. please run probe.sh"
#			exit 0
#		fi
#	fi
echo "doin' stuff for" $STYLE_OPTION
	echo "building VidOS distribution with "$STYLE_OPTION" support"
	echo "building VidOS distribution with "$STYLE_OPTION" support"


	test -e $BUILDROOT; BUILDROOT_EXISTS=$?
	if [ $BUILDROOT_EXISTS -eq 1 ]; then
		#download and unpack latest buildroot release
		echo "Downloading buildroot version: "$BUILDROOT &&
		wget -O - https://buildroot.org/downloads/$BUILDROOT.tar.gz | tar zxf - &&
		echo "finished unpacking "$BUILDROOT &&
		#move configuration dir into board dir
		cp -r vidos $BUILDROOT/board/ &&
		echo "moved vidos dir to "$BUILDROOT
	fi

	echo $BUILDROOT_SYSTEM_PATH
	test -e $BUILDROOT_SYSTEM_PATH; SYSTEM_EXISTS=$?
	if [ $SYSTEM_EXISTS -eq 1 ]; then
		echo "making system path" $BUILDROOT_SYSTEM_PATH
		mkdir -p $BUILDROOT_SYSTEM_PATH
	fi

	test -e $BUILDROOT/$PLATFORM/$STYLE_OPTION/images/vidos_release; IMAGE_EXISTS=1
	if [ $IMAGE_EXISTS -eq 1 ]; then
		echo "patching base configuration for "$STYLE_OPTION" support" &&
	 	patch configs/$PLATFORM/vidos_base_config patches/vidos_$STYLE_OPTION.patch -o "vidos_"$STYLE_OPTION"_config" &&
		cp --verbose "vidos_"$STYLE_OPTION"_config" $BUILDROOT/$PLATFORM/$STYLE_OPTION/.config &&
		pushd $BUILDROOT/ &&
		make O=$PLATFORM/$STYLE_OPTION olddefconfig &&
		make O=$PLATFORM/$STYLE_OPTION -j$(nproc)
		popd
	fi

	echo "Build for VidOS_"$STYLE_OPTION" successful!"
done
