package gui

import (
	"bytes"
	"fmt"
	"io"
	"io/fs"
	"path"
	"strings"
	"time"
)

// dynamicFrontendFS serves the frontend directory with dynamic component assembling for index.html.
// This allows developers to edit clean, modular component HTML files in frontend/components/
// while serving a seamless single-page app without any build-step or WebKit DOM delay.
type dynamicFrontendFS struct {
	base fs.FS
}

func NewDynamicFrontendFS(base fs.FS) fs.FS {
	return &dynamicFrontendFS{base: base}
}

func (d *dynamicFrontendFS) Open(name string) (fs.File, error) {
	cleanName := path.Clean(name)
	if cleanName == "." || cleanName == "index.html" {
		assembled, err := d.assembleIndexHTML()
		if err == nil {
			return &virtualFile{
				Reader: bytes.NewReader(assembled),
				name:   "index.html",
				size:   int64(len(assembled)),
			}, nil
		}
	}
	return d.base.Open(name)
}

func (d *dynamicFrontendFS) assembleIndexHTML() ([]byte, error) {
	components := []string{
		"eyeleo-prebreak.html",
		"eyeleo-shortbreak.html",
		"eyeleo-longbreak.html",
		"modal-eyeleo.html",
		"speech-bubble.html",
		"modal-rag.html",
		"modal-llm.html",
		"modal-recent.html",
		"modal-about.html",
		"modal-system.html",
		"modal-waka.html",
		"modal-profile.html",
		"settings-menu.html",
		"pet-mascot.html",
	}

	var sb strings.Builder
	for _, comp := range components {
		f, err := d.base.Open("components/" + comp)
		if err != nil {
			return nil, fmt.Errorf("open component %s: %w", comp, err)
		}
		data, err := io.ReadAll(f)
		_ = f.Close()
		if err != nil {
			return nil, fmt.Errorf("read component %s: %w", comp, err)
		}
		sb.WriteString("            <!-- Component: " + comp + " -->\n")
		sb.Write(data)
		sb.WriteString("\n\n")
	}

	indexTpl, err := fs.ReadFile(d.base, "index.html")
	if err != nil {
		return nil, err
	}

	out := strings.Replace(string(indexTpl), "<!-- {{COMPONENTS}} -->", sb.String(), 1)
	return []byte(out), nil
}

type virtualFile struct {
	*bytes.Reader
	name string
	size int64
}

func (vf *virtualFile) Close() error {
	return nil
}

func (vf *virtualFile) Stat() (fs.FileInfo, error) {
	return &virtualFileInfo{
		name: vf.name,
		size: vf.size,
	}, nil
}

type virtualFileInfo struct {
	name string
	size int64
}

func (vfi *virtualFileInfo) Name() string       { return vfi.name }
func (vfi *virtualFileInfo) Size() int64        { return vfi.size }
func (vfi *virtualFileInfo) Mode() fs.FileMode  { return 0444 }
func (vfi *virtualFileInfo) ModTime() time.Time { return time.Now() }
func (vfi *virtualFileInfo) IsDir() bool        { return false }
func (vfi *virtualFileInfo) Sys() interface{}   { return nil }
