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
id="$(id -u 2>/dev/null || echo 1)"
tmpdir="/tmp/ext.$$"

function usage()
{
	cat << EOF
$name: download and install Oracle VBox Extension pack

Usage: $name [OPTIONS] ...

        -h             Show help
        -d             Enable debug
                       (default: diabled)

Example:
     $name -d

EOF
}

function vbox_version()
{
	local version

	if [ -x "$(which VBoxManage)" ]; then
		version="$(VBoxManage -v 2>/dev/null | grep '^[0-9].*' | sed '/^[0-9].*/ s/r.*//g')"
	fi

	echo $version
}

while getopts "hv:d" opt; do
	case "$opt" in
		h)
		  usage
		  exit 0
		;;
		d)
		  set -x
		;;
		*)
		  exit 1
		;;
	esac
done

version="$(vbox_version)"
cmd=""

if [ -z "$version" ]; then
	echo "$0: possibily VirtualBox is not installed." >&2
	exit 1
fi

if [ $id -ne 0 ]; then
	cmd="sudo"
fi

[ -d "$tmpdir" ] || mkdir -p $tmpdir 2>/dev/null

echo "Downloading extension pack... (Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack)"
/usr/bin/wget http://download.virtualbox.org/virtualbox/$version/Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack \
   -O $tmpdir/Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack 2>/dev/null || \
   { echo "$0: failed to download extension pack" >&2; rm -fr $tmpdir 2>/dev/null; exit 1; }

echo "Installing extension pack..."
$cmd /usr/bin/VBoxManage extpack install \
   $tmpdir/Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack 2>/dev/null || \
   { echo "$0: failed to install extension pack" >&2; rm -fr $tmpdir 2>/dev/null; exit 1; }

rm -fr $tmpdir 2>/dev/null
