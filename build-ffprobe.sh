#!/bin/sh
#download and unpack latest ffmpeg release
wget -c https://ffmpeg.org/releases/ffmpeg-4.3.1.tar.xz &&
tar -xf ffmpeg-4.3.1.tar.xz &&
rm ffmpeg-4.3.1.tar.xz &&
cd ffmpeg-4.3.1 && mkdir build && cd build
#build only ffprobe
../configure --disable-everything --disable-ffmpeg --disable-ffplay --enable-demuxer=matroska,mov --enable-protocol=file --enable-static &&
make -j$(nproc) &&
mv ffprobe ../../ &&
cd  ../../ &&
rm -r ffmpeg-4.3.1

