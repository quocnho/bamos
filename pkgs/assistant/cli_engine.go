package main

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

type CommandResult struct {
	Command  string `json:"command"`
	Output   string `json:"output"`
	ExitCode int    `json:"exit_code"`
	Duration string `json:"duration"`
	IsSudo   bool   `json:"is_sudo"`
	Learned  bool   `json:"learned"`
}

type CLIEngine struct {
	mem *UserMemory
}

func NewCLIEngine(mem *UserMemory) *CLIEngine {
	return &CLIEngine{mem: mem}
}

// ExecuteCommand thực thi câu lệnh shell trong môi trường NixOS
func (e *CLIEngine) ExecuteCommand(ctx context.Context, rawCmd string, workingDir string, allowSudo bool) CommandResult {
	return e.ExecuteCommandStream(ctx, rawCmd, workingDir, allowSudo, nil)
}

// ExecuteCommandStream thực thi câu lệnh shell và stream từng dòng output tới terminal GUI
func (e *CLIEngine) ExecuteCommandStream(ctx context.Context, rawCmd string, workingDir string, allowSudo bool, onOutput func(string)) CommandResult {
	start := time.Now()
	trimmed := strings.TrimSpace(rawCmd)
	isSudo := false

	// Kiểm tra nếu lệnh yêu cầu quyền sudo
	if strings.HasPrefix(trimmed, "sudo ") {
		isSudo = true
		trimmed = strings.TrimSpace(strings.TrimPrefix(trimmed, "sudo "))
	}

	// Đảm bảo lệnh bam luôn tìm được trong NixOS
	cmdToRun := trimmed
	if strings.HasPrefix(trimmed, "bam ") || trimmed == "bam" {
		// Ưu tiên /run/current-system/sw/bin/bam hoặc /etc/nixos/pkgs/bam/bam.sh
		if _, err := exec.LookPath("bam"); err != nil {
			if _, err2 := os.Stat("/etc/nixos/pkgs/bam/bam.sh"); err2 == nil {
				cmdToRun = "/etc/nixos/pkgs/bam/bam.sh" + strings.TrimPrefix(trimmed, "bam")
			}
		}
	}

	var cmd *exec.Cmd
	if isSudo {
		checkSudo := exec.Command("sudo", "-n", "true")
		if err := checkSudo.Run(); err == nil {
			cmd = exec.CommandContext(ctx, "sudo", "bash", "-c", cmdToRun)
		} else {
			cmd = exec.CommandContext(ctx, "pkexec", "bash", "-c", cmdToRun)
		}
	} else {
		cmd = exec.CommandContext(ctx, "bash", "-c", cmdToRun)
	}

	if workingDir != "" {
		cmd.Dir = workingDir
	}

	var fullOutput strings.Builder
	stdoutPipe, errOut := cmd.StdoutPipe()
	stderrPipe, errErr := cmd.StderrPipe()

	if errOut != nil || errErr != nil {
		var combined bytes.Buffer
		cmd.Stdout = &combined
		cmd.Stderr = &combined
		err := cmd.Run()
		outStr := strings.TrimSpace(combined.String())
		if onOutput != nil && outStr != "" {
			onOutput(outStr)
		}
		duration := time.Since(start).Round(time.Millisecond).String()
		exitCode := 0
		if err != nil {
			if exitErr, ok := err.(*exec.ExitError); ok {
				exitCode = exitErr.ExitCode()
			} else {
				exitCode = 1
			}
		}
		return CommandResult{
			Command:  rawCmd,
			Output:   outStr,
			ExitCode: exitCode,
			Duration: duration,
			IsSudo:   isSudo,
			Learned:  exitCode == 0,
		}
	}

	if err := cmd.Start(); err != nil {
		duration := time.Since(start).Round(time.Millisecond).String()
		return CommandResult{
			Command:  rawCmd,
			Output:   fmt.Sprintf("Lỗi khởi tạo lệnh: %v", err),
			ExitCode: 1,
			Duration: duration,
			IsSudo:   isSudo,
			Learned:  false,
		}
	}

	// Đọc stdout và stderr song song
	outScanner := bufio.NewScanner(stdoutPipe)
	errScanner := bufio.NewScanner(stderrPipe)

	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		for outScanner.Scan() {
			line := outScanner.Text()
			fullOutput.WriteString(line + "\n")
			if onOutput != nil {
				onOutput(line)
			}
		}
	}()

	go func() {
		defer wg.Done()
		for errScanner.Scan() {
			line := errScanner.Text()
			fullOutput.WriteString(line + "\n")
			if onOutput != nil {
				onOutput(line)
			}
		}
	}()

	wg.Wait()
	err := cmd.Wait()
	duration := time.Since(start).Round(time.Millisecond).String()
	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			exitCode = 1
		}
	}

	output := strings.TrimSpace(fullOutput.String())

	// Tự học lệnh vào cơ sở tri thức người dùng
	learned := false
	if e.mem != nil && exitCode == 0 {
		e.mem.LearnCommand(rawCmd, "Thực thi thành công bởi Chủ nhân")
		learned = true
	}

	return CommandResult{
		Command:  rawCmd,
		Output:   output,
		ExitCode: exitCode,
		Duration: duration,
		IsSudo:   isSudo,
		Learned:  learned,
	}
}

// SearchOrLearnCommand tra cứu câu lệnh có sẵn trên máy hoặc hướng dẫn NixOS
func (e *CLIEngine) SearchOrLearnCommand(cmdName string) string {
	cmdName = strings.TrimSpace(cmdName)
	if cmdName == "" {
		return ""
	}

	// 1. Kiểm tra trong bộ nhớ đã học
	if e.mem != nil {
		if desc, exists := e.mem.GetLearnedCommand(cmdName); exists {
			return fmt.Sprintf("Em đã từng học lệnh này: `%s` (%s)", cmdName, desc)
		}
	}

	// 2. Tra cứu bằng `which`
	if path, err := exec.Command("which", cmdName).Output(); err == nil {
		return fmt.Sprintf("Lệnh `%s` đã có sẵn tại: `%s`", cmdName, strings.TrimSpace(string(path)))
	}

	// 3. Tra cứu gói NixOS tương ứng qua `nix-locate` hoặc đề xuất
	out, err := exec.Command("nix-env", "-qaP", "*"+cmdName+"*").Output()
	if err == nil && len(out) > 0 {
		lines := strings.Split(strings.TrimSpace(string(out)), "\n")
		var pkgs []string
		for i, l := range lines {
			if i >= 5 {
				break
			}
			pkgs = append(pkgs, "- `"+strings.Fields(l)[0]+"`")
		}
		if len(pkgs) > 0 {
			return fmt.Sprintf("Lệnh `%s` chưa cài đặt nhưng có thể nạp qua Nix package:\n%s\n(Chủ nhân có thể dùng `nix-shell -p <tên_gói>` để chạy thử ngay!)", cmdName, strings.Join(pkgs, "\n"))
		}
	}

	return fmt.Sprintf("Chưa tìm thấy lệnh `%s` trong hệ thống. Chủ nhân có muốn em tra cứu thêm trên kho tài liệu NixOS không ạ?", cmdName)
}
