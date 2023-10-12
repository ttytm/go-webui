# Download helper for WebUI wrapper users to simplify the setup with the latest
# WebUI-C versions - Go Prototype.
#
# Source: https://github.com/webui-dev/webui-release-downloader
# License: MIT

# Currently the downloader works for tagged release versions.
# E.g., @latest or commit SHAs would not work.
$module = "github.com/ttytm/go-webui@v2.0.0"
$base_url = "https://github.com/webui-dev/webui/releases/"

# Get the platform and architecture
$platform = [System.Environment]::OSVersion.Platform
$architecture = [System.Environment]::Is64BitOperatingSystem

# CLI args defaults.
$output = "webui"
# Set nightly to false to use stable as default after WebUI v2.4.0 was released.
$nightly = $true

# Verify GOPATH.
if ([string]::IsNullOrEmpty($Env:GOPATH)) {
	Write-Host "Warning: GOPATH is not set."
	$go_path = "$Env:USERPROFILE\go"
	Write-Host "Trying to use $go_path instead."
} else {
	$go_path = $Env:GOPATH
}

# Verify that module package is installed.
$module_path = Join-Path $go_path "pkg\mod\$module"
if (-not (Test-Path $module_path -PathType Container)) {
	Write-Host "Error: '$module_path' does not exist in GOPATH."
	Write-Host "Make sure to run 'go get $module' first."
	exit 1
}

# Parse arguments.
while ($args.Count -gt 0) {
	switch -wildcard ($args[0]) {
		"--output" {
			$output = $args[1]
			$args = $args[2..($args.Count - 1)]
		}
		"--nightly" {
			$nightly = $true
			$args = $args[1..($args.Count - 1)]
		}
		default {
			Write-Host "Unknown option: $($args[0])"
			exit 1
		}
	}
}

# Define base URL and archives for different platforms.
switch -wildcard ($platform) {
	"Win32NT" {
		switch -wildcard ($architecture) {
			"True" {
				$archive = "webui-windows-gcc-x64.zip"
			}
			default {
				Write-Host "The setup script currently does not support $arch architectures on Windows."
				exit 1
			}
		}
	}
	default {
		Write-Host "The setup script currently does not support $platform."
		exit 1
	}
}

$archive_dir = $archive.Replace(".zip", "")

$current_location = Get-Location
Set-Location $module_path

# Clean old library files in case they exist.
Remove-Item -Path $archive -ErrorAction SilentlyContinue
Remove-Item -Path $archive_dir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $output -Recurse -Force -ErrorAction SilentlyContinue

# Download and extract the archive.
Write-Host "Downloading..."
if ($nightly -eq $true) {
	$url = "${base_url}download/nightly/$archive"
} else {
	$url = "${base_url}latest/download/$archive"
}
Invoke-WebRequest -Uri $url -OutFile $archive
Write-Host ""

# Move the extracted files to the output directory.
Write-Host "Extracting..."
Expand-Archive -LiteralPath $archive
Move-Item -Path $archive_dir\$archive_dir -Destination $output
Write-Host ""

# Clean downloaded files and residues.
Remove-Item -Path $archive -Force
Remove-Item -Path $archive_dir -Recurse -Force

Write-Host "Done."
Set-Location $current_location
