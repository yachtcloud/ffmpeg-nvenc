# FFmpeg (with nvenc | NVidia hardware accelaration support) and OBS-Studio

This script will compile FFmpeg with Nvidia NVENC support enabled.
It can also build OBS Studio using that FFmpeg build thus providing NVENC for OBS.

## System requirements

You need either Ubutnu 18.04 or Ubuntu 20.04 in order to compile.
Following command should be executed when compiling for the first time:

```
sudo apt-get -y --force-yes install git autoconf automake build-essential libass-dev \
        libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev libtool libva-dev \
        libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
        libqt5x11extras5-dev libxcb-xinerama0-dev libvlc-dev libv4l-dev   \
        pkg-config texi2html zlib1g-dev cmake libcurl4-openssl-dev \
        libjack-jackd2-dev libxcomposite-dev x11proto-composite-dev \
        libx264-dev libgl1-mesa-dev libglu1-mesa-dev libasound2-dev \
        libpulse-dev libx11-dev libxext-dev libxfixes-dev \
        libxi-dev qt5-default qttools5-dev qt5-qmake qtbase5-dev
```

If not installed already you need the NVidia linux driver >= 450.51, as well
as the latest cuda package:

Ubuntu 18.04:

```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.0.3/local_installers/cuda-repo-ubuntu1804-11-0-local_11.0.3-450.51.06-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1804-11-0-local_11.0.3-450.51.06-1_amd64.deb
sudo apt-key add /var/cuda-repo-ubuntu1804-11-0-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda
```


Ubuntu 20.04:

```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.0.3/local_installers/cuda-repo-ubuntu2004-11-0-local_11.0.3-450.51.06-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-0-local_11.0.3-450.51.06-1_amd64.deb
sudo apt-key add /var/cuda-repo-ubuntu2004-11-0-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda
```


## Usage

Clone the repo then use the `build.sh` script to compile the binaries

```
git clone https://github.com/yachtcloud/ffmpeg-nvenc.git
cd ffmpeg-nvenc
sudo ./build.sh --dest /usr/local -o
```

Use `./build.sh -h` to check for further usage.


## Development

If you need to make changes to this repository, it's recommended
to remove the buildsteps you don't need and omit the `--dest` parameter.
You might not want to pollute your /usr/local directory with dev versions
of libraries.
By default the script will create a builddir in your home directory.

