//go:build ignore

package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"runtime"
)

const (
	baseURL  = "https://github.com/webui-dev/webui/releases/"
	platform = runtime.GOOS
	arch     = runtime.GOARCH
)

var (
	output  string
	nightly bool
)

func downloadFile(url, archive string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	file, err := os.Create(archive)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = io.Copy(file, resp.Body)
	if err != nil {
		return err
	}

	return nil
}

func extractArchive(archive, outDir string) error {
	if platform == "windows" {
		cmd := exec.Command("powershell", "-command", fmt.Sprintf("Expand-Archive -LiteralPath %s", archive))
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return err
		}
		err := os.Rename(archive[:len(archive)-len(".zip")], outDir)
		if err != nil {
			return err
		}
	} else {
		cmd := exec.Command("tar", "-xvzf", archive)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return err
		}
		err := os.Rename(archive[:len(archive)-len(".tar.gz")], outDir)
		if err != nil {
			return err
		}
	}

	// Remove downloaded archive.
	if err := os.Remove(archive); err != nil {
		fmt.Printf("Failed to remove archive %s. %v\n", archive, err)
	}

	return nil
}

func parseArgs() {
	flag.StringVar(&output, "output", "webui", "Specify the output path for the downloaded WebUI platform release.")
	flag.BoolVar(&nightly, "nightly", true, "Download the nightly version instead of the latest stable version.")
	flag.Parse()
}

func main() {
	parseArgs()

	// Remove old output dir if it exists.
	os.RemoveAll(output)

	platformArchives := map[string]map[string]string{
		"linux": {
			"amd64":   "webui-linux-gcc-x64.tar.gz",
			"aarch64": "webui-linux-gcc-aarch64.tar.gz",
			"arm64":   "webui-linux-gcc-aarch64.tar.gz",
			"arm":     "webui-linux-gcc-arm.tar.gz",
		},
		"darwin": {
			"amd64": "webui-macos-clang-x64.tar.gz",
			"arm64": "webui-macos-clang-arm64.tar.gz",
		},
		"windows": {
			"amd64": "webui-windows-gcc-x64.zip",
		},
	}

	archive, ok := platformArchives[platform][arch]
	if !ok {
		fmt.Printf("The setup script currently does not support %s %s.\n", platform, arch)
		os.Exit(1)
	}

	fmt.Println("Downloading...")
	url := baseURL + "latest/download/"
	if nightly {
		url = baseURL + "download/nightly/"
	}
	if err := downloadFile(url+archive, archive); err != nil {
		fmt.Printf("Failed downloading archive %s. %v\n", archive, err)
		os.Exit(1)
	}

	fmt.Println("Extracting...")
	if err := extractArchive(archive, output); err != nil {
		fmt.Printf("Failed extracting archive %s. %v\n", archive, err)
		os.Exit(1)
	}

	fmt.Println("Done.")
}
