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
	ln -snf "$HOME/dotfiles/Xdefaults" "$HOME/.Xdefaults"
	ln -snf "$HOME/dotfiles/Xresources" "$HOME/.Xresources"
	ln -snf "$HOME/dotfiles/xsessionrc" "$HOME/.xsessionrc"
}

setup_config() {
	for f in config/*; do
		echo "ln -sfn $HOME/dotfiles/$f $HOME/.$f"
	done
}

setup_sources() {
	# Chrome
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
	echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

	# Atom
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 7B2C3B0889BF5709A105D03AC2518248EEA14886
	echo "deb http://ppa.launchpad.net/webupd8team/atom/ubuntu xenial main" > /etc/apt/sources.list.d/atom.list

	# Docker
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list

	# Ansible
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367
	echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu xenial main" > /etc/apt/sources.list.d/ansible.list

}

setup_base() {
	apt-get update

	apt-get upgrade -y

	apt-get install -y \
		ansible \
		atom \
		rxvt-unicode-256color \
		network-manager \
		google-chrome-stable \
		libappindicator3-1 \
		libappindicator1

	apt-get autoremove
	apt-get autoclean
	apt-get clean
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
		rofi \
		slim \
		xorg \
		network-manager-gnome \
		gnome-keyring \
		xserver-xorg
}

main() {
	setup_sudo
	setup_dotfiles
	setup_config
	setup_sources
	setup_base
	setup_docker
	setup_wm

	chown -R "$USERNAME":"$USERNAME" ~
}

main "$@"

