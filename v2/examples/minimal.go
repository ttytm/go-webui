package main

import "github.com/ttytm/go-webui/v2"

func main() {
	w := webui.NewWindow()
	w.Show("<html>Hello World</html>")
	webui.Wait()
}
