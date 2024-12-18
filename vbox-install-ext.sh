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
version="0.8"
id="$(id -u 2>/dev/null || echo 1)"
use_force=0
use_debug=0
tmpdir="/tmp/ext.$$"
vboxbin=""

echo_error() { echo "error: $@" >&2; }

usage() {
	cat << EOF
$name: download and install Oracle VirtualBox Extension pack

Usage: $name [OPTIONS] ...

        -h             Show help
        -v             Show version
        -f             Force installation
        -d             Enable debug
                       (default: diabled)

Example:
      $name
    or
      $name -d

EOF
}

vbox_binary() {
	local os="$(uname)"

	case "$os" in
		Darwin)
			vboxbin=/Applications/VirtualBox.app/Contents/MacOS/VBoxManage
		;;
		Linux)
			vboxbin=/usr/bin/VBoxManage
		;;
		*)
			vboxbin=""
		;;
	esac
}

get_vbox_version() {
	local vbox_version="$($vboxbin -v 2>/dev/null | sed 's/[A-Za-z_].*$//g')"
	echo $vbox_version
}

generate_name() {
	local vbox_version="$1"
	local fname=""

	[ -z "$vbox_version" ] && return 1

	fname="Oracle_VirtualBox_Extension_Pack-$vbox_version.vbox-extpack"
	echo $fname
}

generate_url() {
	local vbox_version="$1"
	local url=""
	local fname=""

	[ -z "$vbox_version" ] && return 1

	fname="$(generate_name $vbox_version)"
	url="http://download.virtualbox.org/virtualbox/$vbox_version/$fname"
	echo $url
}

download_ext() {
	local vbox_version="$1"
	local url=""
	local fname=""

	[ -z $vbox_version ] && return 1

	url="$(generate_url $vbox_version)"
	fname="$(generate_name $vbox_version)"

	rc=$(curl -sk $url -o $tmpdir/$fname -w '%{http_code}')
	if [ $rc -ne 200 ]; then
		echo_error "failed to download extension pack."
		return 1
	fi
}

install_ext() {
	local vbox_version="$1"
	local cmd="$2"
	local fname=""

	[ -z $vbox_version ] && return 1

	fname="$(generate_name $vbox_version)"

	echo "y" | $cmd $vboxbin extpack install $tmpdir/$fname >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		if [ $use_force -eq 1 ]; then
			echo "Forcing installation of the extension pack ..."
			echo "y" | $cmd $vboxbin extpack install --replace $tmpdir/$fname >/dev/null 2>&1
			if [ $? -ne 0 ]; then
				return 1
			fi
		else
			echo_error "installation failed, use -f option to force installation."
			return 1
		fi
	fi
}

vbox_binary

if [ ! -x "$vboxbin" ]; then
	echo_error "$vboxbin binary not found, exiting."
	exit 1
fi

while getopts "hvfd" opt; do
	case "$opt" in
		h)
		  usage
		  exit 0
		;;
		v)
		  echo "$name $version (VirtualBox $($vboxbin -v 2>/dev/null))"
		  exit 0
		;;
		f)
		  use_force=1
		;;
		d)
		  use_debug=1
		;;
		*)
		  exit 1
		;;
	esac
done

if [ $use_debug -eq 1 ]; then
	set -x
fi

vbox_version="$(get_vbox_version)"
if [ -z "$vbox_version" ]; then
	echo_error "failed to get VBox version."
	exit 1
fi

cmd=""
if [ $id -ne 0 ]; then
	cmd="sudo"
fi

[ -d "$tmpdir" ] || mkdir -p $tmpdir 2>/dev/null

fname="$(generate_name $vbox_version)"

echo "VirtualBox $vbox_version (extension: $fname)"
echo "Downloading extension pack ..."
if ! download_ext $vbox_version; then
	rm -fr $tmpdir 2>/dev/null
	exit 1
fi

echo "Installing extension pack ..."
if ! install_ext $vbox_version $cmd; then
	rm -fr $tmpdir 2>/dev/null
	exit 1
fi

rm -fr $tmpdir 2>/dev/null
