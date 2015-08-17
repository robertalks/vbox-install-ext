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

function usage()
{
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

function get_vbox_version()
{
	local version="$(VBoxManage -v 2>/dev/null | grep '^[0-9].*' | sed '/^[0-9].*/ s/r.*//g')"
	echo $version
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

echo "Downloading extension pack... (Oracle_VM_VirtualBox_Extension_Pack-$vbox_version.vbox-extpack)"
/usr/bin/wget http://download.virtualbox.org/virtualbox/$vbox_version/Oracle_VM_VirtualBox_Extension_Pack-$vbox_version.vbox-extpack \
   -O $tmpdir/Oracle_VM_VirtualBox_Extension_Pack-$vbox_version.vbox-extpack 2>/dev/null || \
   { echo "$name: failed to download extension pack" >&2; rm -fr $tmpdir 2>/dev/null; exit 1; }

echo "Installing extension pack..."
$cmd /usr/bin/VBoxManage extpack install \
   $tmpdir/Oracle_VM_VirtualBox_Extension_Pack-$vbox_version.vbox-extpack 2>/dev/null || \
   { echo "$name: failed to install extension pack" >&2; rm -fr $tmpdir 2>/dev/null; exit 1; }

rm -fr $tmpdir 2>/dev/null
