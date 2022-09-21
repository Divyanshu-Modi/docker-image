#!/bin/bash

# Uncomment community [multilib] repository
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Refresh mirror list
pacman-key --init
pacman -Syu --noconfirm reflector rsync curl git base-devel 2>&1 | grep -v "warning: could not get file information"
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Download fresh package databases from the servers
pacman -Syy

# Create a non-root user for yay to install packages from AUR
useradd -m -G wheel -s /bin/bash auruser
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# AUR Packages
sudo -u auruser yay -S --noconfirm alhp-keyring alhp-mirrorlist

# Enable ALHP repos
sed -i 's/#Server/Server/g' /etc/pacman.d/alhp-mirrorlist
sed -e '/Worldwide/,+1 s/^/#/' /etc/pacman.d/alhp-mirrorlist
sed -i "/\[core-x86-64-v3\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i "/\[extra-x86-64-v3\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i "/\[community-x86-64-v3\]/,/Include/"'s/^#//' /etc/pacman.conf

# Update
pacman -Syyu --noconfirm 2>&1 | grep -v "warning: could not get file information"

# Install Development Packages
pacman -Sy --noconfirm \
	git \
	curl \
	wget \
	base-devel \
	bc \
	bison \
	clang \
	cpio \
	cmake \
	flex \
	gcc \
	gcc-libs \
	github-cli \
	jemalloc \
	jdk-openjdk \
	libelf \
	lld \
	lz4 \
	llvm \
	multilib-devel \
	openssl \
	patchelf \
	perf \
	perl \
	python3 \
	python-pip \
	unzip \
	zip \
	zstd

# Symlinks for python an
ln -sf /usr/bin/pip3.10 /usr/bin/pip3
ln -sf /usr/bin/pip3.10 /usr/bin/pip
ln -sf /usr/bin/python3.10 /usr/bin/python3
ln -sf /usr/bin/python3.10 /usr/bin/python

# Install Some pip packages
pip3 install telegram-send

get() {
    curl -LSs  "https://codeload.github.com/$1/zip/$2" -o "$3".zip
    unzip "$3".zip -d. && rm "$3".zip && mv -v "${1##*/}-$2" "/usr/${3}"
    find "/usr/${3}" -exec chmod +x {} \;
}

get mvaisakh/gcc-arm64 gcc-master gcc64
get mvaisakh/gcc-arm gcc-master gcc32

# Latest clang will be used
mkdir -p /usr/clang
r_tag=$(curl --silent "https://raw.githubusercontent.com/Neutron-Toolchains/clang-build-catalogue/main/latest.txt" | grep -A1 tag | tail -n1)
wget --quiet --show-progress "https://github.com/Neutron-Toolchains/clang-build-catalogue/releases/download/$r_tag/neutron-clang-$r_tag.tar.zst"
tar -I zstd -xf *.tar.zst --directory=/usr/clang
find "/usr/clang" -exec chmod +x {} \;

# Fix for docker's unusal locale config
sed -i s/"#en_US.UTF-8 UTF-8"/"en_US.UTF-8 UTF-8"/g /etc/locale.gen
locale-gen

echo 'package installtion completed'
