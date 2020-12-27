#!/bin/sh
#downlaod and unpack latest buildroot release
wget -c https://buildroot.org/downloads/buildroot-2020.11.tar.bz2 &&
tar -xf buildroot-2020.11.tar.bz2 &&
rm buildroot-2020.11.tar.bz2 &&
#move configuration dir into board dir
cp -r vidos_av1 buildroot-2020.11/board/ &&
#move configuration for custom built toolchain (sdk) to .config
cp sdk_config  buildroot-2020.11/.config &&
cd buildroot-2020.11/ &&
#build everything including toolchain, then specifically build a reloacatble toolchain (sdk)
make -j$(nproc) &&
make sdk -j$(nproc) &&
#copy and unpack sdk to project root directory
cp output/images/x86_64-buildroot-linux-musl_sdk-buildroot.tar.gz ../ &&
cd ../ &&
tar -xf x86_64-buildroot-linux-musl_sdk-buildroot.tar.gz &&
#rm x86_64-buildroot-linux-musl_sdk-buildroot.tar.gz &&
#run relocate-sdk.sh which does funky path voodoo (I think?)
x86_64-buildroot-linux-musl_sdk-buildroot/relocate-sdk.sh &&
#replace with different config that has options set for prebuilt sdk
cp vidos_av1_config buildroot-2020.11/.config &&
#set toolchain path automagically
sed -i '160 a BR2_TOOLCHAIN_EXTERNAL_PATH="'$PWD'/x86_64-buildroot-linux-musl_sdk-buildroot"' buildroot-2020.11/.config &&
cd buildroot-2020.11/ &&
make -j$(nproc)
