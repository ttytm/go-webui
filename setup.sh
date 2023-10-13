#!/bin/bash

# Download helper for WebUI wrapper users to simplify the setup with the latest
# WebUI-C versions - Go Prototype.
#
# Source: https://github.com/webui-dev/go-webui
# License: MIT
#
# Currently the downloader works for tagged release versions.
# Usage via web: `sh -c "$(curl -fsSL https://raw.githubusercontent.com/webui-dev/go-webui/main/setup.sh)"`
# Local execution e.g., `sh $GOPATH/pkg/mod/github.com/webui-dev/go-webui/v2@v2.4.0/setup.sh` would require
# less logic but the idea is to eventually dynamically determine the latest version to also support versions
# like `@latest` or commit SHAs.

module=github.com/webui-dev/go-webui/v2
version=v2.4.0-beta # TODO: fetch latest version automatically and allow to set version via flag
release_base_url="https://github.com/webui-dev/webui/releases/"

# Determine the release archive for the used platform and architecture.
platform=$(uname -s)
arch=$(uname -m)
case "$platform" in
	Linux)
		case "$arch" in
			x86_64)
				archive="webui-linux-gcc-x64.tar.gz"
				;;
			aarch64|arm64)
				archive="webui-linux-gcc-aarch64.tar.gz"
				;;
			arm*)
				archive="webui-linux-gcc-arm.tar.gz"
				;;
			*)
				echo "The setup script currently does not support $arch architectures on $platform."
				exit 1
				;;
		esac
		;;
	Darwin)
		case "$arch" in
			x86_64)
				archive="webui-macos-clang-x64.tar.gz"
				;;
			arm64)
				archive="webui-macos-clang-arm64.tar.gz"
				;;
			*)
				echo "The setup script currently does not support $arch architectures on $platform."
				exit 1
				;;
		esac
		;;
	*)
		echo "The setup script currently does not support $platform."
		exit 1
		;;
esac

# Parse CLI arguments.
# Defaults.
output="webui"
nightly=true # TODO: After WebUI v2.4.0 release, remove default, to set nightly to false.
local=false
while [[ $# -gt 0 ]]; do
	case "$1" in
		-o|--output)
			output="$2"
			shift
			;;
		--nightly)
			nightly=true
			shift
			;;
		--local)
			local=true
			shift
			;;
		-h|--help)
			echo -e "Usage: setup.sh [flags]\n"
			echo "Flags:"
			echo "  -o, --output: Specify the output directory"
			echo "  --nightly: Download the lastest nightly release"
			echo "  --local: Save the output into the current directory"
			echo "  -h, --help: Display this help message"
			exit 0
			;;
		*)
			echo "Unknown option: $1"
			exit 1
			;;
	esac
done

if [ "$local" = false ]; then
	# Verify GOPATH.
	if [[ -z "${GOPATH}" ]]; then
		echo "Warning: GOPATH is not set."
		go_path="$HOME/go"
		echo -e "Trying to use $go_path instead.\n"
	else
		go_path="$GOPATH"
	fi

	# Verify that module package is installed.
	module_path="$go_path/pkg/mod/$module@$version"
	if [ ! -d "$module_path" ]; then
		echo "Error: \`$module_path\` does not exist in GOPATH."
		echo "Make sure to run \`go get $module@$version\` first."
		exit 1
	fi

	# Make sure the go modules directory is writable for the current user.
	chmod +w "$module_path"
	cd "$module_path"
	# Move back up from major version `v2` path, into "repository root".
	cd ..
fi

# Clean old library files.
rm -rf "${output}/include/webui.h" "${output}/include/webui.hpp" \
	"${output}/debug/libwebui-2-static.a" "${output}/debug/webui-2.dylib" "${output}/debug/webui-2.dll" \
	"${output}/libwebui-2-static.a" "${output}/webui-2.dylib" "${output}/webui-2.dll"

# Download and extract the archive.
echo "Downloading..."
if [ "$nightly" = true ]; then
	url="${release_base_url}download/nightly/${archive}"
else
	url="${release_base_url}latest/download/${archive}"
fi
curl -L "$url" -o "$archive"
echo ""

# Move the extracted files to the output directory.
echo "Extracting..."
archive_dir="${archive%.tar.*}"
tar -xvzf "$archive"
mv "$archive_dir" "$output"
echo ""

# Clean downloaded files and residues.
rm -f "$archive"
rm -rf "$output/$archive_dir"

echo "Done."