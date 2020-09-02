#!/bin/bash
sudo apt-get -y --force-yes install git autoconf automake build-essential libass-dev \
        libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev libtool libva-dev \
        libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
        libqt5x11extras5-dev libxcb-xinerama0-dev libvlc-dev libv4l-dev   \
        pkg-config texi2html zlib1g-dev cmake libcurl4-openssl-dev \
        libjack-jackd2-dev libxcomposite-dev x11proto-composite-dev \
        libx264-dev libgl1-mesa-dev libglu1-mesa-dev libasound2-dev \
        libpulse-dev libx11-dev libxext-dev libxfixes-dev \
        libxi-dev qt5-default qttools5-dev qt5-qmake qtbase5-dev \
	libx11-xcb-dev libqt5svg5-dev libxcb-randr0-dev


osver=$(lsb_release -sr)

if [ $osver == "18.04" ]; then
    echo "Get nvidia cuda for Ubuntu 18.04"
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
    sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/11.0.3/local_installers/cuda-repo-ubuntu1804-11-0-local_11.0.3-450.51.06-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu1804-11-0-local_11.0.3-450.51.06-1_amd64.deb
    sudo apt-key add /var/cuda-repo-ubuntu1804-11-0-local/7fa2af80.pub
    sudo apt-get update
    sudo apt-get -y install cuda

elif [ $osver == "20.04" ]; then
    echo "Get nvidia cuda for Ubuntu 20.04"
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
    sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/11.0.3/local_installers/cuda-repo-ubuntu2004-11-0-local_11.0.3-450.51.06-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu2004-11-0-local_11.0.3-450.51.06-1_amd64.deb
    sudo apt-key add /var/cuda-repo-ubuntu2004-11-0-local/7fa2af80.pub
    sudo apt-get update
    sudo apt-get -y install cuda
else
    echo "Unsupported operating system."
    echo "You need to install cuda manually!"
fi
