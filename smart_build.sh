#!/bin/sh
#download and unpack latest buildroot release
BUILDROOT=buildroot-2021.05
TOOLCHAIN=x86_64-buildroot-linux-musl_sdk-buildroot

test -e "$BUILDROOT"; BUILDROOT_EXISTS=$?
if [ $BUILDROOT_EXISTS -eq 1 ]; then
	echo "Downloading buildroot version: "$BUILDROOT &&
	wget -qO - https://buildroot.org/downloads/$BUILDROOT.tar.gz | tar zxf - &&
	echo "finished unpacking "$BUILDROOT &&

	#move configuration dir into board dir
	cp -r vidos_av1 $BUILDROOT/board/ &&
	echo "moved vidos_av1 dir to "$BUILDROOT
fi

test -e "$TOOLCHAIN"; TOOLCHAIN_EXISTS=$?
if [ $TOOLCHAIN_EXISTS -eq 1 ]; then
	test -e "$BUILDROOT"/"$TOOLCHAIN"/output/images/"$TOOLCHAIN".tar.gz; TOOLCHAIN_EXISTS=$?
	if [ $TOOLCHAIN_EXISTS -eq 1 ]; then
		echo "Building SDK"
		#move configuration for custom built toolchain (sdk) to .config
		cp sdk_config  $BUILDROOT/.config &&
		echo "moved initial SDK configuration to "$BUILDROOT
		cd $BUILDROOT/ &&
		#build everything including toolchain, then specifically build a reloacatble toolchain (sdk)
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
	#replace with different config that has options set for prebuilt sdk
	cp output/images/$TOOLCHAIN.tar.gz ../ &&
	make clean &&
	cd ../ &&
	tar -xf $TOOLCHAIN.tar.gz &&
	rm $TOOLCHAIN.tar.gz &&
	#run relocate-sdk.sh which does funky path nonsense (I think?)
	$TOOLCHAIN/relocate-sdk.sh
	#replace with different config that has options set for prebuilt sdk
fi
test -e "$BUILDROOT/output/images/output.iso"; IMAGE_EXISTS=$?
if [ $IMAGE_EXISTS -eq 1 ]; then
	cp vidos_av1_config $BUILDROOT/.config &&
	#set toolchain path automagically
	sed -i '6 a BR2_TOOLCHAIN_EXTERNAL_PATH="'$PWD'/'$TOOLCHAIN'"' $BUILDROOT/.config &&
	cd $BUILDROOT/ &&
	make olddefconfig &&
	make -j$(nproc)
fi

echo "Build successful!"
