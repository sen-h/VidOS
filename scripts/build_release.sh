#!/bin/bash
BUILDROOT_LATEST="buildroot-2023.05.1"
KERNEL_LATEST="5.4.249"
KERNEL_LATEST_MAJOR=$(echo $KERNEL_LATEST | head -c 1)
SUPPORTED_FORMATS=("av1" "avc" "webm")
SUPPORTED_STYLES=("disk" "ram" "hybrid")

NAME=$1

if [ -z $NAME ]; then NAME=$(date +%F); fi

mkdir -p vidos_release_$NAME/vidos_components
mkdir -p vidos_release_$NAME/SOURCE_AND_LICENSE_INFO

pushd $BUILDROOT_LATEST

for FORMAT in "${SUPPORTED_FORMATS[@]}"; do
        make O=$FORMAT legal-info
	cp -r $FORMAT/legal-info ../vidos_release_$NAME/SOURCE_AND_LICENSE_INFO/legal-info-$FORMAT

	echo $FORMAT/images/vidos_release/$FORMAT"_build"/$FORMAT"_kernel"
	cp -r $FORMAT/images/vidos_release/$FORMAT"_build"/* ../vidos_release_$NAME/vidos_components
done

popd

cp vidos_av1/vobu.sh README.md DEPS vidos_release_$NAME/

wget https://cdn.kernel.org/pub/linux/kernel/v$KERNEL_LATEST_MAJOR.x/linux-$KERNEL_LATEST.tar.xz -O vidos_release_$NAME/SOURCE_AND_LICENSE_INFO/linux-$KERNEL_LATEST.tar.xz
wget https://buildroot.org/downloads/$BUILDROOT_LATEST.tar.xz -O  vidos_release_$NAME/SOURCE_AND_LICENSE_INFO/$BUILDROOT_LATEST.tar.xz
find vidos_release_$NAME -type f -name "rootfs.cpio.lz4" -delete
rm vidos_release_$NAME/vidos_components/vidos_iso9660/video/*
rm -r vidos_release_$NAME/vidos_components/avc_external_lib
