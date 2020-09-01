#!/bin/bash

# This script will compile and install a static ffmpeg build with support for
# nvenc on ubuntu. See the prefix path and compile options if edits are needed
# to suit your needs.

#Authors:
#   Linux GameCast ( http://linuxgamecast.com/ )
#   Mathieu Comandon <strider@strycore.com>

set -e

ShowUsage() {
    echo "Usage: ./build.sh [--dest /path/to/ffmpeg] [--obs] [--help]"
    echo "Options:"
    echo "  -d/--dest: Where to build ffmpeg (Optional, defaults to ./ffmpeg-nvenc)"
    echo "  -o/--obs:  Build OBS Studio"
    echo "  -h/--help: This help screen"
    exit 0
}

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

params=$(getopt -n $0 -o d:oh --long dest:,obs,help -- "$@")
eval set -- $params
while true ; do
    case "$1" in
        -h|--help) ShowUsage ;;
        -o|--obs) build_obs=1; shift ;;
        -d|--dest) build_dir=$2; shift 2;;
        *) shift; break ;;
    esac
done

cpus=$(getconf _NPROCESSORS_ONLN)
source_dir="${root_dir}/source"
mkdir -p $source_dir
build_dir="${build_dir:-"${root_dir}/ffmpeg-nvenc"}"
mkdir -p $build_dir
bin_dir="${build_dir}/bin"
mkdir -p $bin_dir
inc_dir="${build_dir}/include"
mkdir -p $inc_dir

echo "Building FFmpeg in ${build_dir}"

export PATH=$bin_dir:$PATH

InstallDependencies() {
    echo "Installing dependencies"
    sudo apt-get -y --force-yes install git autoconf automake build-essential libass-dev \
        libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev libtool libva-dev \
        libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
        libqt5x11extras5-dev libxcb-xinerama0-dev libvlc-dev libv4l-dev   \
        pkg-config texi2html zlib1g-dev cmake libcurl4-openssl-dev \
        libjack-jackd2-dev libxcomposite-dev x11proto-composite-dev \
        libx264-dev libgl1-mesa-dev libglu1-mesa-dev libasound2-dev \
        libpulse-dev libx11-dev libxext-dev libxfixes-dev \
        libxi-dev qt5-default qttools5-dev qt5-qmake qtbase5-dev
}

InstallNvidiaSDK() {
    echo "Installing the NVidia cuda toolkit"
    sudo apt install -y nvidia-cuda-toolkit
}

BuildNasm() {
    echo "Compiling nasm"
    cd $source_dir
    nasm_version="2.15.05"
    nasm_basename="nasm-${nasm_version}"
    if [ ! -f ${nasm_basename}.tar.bz2 ]; then
        wget -4 http://www.nasm.us/pub/nasm/releasebuilds/${nasm_version}/nasm-${nasm_version}.tar.bz2
    fi
    tar xjf "${nasm_basename}.tar.bz2"
    mkdir -p build-$nasm_basename && cd build-$nasm_basename
    ../$nasm_basename/configure --prefix="${build_dir}"
    make -j${cpus}
    make install
}

BuildYasm() {
    echo "Compiling yasm"
    cd $source_dir
    yasm_version="1.3.0"
    yasm_basename="yasm-${yasm_version}"
    if [ ! -f ${yasm_basename}.tar.gz ]; then
        wget -4 http://www.tortall.net/projects/yasm/releases/${yasm_basename}.tar.gz
    fi
    tar xzf "${yasm_basename}.tar.gz"
    mkdir -p build-$yasm_basename && cd build-$yasm_basename
    ../$yasm_basename/configure --prefix="${build_dir}"
    make -j${cpus}
    make install
}

BuildX264() {
    echo "Compiling libx264"
    cd $source_dir
    if [ ! -f "x264-snapshot-20191217-2245-stable.tar.bz2" ]; then
        wget -4 http://download.videolan.org/pub/x264/snapshots/x264-snapshot-20191217-2245-stable.tar.bz2
    fi
    tar xjf x264-snapshot-20191217-2245-stable.tar.bz2
    mkdir -p build-x264 && cd build-x264
    ../x264-snapshot-20191217-2245-stable/configure --prefix="$build_dir" --enable-static --enable-pic
    make -j${cpus}
    make install
}

BuildFdkAac() {
    echo "Compiling libfdk-aac"
    cd $source_dir
    if [ ! -f "fdk-aac-2.0.1.tar.gz" ]; then
        wget -4 -O fdk-aac-2.0.1.tar.gz https://github.com/mstorsjo/fdk-aac/archive/v2.0.1.tar.gz
    fi
    tar xzf fdk-aac-2.0.1.tar.gz
    cd fdk-aac-2.0.1
    autoreconf -fiv
    cd ..
    mkdir -p build-fdk-aac-2.0.1 && cd build-fdk-aac-2.0.1
    ../fdk-aac-2.0.1/configure --prefix="$build_dir" --disable-shared
    make -j${cpus}
    make install
}

BuildLame() {
    echo "Compiling libmp3lame"
    cd $source_dir
    lame_version="3.100"
    lame_basename="lame-${lame_version}"
    if [ ! -f ${lame_basename}.tar.gz ]; then
        wget -4 "http://downloads.sourceforge.net/project/lame/lame/3.100/${lame_basename}.tar.gz"
    fi
    tar xzf "${lame_basename}.tar.gz"
    mkdir build-$lame_basename && cd build-$lame_basename
    ../$lame_basename/configure --prefix="$build_dir" --enable-nasm --disable-shared
    make -j${cpus}
    make install
}

BuildOpus() {
    echo "Compiling libopus"
    cd $source_dir
    opus_version="1.3.1"
    opus_basename="opus-${opus_version}"
    if [ ! -f ${opus_basename}.tar.gz ]; then
        wget -4 -O "${opus_basename}.tar.gz" "https://github.com/xiph/opus/archive/v${opus_version}.tar.gz"
    fi
    tar xzf "${opus_basename}.tar.gz"
    cd $opus_basename
    autoreconf -fiv
    cd ..
    mkdir -p build-$opus_basename && cd build-$opus_basename
    ../$opus_basename/configure --prefix="$build_dir" --disable-shared --enable-static
    make -j${cpus}
    make install
}

BuildVpx() {
    echo "Compiling libvpx"
    cd $source_dir
    vpx_version="1.9.0"
    vpx_basename="libvpx-${vpx_version}"
    if [ ! -f ${vpx_basename}.tar.gz ]; then
        wget -4 -O "${vpx_basename}.tar.gz" "https://github.com/webmproject/libvpx/archive/v${vpx_version}.tar.gz"
    fi
    tar xzf "${vpx_basename}.tar.gz"
    mkdir -p build-$vpx_basename && cd build-$vpx_basename
    ../$vpx_basename/configure --prefix="$build_dir" --disable-examples --disable-shared --enable-static --enable-pic
    make -j${cpus}
    make install
}

BuildFFmpeg() {
    echo "Compiling nv-codec-headers"
    if [ ! -d  nv-codec-headers ]; then
        git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
    fi
    cd nv-codec-headers
    make
    sudo make install
    cd ..

    echo "Compiling ffmpeg"
    cd $source_dir
    ffmpeg_version="4.3.1"
    if [ ! -f  ffmpeg-${ffmpeg_version}.tar.bz2 ]; then
        wget -4 http://ffmpeg.org/releases/ffmpeg-${ffmpeg_version}.tar.bz2
    fi
    tar xjf ffmpeg-${ffmpeg_version}.tar.bz2
    mkdir -p build-ffmpeg-${ffmpeg_version} && cd build-ffmpeg-${ffmpeg_version}
    PKG_CONFIG_PATH="${build_dir}/lib/pkgconfig" ../ffmpeg-${ffmpeg_version}/configure \
        --prefix="$build_dir" \
        --extra-cflags="-fPIC -m64 -I${inc_dir} -I/usr/local/cuda/include" \
        --extra-ldflags="-L${build_dir}/lib -L/usr/local/cuda/lib64" \
        --enable-gpl \
        --enable-libass \
        --enable-libfdk-aac \
        --enable-libfreetype \
        --enable-libmp3lame \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libx264 \
        --enable-nonfree \
        --enable-nvenc \
	    --enable-cuda-nvcc \
        --enable-libnpp
    make -j${cpus}
    make install
}

BuildOBS() {
    cd $source_dir
    export FFmpegPath="${source_dir}/ffmpeg"
    if [ -d obs-studio ]; then
        cd obs-studio
        git pull
	make -j${cpus}
    else
        git clone --recursive https://github.com/yachtcloud/obs-studio.git
	cd obs-studio/plugins
	git clone --recursive https://github.com/yachtcloud/obs-websocket.git
        cd ..
	cmake -DLIBOBS_INCLUDE_DIR=${source_dir}/obs-studio/libobs .
        make -j${cpus}
	echo "add_subdirectory(obs-websocket)" >> plugins/CMakeLists.txt
        cmake -DLIBOBS_INCLUDE_DIR=${source_dir}/obs-studio/libobs -DLIBOBS_LIB=${source_dir}/obs-studio/libobs/libobs.so .
    fi
    make install
}

CleanAll() {
    rm -rf $source_dir
}

MakeScripts() {
    cd $build_dir
    mkdir -p scripts
    cd scripts
    cat <<EOF > ffmpeg.sh
#!/bin/bash
export LD_LIBRARY_PATH="${build_dir}/lib":\$LD_LIBRARY_PATH
cd "${build_dir}/bin"
./ffmpeg "\$@"
EOF
    chmod +x ffmpeg.sh

    if [ "$build_obs" ]; then
        cat <<EOF > obs.sh
#!/bin/bash
export LD_LIBRARY_PATH="${build_dir}/lib":\$LD_LIBRARY_PATH
cd "${build_dir}/bin"
./obs "\$@"
EOF
        chmod +x obs.sh
    fi
}

MakeLauncherOBS() {
    cat <<EOF > ~/.local/share/applications/obs.desktop
[Desktop Entry]
Version=1.0
Name=OBS Studio
Comment=OBS Studio (NVenc enabled)
Categories=Video;
Exec=${build_dir}/scripts/obs.sh %U
Icon=obs
Terminal=false
Type=Application
EOF
    mkdir -p ~/.icons
    cp ${root_dir}/media/obs.png ~/.icons
    gtk-update-icon-cache -t ~/.icons
}

if [ $1 ]; then
    $1
else
    InstallDependencies
    InstallNvidiaSDK
    BuildNasm
    BuildYasm
    BuildX264
    BuildFdkAac
    BuildLame
    BuildOpus
    BuildVpx
    BuildFFmpeg
    if [ "$build_obs" ]; then
        BuildOBS
        #MakeLauncherOBS
    fi
    #MakeScripts
fi
