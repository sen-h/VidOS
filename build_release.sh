#!/bin/bash
BUILDROOT_LATEST="buildroot-2021.08"
SUPPORTED_FORMATS=("av1" "avc" "webm")
SUPPORTED_STYLES=("disk" "ram" "hybrid")
mkdir -p vidos_release/vidos_components

cp -r $BUILDROOT_LATEST/${SUPPORTED_FORMATS[0]}/images/vidos_release/${SUPPORTED_FORMATS[0]}"_build"/. vidos_release/vidos_components

for FORMAT in "${SUPPORTED_FORMATS[@]}"; do
	echo $BUILDROOT_LATEST/$FORMAT/images/vidos_release/$FORMAT"_build"/$FORMAT"_kernel"
	cp -r $BUILDROOT_LATEST/$FORMAT/images/vidos_release/$FORMAT"_build"/$FORMAT"_kernel" vidos_release/vidos_components

done

cp vidos_av1/vobu.sh vidos_release/
cp README.md vidos_release/
find vidos_release -type f -name "rootfs.cpio.lz4" -delete
rm vidos_release/vidos_components/vidos_iso9660/video/*
