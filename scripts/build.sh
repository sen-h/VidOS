#!/bin/bash
BUILDROOT=buildroot-2023.05.1
BUILDROOT_IMAGE_PATH=$BUILDROOT/$SYSTEM_TYPE_ARG/images/vidos_release
SUPPORTED_SYSTEM_TYPES=("av1" "webm" "avc")
IS_SUPPORTED=0
TOOLCHAIN=0
PREFIX=0
#SYSTEM_TYPE_ARG=$1

for SYSTEM_TYPE_ARG in "$@"
do

if [ -z $SYSTEM_TYPE_ARG ]; then
	echo "no configuration specifed, please specify one of the following system types: "${SUPPORTED_SYSTEM_TYPES[@]}&&
	exit 1
fi

BUILDROOT_SYSTEM_PATH=$BUILDROOT/$SYSTEM_TYPE_ARG/

for SYSTEM_TYPE in "${SUPPORTED_SYSTEM_TYPES[@]}"
do
	if [ $SYSTEM_TYPE_ARG = $SYSTEM_TYPE ]; then
		IS_SUPPORTED=1
	fi
done

if [ $IS_SUPPORTED = 0 ];then
	echo $SYSTEM_TYPE_ARG" is not a supported configuration, please specify one of the follwing system types: "${SUPPORTED_SYSTEM_TYPES[@]}&&
	exit 1
fi

test -e $BUILDROOT_IMAGE_PATH; BUILDROOT_IMAGE_PATH_EXISTS=$?
if [ $BUILDROOT_IMAGE_PATH_EXISTS -eq 0 ]; then
	VIDOS_ROOTFS=$(ls $BUILDROOT_IMAGE_PATH/ | grep -m 1 "vidos_iso9660_*")
	if [ "$VIDOS_ROOTFS" != "vidos_iso9660_"$SYSTEM_TYPE_ARG ]; then
		yes | rm -r $BUILDROOT
	else
		echo "specified vidos distribution VidOS_"$SYSTEM_TYPE_ARG" has already been built. please run probe.sh"
		exit 0
	fi
fi
echo "building VidOS distribution with "$SYSTEM_TYPE_ARG" support"


test -e $BUILDROOT; BUILDROOT_EXISTS=$?
if [ $BUILDROOT_EXISTS -eq 1 ]; then
	#download and unpack latest buildroot release
	echo "Downloading buildroot version: "$BUILDROOT &&
	wget -qO - https://buildroot.org/downloads/$BUILDROOT.tar.gz | tar zxf - &&
	echo "finished unpacking "$BUILDROOT &&
	#move configuration dir into board dir
	cp -r vidos_x86_64 $BUILDROOT/board/ &&
	echo "moved vidos_x86_64 dir to "$BUILDROOT
fi

echo $BUILDROOT_SYSTEM_PATH
test -e $BUILDROOT_SYSTEM_PATH; SYSTEM_EXISTS=$?
if [ $SYSTEM_EXISTS -eq 1 ]; then
	echo "making system path" $BUILDROOT_SYSTEM_PATH
	mkdir -p $BUILDROOT_SYSTEM_PATH
fi

test -e $BUILDROOT/$SYSTEM_TYPE_ARG/images/vidos_release; IMAGE_EXISTS=$?
if [ $IMAGE_EXISTS -eq 1 ]; then
	echo "patching base configuration for "$SYSTEM_TYPE_ARG" support" &&
 	patch configs/vidos_base_config patches/vidos_$SYSTEM_TYPE_ARG.patch -o "vidos_"$SYSTEM_TYPE_ARG"_config" &&
	cp "vidos_"$SYSTEM_TYPE_ARG"_config" $BUILDROOT/$SYSTEM_TYPE_ARG/.config &&
	pushd $BUILDROOT/ &&
	make O=$SYSTEM_TYPE_ARG olddefconfig &&
	make O=$SYSTEM_TYPE_ARG -j$(nproc)
	popd
fi

echo "Build for VidOS_"$SYSTEM_TYPE_ARG" successful!"

done
