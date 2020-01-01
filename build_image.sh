#!/bin/bash

#
# by TS, Oct 2019
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------

# Outputs CPU architecture string
#
# @param string $1 debian_rootfs|debian_dist
#
# @return int EXITCODE
function _getCpuArch() {
	case "$(uname -m)" in
		x86_64*)
			echo -n "amd64"
			;;
		aarch64*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm64v8"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "arm64"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		armv7*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm32v7"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "armhf"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		*)
			echo "$VAR_MYNAME: Error: Unknown CPU architecture '$(uname -m)'" >/dev/stderr
			return 1
			;;
	esac
	return 0
}

_getCpuArch debian_dist >/dev/null || exit 1

TMP_CPUARCH="$(_getCpuArch debian_dist)"
if [ "$TMP_CPUARCH" != "amd64" ]; then
	echo "$VAR_MYNAME: Error: Unsupported CPU architecture '$TMP_CPUARCH'. Aborting." >/dev/stderr
	echo "$VAR_MYNAME: This script must run on a X64/AMD64 host" >/dev/stderr
	exit 1
fi

# ----------------------------------------------------------

function md5sum_poly() {
	case "$OSTYPE" in
		linux*) md5sum "$1" ;;
		darwin*) md5 -r "$1" | sed -e 's/ /  /' ;;
		*) echo "Error: Unknown OSTYPE '$OSTYPE'" >/dev/stderr; echo -n "$1" ;;
	esac
}

# @param string $1 Filename
# @param bool $2 (Optional) Output error on MD5.err404? Default=true
function _getCommonFile() {
	[ -z "$LVAR_GITHUB_BASE" ] && return 1
	[ -z "$1" ] && return 1
	if [ ! -f "cache/$1" -o ! -f "cache/$1.md5" ]; then
		local TMP_DN="$(dirname "$1")"
		if [ "$TMP_DN" != "." -a "$TMP_DN" != "./" -a "$TMP_DN" != "/" ]; then
			[ ! -d "cache/$TMP_DN" ] && {
				mkdir "cache/$TMP_DN" || return 1
			}
		fi
		if [ ! -f "cache/$1.md5" ]; then
			echo -e "\nDownloading file '$1.md5'...\n"
			curl -L \
					-o cache/$1.md5 \
					${LVAR_GITHUB_BASE}/$1.md5 || return 1
		fi

		local TMP_MD5EXP="$(cat "cache/$1.md5" | cut -f1 -d\ )"
		if [ -z "$TMP_MD5EXP" ]; then
			echo "Could not get expected MD5. Aborting." >/dev/stderr
			rm "cache/$1.md5"
			return 1
		fi
		if [ "$TMP_MD5EXP" = "404:" ]; then
			[ "$2" != "false" ] && echo "Could not download MD5 file (Err 404). Aborting." >/dev/stderr
			rm "cache/$1.md5"
			return 2
		fi

		echo -e "\nDownloading file '$1'...\n"
		curl -L \
				-o cache/$1 \
				${LVAR_GITHUB_BASE}/$1 || return 1
		local TMP_MD5CUR="$(md5sum_poly "cache/$1" | cut -f1 -d\ )"
		if [ "$TMP_MD5EXP" != "$TMP_MD5CUR" ]; then
			echo "Expected MD5 != current MD5. Aborting." >/dev/stderr
			echo "  '$TMP_MD5EXP' != '$TMP_MD5CUR'" >/dev/stderr
			echo "Renaming file to '${1}-'" >/dev/stderr
			mv "cache/$1" "cache/${1}-"
			return 1
		fi
	fi
	return 0
}

# ----------------------------------------------------------

LVAR_GITHUB_BASE="https://raw.githubusercontent.com/tsitle/docker_images_common_files/master"

LVAR_DEBIAN_DIST="$(_getCpuArch debian_dist)"
LVAR_UBUNTU_RELEASE="bionic"
LVAR_UBUNTU_VERSION="18.04"

# ----------------------------------------------------------

LVAR_IMAGE_NAME="mpy-esp32-cc-$LVAR_DEBIAN_DIST"
LVAR_IMAGE_VER="1.11"

LVAR_XTENSA_VER="xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0"

# see MicroPython file /ports/esp32/Makefile for the currently supported ESP-IDF version
LVAR_ESPIDF_GIT_HASH="5c88c5996dbde6208e3bec05abc21ff6cd822d26"

# ----------------------------------------------------------

cd build-ctx || exit 1

[ ! -d cache ] && {
	mkdir cache || exit 1
}

_getCommonFile "xtensa_esp32_toolchain/${LVAR_XTENSA_VER}.tgz" || exit 1

docker build \
		--build-arg CF_CPUARCH_DEB_DIST="$LVAR_DEBIAN_DIST" \
		--build-arg CF_UBUNTU_RELEASE="$LVAR_UBUNTU_RELEASE" \
		--build-arg CF_UBUNTU_VERSION="$LVAR_UBUNTU_VERSION" \
		--build-arg CF_XTENSA_VER="$LVAR_XTENSA_VER" \
		--build-arg CF_ESPIDF_GIT_HASH="$LVAR_ESPIDF_GIT_HASH" \
		--build-arg CF_MPY_VER="v${LVAR_IMAGE_VER}" \
		-t "$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VER" \
		.
