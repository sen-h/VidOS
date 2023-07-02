#!/bin/bash
BUILDROOT_LATEST="buildroot-2023.02.2"
SUPPORTED_FORMATS=("av1" "avc" "webm")
SUPPORTED_STYLES=("disk" "ram" "hybrid")
mkdir -p vidos_release_$1/vidos_components

cp -r $BUILDROOT_LATEST/${SUPPORTED_FORMATS[0]}/images/vidos_release/${SUPPORTED_FORMATS[0]}"_build"/. vidos_release_$1/vidos_components

for FORMAT in "${SUPPORTED_FORMATS[@]}"; do
	echo $BUILDROOT_LATEST/$FORMAT/images/vidos_release/$FORMAT"_build"/$FORMAT"_kernel"
	cp -r $BUILDROOT_LATEST/$FORMAT/images/vidos_release/$FORMAT"_build"/$FORMAT"_kernel" vidos_release_$1/vidos_components

done

cp vidos_av1/vobu.sh vidos_release_$1/
cp README.md vidos_release_$1/
find vidos_release_$1 -type f -name "rootfs.cpio.lz4" -delete
rm vidos_release_$1/vidos_components/vidos_iso9660/video/*
