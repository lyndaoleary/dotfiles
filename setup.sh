#!/bin/bash
set -e

USERNAME=$(find /home/* -maxdepth 0 -printf "%f" -type d)

setup_sudo() {
	gpasswd -a "$USERNAME" sudo

	gpasswd -a "$USERNAME" systemd-journal
	gpasswd -a "$USERNAME" systemd-network

	echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/tmp/sudo_$USERNAME"
	echo "${USERNAME} ALL=NOPASSWD: /bin/mount, /sbin/mount.nfs, /bin/umount, /sbin/umount.nfs, /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery" >> "/tmp/sudo_$USERNAME"

	visudo -c -f "/tmp/sudo_$USERNAME"
	cp "/tmp/sudo_$USERNAME" /etc/sudoers.d/
}

setup_dotfiles() {
	ln -snf "$HOME/dotfiles/shell/bashrc" "$HOME/.bashrc"
	ln -snf "$HOME/dotfiles/shell/bash_profile" "$HOME/.bash_profile"
	ln -snf "$HOME/dotfiles/shell/inputrc" "$HOME/.inputrc"
	ln -snf "$HOME/dotfiles/Xdefaults" "$HOME/.Xdefaults"
	ln -snf "$HOME/dotfiles/Xresources" "$HOME/.Xresources"
	ln -snf "$HOME/dotfiles/xsessionrc" "$HOME/.xsessionrc"
	ln -snf "$HOME/dotfiles/usr/local/bin/light" /usr/local/bin/light
	ln -snf "$HOME/dotfiles/etc/modprobe.d/intel.conf" /etc/modprobe.d/intel.conf
}

setup_config() {
	for f in config/*; do
		ln -sfn $HOME/dotfiles/$f $HOME/.$f
	done
}

setup_sources() {
	# Chrome
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
	echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

	# Docker
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list

	# Neovim
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 9DBB0BE9366964F134855E2255F96FCF8231B6DD
	echo "deb http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu xenial main" > /etc/apt/sources.list.d/neovim.list

	# Syncthing
	curl -s https://syncthing.net/release-key.txt | apt-key add -
	echo "deb http://apt.syncthing.net/ syncthing release" | tee /etc/apt/sources.list.d/syncthing.list

	# VirtualBox
	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
	echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" > /etc/apt/sources.list.d/virtualbox.list

	# Neovim
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 9DBB0BE9366964F134855E2255F96FCF8231B6DD
	echo "deb http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu xenial main" > /etc/apt/sources.list.d/neovim.list
}

setup_base() {
	apt-get update

	apt-get upgrade -y

	apt-get install -y \
		ansible \
		alsa-utils \
		atom \
		rxvt-unicode-256color \
		network-manager \
		openvpn \
		google-chrome-stable \
		libappindicator3-1 \
		libappindicator1 \
		keepassx \
		tlp \
		virtualbox-5.0

	apt-get autoremove
	apt-get autoclean
	apt-get clean
}

setup_neovim() {
	apt-get install -y \
		neovim \
		python-dev \
		python-pip \
		python3-dev \
		python3-pip

	update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
	update-alternatives --config vi
	update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
	update-alternatives --config vim
	update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
	update-alternatives --config editor

	pip install neovim
}

setup_syncthing() {
	apt-get install -y \
		syncthing

	cp -f "$HOME/dotfiles/etc/systemd/system/syncthing@.service" /etc/systemd/system/syncthing@.service

	systemctl daemon-reload
	systemctl enable syncthing@${USERNAME}
}

setup_docker() {
	groupadd -f docker
	gpasswd -a "$USERNAME" docker

	apt-get install -y \
		docker-engine \
		docker-compose
}

setup_wm() {
	apt-get install -y --no-install-recommends \
		i3 \
		i3lock \
		i3status \
		scrot \
		rofi \
		slim \
		xorg \
		network-manager-gnome \
		network-manager-openvpn-gnome \
		gnome-keyring \
		xserver-xorg
}

main() {
	setup_sudo
	setup_dotfiles
	setup_config
	setup_sources
	setup_base
	setup_syncthing
	setup_neovim
	setup_docker
	setup_wm

	chown -R "$USERNAME":"$USERNAME" ~
}

main "$@"
