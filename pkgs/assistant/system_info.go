package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
)

type SystemInfo struct {
	OS          string `json:"os"`
	Kernel      string `json:"kernel"`
	HostName    string `json:"hostname"`
	CPU         string `json:"cpu"`
	Cores       int    `json:"cores"`
	MemoryTotal string `json:"memory_total"`
	MemoryUsed  string `json:"memory_used"`
	DiskUsage   string `json:"disk_usage"`
	GPU         string `json:"gpu"`
}

type RunningApp struct {
	Name    string `json:"name"`
	PID     string `json:"pid"`
	CPU     string `json:"cpu"`
	Memory  string `json:"memory"`
	Command string `json:"command"`
}

func GetHardwareAndSystemInfo() SystemInfo {
	info := SystemInfo{
		OS:       "BamOS (NixOS)",
		HostName: "localhost",
		Cores:    runtime.NumCPU(),
	}

	if hn, err := os.Hostname(); err == nil {
		info.HostName = hn
	}

	// Kernel
	if out, err := exec.Command("uname", "-sr").Output(); err == nil {
		info.Kernel = strings.TrimSpace(string(out))
	}

	// CPU Model
	if f, err := os.Open("/proc/cpuinfo"); err == nil {
		defer f.Close()
		scanner := bufio.NewScanner(f)
		for scanner.Scan() {
			line := scanner.Text()
			if strings.HasPrefix(line, "model name") {
				parts := strings.Split(line, ":")
				if len(parts) > 1 {
					info.CPU = strings.TrimSpace(parts[1])
					break
				}
			}
		}
	}

	// Memory
	if f, err := os.Open("/proc/meminfo"); err == nil {
		defer f.Close()
		scanner := bufio.NewScanner(f)
		var totalKB, availKB float64
		for scanner.Scan() {
			line := scanner.Text()
			if strings.HasPrefix(line, "MemTotal:") {
				fields := strings.Fields(line)
				if len(fields) >= 2 {
					totalKB, _ = strconv.ParseFloat(fields[1], 64)
				}
			} else if strings.HasPrefix(line, "MemAvailable:") {
				fields := strings.Fields(line)
				if len(fields) >= 2 {
					availKB, _ = strconv.ParseFloat(fields[1], 64)
				}
			}
		}
		if totalKB > 0 {
			usedKB := totalKB - availKB
			info.MemoryTotal = fmt.Sprintf("%.1f GB", totalKB/(1024*1024))
			info.MemoryUsed = fmt.Sprintf("%.1f GB (%.0f%%)", usedKB/(1024*1024), (usedKB/totalKB)*100)
		}
	}

	// Disk
	if out, err := exec.Command("df", "-h", "/").Output(); err == nil {
		lines := strings.Split(strings.TrimSpace(string(out)), "\n")
		if len(lines) >= 2 {
			fields := strings.Fields(lines[1])
			if len(fields) >= 5 {
				info.DiskUsage = fmt.Sprintf("%s / %s (Dùng: %s)", fields[2], fields[1], fields[4])
			}
		}
	}

	// GPU (lspci)
	if out, err := exec.Command("lspci").Output(); err == nil {
		var gpus []string
		lines := strings.Split(string(out), "\n")
		for _, line := range lines {
			lower := strings.ToLower(line)
			if strings.Contains(lower, "vga compatible controller") || strings.Contains(lower, "3d controller") {
				parts := strings.SplitN(line, ": ", 2)
				if len(parts) == 2 {
					gpus = append(gpus, strings.TrimSpace(parts[1]))
				}
			}
		}
		if len(gpus) > 0 {
			info.GPU = strings.Join(gpus, " + ")
		} else {
			info.GPU = "Tích hợp đồ họa"
		}
	}

	return info
}

// GetRunningApps trả về danh sách các ứng dụng người dùng và tiến trình chính
func GetRunningApps() []RunningApp {
	var apps []RunningApp
	out, err := exec.Command("ps", "-eo", "pid,%cpu,%mem,comm", "--sort=-%mem").Output()
	if err != nil {
		return apps
	}

	seen := make(map[string]bool)
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	for i, line := range lines {
		if i == 0 {
			continue // skip header
		}
		fields := strings.Fields(line)
		if len(fields) < 4 {
			continue
		}
		pid := fields[0]
		cpu := fields[1]
		mem := fields[2]
		comm := fields[3]

		// Lọc các kernel thread hoặc tiến trình hệ thống quen thuộc
		if strings.HasPrefix(comm, "kworker") || comm == "systemd" || comm == "ps" {
			continue
		}

		friendlyName := comm
		switch comm {
		case "antigravity-ide":
			friendlyName = "Antigravity IDE 🚀"
		case "firefox":
			friendlyName = "Firefox Web Browser 🌐"
		case "gnome-shell":
			friendlyName = "GNOME Shell (Desktop)"
		case "nautilus":
			friendlyName = "Tệp tin (Nautilus) 📁"
		case "llama-server":
			friendlyName = "BamAI Local LLM Server 🧠"
		case "bamos-assistant":
			friendlyName = "BamOS Puppy Mascot 🐶"
		case "zed":
			friendlyName = "Zed Code Editor"
		case "alacritty", "kitty", "gnome-terminal-":
			friendlyName = "Terminal Console 💻"
		}

		if !seen[friendlyName] {
			seen[friendlyName] = true
			apps = append(apps, RunningApp{
				Name:    friendlyName,
				PID:     pid,
				CPU:     cpu + "%",
				Memory:  mem + "%",
				Command: comm,
			})
		}

		if len(apps) >= 12 {
			break
		}
	}
	return apps
}
