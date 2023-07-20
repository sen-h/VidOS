#!/bin/bash
BUILDROOT_LATEST="buildroot-2023.05.1"
KERNEL_LATEST="5.4.249"
KERNEL_LATEST_MAJOR=$(echo $KERNEL_LATEST | head -c 1)
SUPPORTED_FORMATS=("av1" "avc" "webm")
SUPPORTED_STYLES=("disk" "ram" "hybrid")

NAME=$1

if [ -z $NAME ]; then NAME=$(date +%F); fi

mkdir -p vidos_release_$NAME/vidos_components
mkdir -p vidos_release_$NAME-source-and-licence-info/

pushd $BUILDROOT_LATEST

for FORMAT in "${SUPPORTED_FORMATS[@]}"; do
        make O=$FORMAT -j$(nproc) legal-info
	cp -r $FORMAT/legal-info/* ../vidos_release_$NAME-source-and-licence-info/
	cp -r $FORMAT/legal-info/manifest.csv ../vidos_release_$NAME-source-and-licence-info/$FORMAT-manifest.csv
	cp -r $FORMAT/legal-info/host-manifest.csv ../vidos_release_$NAME-source-and-licence-info/$FORMAT-host-manifest.csv
	cp -r $FORMAT/legal-info/buildroot.config ../vidos_release_$NAME-source-and-licence-info/$FORMAT-buildroot.config

	echo $FORMAT/images/vidos_release/$FORMAT"_build"/$FORMAT"_kernel"
	cp -r $FORMAT/images/vidos_release/$FORMAT"_build"/* ../vidos_release_$NAME/vidos_components
done

	mv ../vidos_release_$NAME-source-and-licence-info/host-source ../vidos_release_$NAME-source-and-licence-info/combined-host-sources
	mv ../vidos_release_$NAME-source-and-licence-info/host-licenses ../vidos_release_$NAME-source-and-licence-info/combined-host-licenses
	mv ../vidos_release_$NAME-source-and-licence-info/sources ../vidos_release_$NAME-source-and-licence-info/combined-sources
	mv ../vidos_release_$NAME-source-and-licence-info/licenses ../vidos_release_$NAME-source-and-licence-info/combined-licenses
	rm ../vidos_release_$NAME-source-and-licence-info/host-manifest.csv
	rm ../vidos_release_$NAME-source-and-licence-info/manifest.csv
	rm ../vidos_release_$NAME-source-and-licence-info/buildroot.config
	rm ../vidos_release_$NAME-source-and-licence-info/legal-info.sha256

popd

cp vidos_av1/vobu.sh README.md vidos_release_$NAME/

wget https://cdn.kernel.org/pub/linux/kernel/v$KERNEL_LATEST_MAJOR.x/linux-$KERNEL_LATEST.tar.xz -O vidos_release_$NAME-source-and-licence-info/linux-$KERNEL_LATEST.tar.xz
wget https://buildroot.org/downloads/$BUILDROOT_LATEST.tar.xz -O  vidos_release_$NAME-source-and-licence-info/$BUILDROOT_LATEST.tar.xz
find vidos_release_$NAME -type f -name "rootfs.cpio.lz4" -delete
rm vidos_release_$NAME/vidos_components/vidos_iso9660/video/*
rm -r vidos_release_$NAME/vidos_components/avc_external_lib
