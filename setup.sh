#!/bin/bash

# Download helper for WebUI wrapper users to simplify the setup with the latest
# WebUI-C versions - Go Prototype.
#
# Source: https://github.com/webui-dev/webui-release-downloader
# License: MIT

# Currently the downloader works for tagged release versions.
# E.g., @latest or commit SHAs would not work.
module=github.com/ttytm/go-webui@v2.0.0
release_base_url="https://github.com/webui-dev/webui/releases/"

platform=$(uname -s)
arch=$(uname -m)

# CLI args defaults.
output="webui"
# Set nightly to false to use stable as default after WebUI v2.4.0 was released.
nightly=true

# Verify GOPATH.
if [[ -z "${GOPATH}" ]]; then
	echo "Warning: GOPATH is not set."
	go_path="$HOME/go"
	echo -e "Trying to use $go_path instead.\n"
else
	go_path="$GOPATH"
fi

# Verify that module package is installed.
module_path="$go_path/pkg/mod/$module"
if [ ! -d "$module_path" ]; then
	echo "Error: \`$module_path\` does not exist in GOPATH."
	echo "Make sure to run \`go get $module\` first."
	exit 1
fi

# Parse arguments.
while [[ $# -gt 0 ]]; do
	case "$1" in
		-o|--output)
			output="$2"
			shift 2
			;;
		--nightly)
			nightly=true
			shift
			;;
		*)
			echo "Unknown option: $1"
			exit 1
			;;
	esac
done

# Define base URL and archives for platform and architecture.
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

# Clean old library files.
rm -rf "${output}/include/webui.h" "${output}/include/webui.hpp" \
	"${output}/debug/libwebui-2-static.a" "${output}/debug/webui-2.dylib" "${output}/debug/webui-2.dll" \
	"${output}/libwebui-2-static.a" "${output}/webui-2.dylib" "${output}/webui-2.dll"

# Make sure the go moudles directory is writable for the current user.
chmod +w "$module_path"

cd "$module_path"

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
