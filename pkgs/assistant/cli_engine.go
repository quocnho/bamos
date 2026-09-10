package main

import (
	"bytes"
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

type CommandResult struct {
	Command   string `json:"command"`
	Output    string `json:"output"`
	ExitCode  int    `json:"exit_code"`
	Duration  string `json:"duration"`
	IsSudo    bool   `json:"is_sudo"`
	Learned   bool   `json:"learned"`
}

type CLIEngine struct {
	mem *UserMemory
}

func NewCLIEngine(mem *UserMemory) *CLIEngine {
	return &CLIEngine{mem: mem}
}

// ExecuteCommand thực thi câu lệnh shell trong môi trường NixOS
func (e *CLIEngine) ExecuteCommand(ctx context.Context, rawCmd string, workingDir string, allowSudo bool) CommandResult {
	start := time.Now()
	trimmed := strings.TrimSpace(rawCmd)
	isSudo := false

	// Kiểm tra nếu lệnh yêu cầu quyền sudo
	if strings.HasPrefix(trimmed, "sudo ") {
		isSudo = true
		trimmed = strings.TrimSpace(strings.TrimPrefix(trimmed, "sudo "))
	}

	var cmd *exec.Cmd
	if isSudo {
		// Kiểm tra nếu sudo không cần pass được
		checkSudo := exec.Command("sudo", "-n", "true")
		if err := checkSudo.Run(); err == nil {
			cmd = exec.CommandContext(ctx, "sudo", "bash", "-c", trimmed)
		} else {
			// Dùng pkexec để bật hộp thoại GUI nhập pass bảo mật nếu trên desktop
			cmd = exec.CommandContext(ctx, "pkexec", "bash", "-c", trimmed)
		}
	} else {
		cmd = exec.CommandContext(ctx, "bash", "-c", trimmed)
	}

	if workingDir != "" {
		cmd.Dir = workingDir
	}

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	duration := time.Since(start).Round(time.Millisecond).String()
	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			exitCode = 1
		}
	}

	output := strings.TrimSpace(stdout.String())
	if stderr.Len() > 0 {
		errStr := strings.TrimSpace(stderr.String())
		if output != "" {
			output += "\n" + errStr
		} else {
			output = errStr
		}
	}

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
