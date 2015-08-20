#!/bin/sh -e
#
# Copyright (C) 2015 Robert Milasan <rmilasan@suse.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

name="$(basename $0)"
version="0.3"
id="$(id -u 2>/dev/null || echo 1)"
debug=0
tmpdir="/tmp/ext.$$"

usage() {
	cat << EOF
$name: download and install Oracle VirtualBox Extension pack

Usage: $name [OPTIONS] ...

        -h             Show help
        -v             Show version
        -d             Enable debug
                       (default: diabled)

Example:
      $name
    or
      $name -d

EOF
}

get_vbox_version() {
	local version="$(VBoxManage -v 2>/dev/null | grep '^[0-9].*' | sed '/^[0-9].*/ s/r.*//g')"
	echo $version
}

generate_url() {
	local version="$1"
	local url=""

	[ -z "$version" ] && return 1

	url="http://download.virtualbox.org/virtualbox/$version/Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack"
	echo $url
}

download_ext() {
	local version="$1"
	local url=""
	local fname=""

	[ -z $version ] && return 1

	url="$(generate_url $version)"
	fname="Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack"

	/usr/bin/wget $url -O $tmpdir/$fname >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 1
	fi
}

install_ext() {
	local version="$1"
	local cmd="$2"
	local fname=""

	[ -z $version ] && return 1

	fname="Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack"

	$cmd /usr/bin/VBoxManage extpack install $tmpdir/$fname >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Installation failed, trying to replace extension package..."
		$cmd /usr/bin/VBoxManage extpack install --replace $tmpdir/$fname >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			return 1
		fi
	fi
}

if [ ! -x /usr/bin/VBoxManage ]; then
	echo "$name: /usr/bin/VBoxManage binary not found, exiting."
	exit 1
fi

while getopts "hvd" opt; do
	case "$opt" in
		h)
		  usage
		  exit 0
		;;
		v)
		  echo "$name $version (VirtualBox $(VBoxManage -v 2>/dev/null | grep '^[0-9].*'))"
		  exit 0
		;;
		d)
		  debug=1
		;;
		*)
		  exit 1
		;;
	esac
done

if [ $debug -eq 1 ]; then
	set -x
fi

vbox_version="$(get_vbox_version)"
if [ -z "$vbox_version" ]; then
	echo "$name: failed to get VBox version." >&2
	exit 1
fi

cmd=""
if [ $id -ne 0 ]; then
	cmd="sudo"
fi

[ -d "$tmpdir" ] || mkdir -p $tmpdir 2>/dev/null

echo "Downloading extension pack..."
if ! download_ext $vbox_version; then
	echo "$name: failed to download extension pack" >&2
	rm -fr $tmpdir 2>/dev/null
	exit 1
fi

echo "Installing extension pack..."
if ! install_ext $vbox_version $cmd; then
	echo "$name: failed to install extension pack (2 tries)" >&2
	rm -fr $tmpdir 2>/dev/null
	exit 1
fi

rm -fr $tmpdir 2>/dev/null
