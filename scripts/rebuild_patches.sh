#!/bin/bash
BUILDROOT_LATEST="buildroot-2023.05.1"
SUPPORTED_FORMATS=("av1" "avc" "webm" "efi")
SUPPORTED_STYLES=("disk" "ram" "hybrid")

#this script generates new patches for the vidos format configs
#if you have made a change to a particular format, run this script so it gets preserved :>)

pushd $BUILDROOT_LATEST

for FORMAT in "$@"; do
#first savedefconfigs are created for each format
	make O=$FORMAT -j$(nproc) savedefconfig BR2_DEFCONFIG=../configs/"vidos_"$FORMAT"_config"
	echo "vidos_"$FORMAT"_config"
done

popd
pushd configs

for FORMAT in "$@"; do
#then those savedefconfigs are compared against the base config to create patches
	diff -U0 vidos_base_config  "vidos_"$FORMAT"_config" | cut -f1 > ../patches/vidos_$FORMAT.patch
	echo "vidos_$FORMAT.patch"
done
