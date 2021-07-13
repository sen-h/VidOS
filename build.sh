#!/bin/sh
BUILDROOT=buildroot-2021.05
TOOLCHAIN=x86_64-buildroot-linux-musl_sdk-buildroot


if [ -z $1 ]; then
	echo "no configuration specifed, please specify either av1 or webm"&&
	exit 1
elif [ $1 = "av1" ] || [ $1 = "webm" ]; then
	echo "building VidOS distribution with "$1" support"
else
	echo $1" is not a supported configuration, please specify either av1 or webm"&&
	exit 1
fi

test -e "$BUILDROOT"; BUILDROOT_EXISTS=$?
if [ $BUILDROOT_EXISTS -eq 1 ]; then
	#download and unpack latest buildroot release
	echo "Downloading buildroot version: "$BUILDROOT &&
	wget -qO - https://buildroot.org/downloads/$BUILDROOT.tar.gz | tar zxf - &&
	echo "finished unpacking "$BUILDROOT &&
	#move configuration dir into board dir
	cp -r vidos_av1 $BUILDROOT/board/ &&
	echo "moved vidos_av1 dir to "$BUILDROOT
fi

test -e $TOOLCHAIN; TOOLCHAIN_EXISTS=$?
if [ $TOOLCHAIN_EXISTS -eq 1 ]; then
	test -e $BUILDROOT/output/images/$TOOLCHAIN.tar.gz; TOOLCHAIN_EXISTS=$?
	if [ $TOOLCHAIN_EXISTS -eq 1 ]; then
		echo "Building SDK"
		#move configuration for custom built toolchain (sdk) to .config
		cp sdk_config  $BUILDROOT/.config &&
		echo "moved initial SDK configuration to "$BUILDROOT
		cd $BUILDROOT/ &&
		#build a reloacatable toolchain (sdk)
		echo "attempting to build SDK" &&
		make olddefconfig &&
		make -j$(nproc) &&
		make sdk -j$(nproc) &&
		echo "Built SDK sucessfully"
		cd ../
	fi
	#copy and unpack sdk to project root directory
	cd $BUILDROOT/ &&
	cp output/images/$TOOLCHAIN.tar.gz ../ &&
	make clean &&
	cd ../ &&
	tar -xf $TOOLCHAIN.tar.gz &&
	rm $TOOLCHAIN.tar.gz &&
	#run relocate-sdk.sh which does funky path nonsense (I think?)
	$TOOLCHAIN/relocate-sdk.sh
fi

test -e $BUILDROOT/output/images/output.iso; IMAGE_EXISTS=$?
if [ $IMAGE_EXISTS -eq 1 ]; then
	echo "patching base configuration for "$1" support" &&
 	patch vidos_base_config vidos_$1.patch -o vidos_$1_config &&
	cp vidos_$1_config $BUILDROOT/.config &&
	#set toolchain path automagically
	sed -i '6 a BR2_TOOLCHAIN_EXTERNAL_PATH="'$PWD'/'$TOOLCHAIN'"' $BUILDROOT/.config &&
	cd $BUILDROOT/ &&
	make olddefconfig &&
	make -j$(nproc)
fi

echo "Build for VidOS_"$1" successful!"
