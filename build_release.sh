#!/bin/bash
BUILDROOT_LATEST="buildroot-2021.08"
SUPPORTED_CODECS=("av1" "avc" "webm")

echo ${SUPPORTED_CODECS[0]}

cp -r $BUILDROOT_LATEST/${SUPPORTED_CODECS[0]}/images/vidos_release/${SUPPORTED_CODECS[0]}"_build" vidos_full_release


for CODEC in "${SUPPORTED_CODECS[@]}"; do
	echo $BUILDROOT_LATEST/$CODEC/images/vidos_release/$CODEC"_build"/$CODEC"_kernel"
	cp -r $BUILDROOT_LATEST/$CODEC/images/vidos_release/$CODEC"_build"/$CODEC"_kernel" vidos_full_release
done
