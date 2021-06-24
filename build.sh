#!/bin/sh
#download and unpack latest buildroot release
BUILDROOT_LATEST=buildroot-2021.02.3
wget -c https://buildroot.org/downloads/$BUILDROOT_LATEST.tar.gz &&
tar -xf $BUILDROOT_LATEST.tar.gz &&
rm $BUILDROOT_LATEST.tar.gz &&
echo "finished unpacking "$BUILDROOT_LATEST &&
#move configuration dir into board dir
cp -r vidos_av1 $BUILDROOT_LATEST/board/ &&
echo "moved vidos_av1 dir to "$BUILDROOT_LATEST &&

#move configuration for custom built toolchain (sdk) to .config
cp sdk_config  $BUILDROOT_LATEST/.config &&
echo "moved initial configuration to "$BUILDROOT_LATEST
cd $BUILDROOT_LATEST/ &&
#build everything including toolchain, then specifically build a reloacatble toolchain (sdk)


#echo "attempting to build SDK" &&
make -j$(nproc) &&
make sdk -j$(nproc) &&
echo "Built SDK sucessfully"
#copy and unpack sdk to project root directory
cp output/images/x86_64-buildroot-linux-musl_sdk-buildroot.tar.gz ../ &&
cd ../ &&
tar -xf x86_64-buildroot-linux-musl_sdk-buildroot.tar.gz &&
rm x86_64-buildroot-linux-musl_sdk-buildroot.tar.gz &&
#run relocate-sdk.sh which does funky path nonsense (I think?)
x86_64-buildroot-linux-musl_sdk-buildroot/relocate-sdk.sh &&
#replace with different config that has options set for prebuilt sdk
cp vidos_av1_config $BUILDROOT_LATEST/.config &&
#set toolchain path automagically
sed -i '160 a BR2_TOOLCHAIN_EXTERNAL_PATH="'$PWD'/x86_64-buildroot-linux-musl_sdk-buildroot"' $BUILDROOT_LATEST/.config &&
cd $BUILDROOT_LATEST/ &&
make clean &&
make -j$(nproc)
