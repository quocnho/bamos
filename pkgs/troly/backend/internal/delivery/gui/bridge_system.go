package gui

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"os/exec"
	"strings"

	"troly/backend/internal/domain"
)

func (d *Dispatcher) handleOpenURL(payload json.RawMessage) {
	var req struct {
		URL string `json:"url"`
	}
	if err := json.Unmarshal(payload, &req); err != nil {
		return
	}
	raw := strings.TrimSpace(req.URL)
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return
	}
	TriggerOpenURL(parsed.String())
}

func getMutterIdleTimeMs() int64 {
	cmd := exec.Command("gdbus", "call", "--session", "--dest", "org.gnome.Mutter.IdleMonitor",
		"--object-path", "/org/gnome/Mutter/IdleMonitor/Core",
		"--method", "org.gnome.Mutter.IdleMonitor.GetIdletime")
	out, err := cmd.Output()
	if err != nil {
		return 0
	}
	s := strings.TrimSpace(string(out))
	s = strings.TrimPrefix(s, "(uint64 ")
	s = strings.TrimSuffix(s, ",)")
	s = strings.TrimSpace(s)
	var val int64
	_, _ = fmt.Sscanf(s, "%d", &val)
	return val
}

func (d *Dispatcher) handleSystemInspect() {
	ctx := context.Background()
	logs, _ := d.inspectUc.InspectRecentLogs(ctx)
	confs, _ := d.inspectUc.CheckNixOSConfiguration()
	idle := d.inspectUc.DetectIdleBackgroundApps()
	issues := append(logs, confs...)
	PushJSON("onSystemInspected", map[string]any{
		"ok":        true,
		"issues":    issues,
		"idle_apps": idle,
	})
}

func (d *Dispatcher) handleWakaStats() {
	sum := d.wakaUc.GetSummary()
	PushJSON("onWakaStats", map[string]any{
		"ok":      true,
		"summary": sum,
	})
}

func (d *Dispatcher) handleAddReminder(raw json.RawMessage) {
	var req struct {
		Title   string `json:"title"`
		DueTime string `json:"due_time"`
	}
	if err := json.Unmarshal(raw, &req); err == nil && req.Title != "" {
		d.wakaUc.AddReminder(req.Title, req.DueTime)
		d.handleWakaStats()
	}
}

func (d *Dispatcher) handleToggleReminder(raw json.RawMessage) {
	var req struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(raw, &req); err == nil && req.ID != "" {
		d.wakaUc.ToggleReminder(req.ID)
		d.handleWakaStats()
	}
}

func (d *Dispatcher) handleGetProfile() {
	prof := d.profileUc.GetProfile()
	PushJSON("onProfileLoaded", map[string]any{
		"ok":      true,
		"profile": prof,
		"domains": domain.AvailableDomains,
	})
}

func (d *Dispatcher) handleUpdateProfile(raw json.RawMessage) {
	var req domain.UserProfileData
	if err := json.Unmarshal(raw, &req); err == nil {
		d.profileUc.UpdateProfile(req)
		PushJSON("onProfileLoaded", map[string]any{
			"ok":      true,
			"profile": d.profileUc.GetProfile(),
			"domains": domain.AvailableDomains,
			"message": "Đã lưu hồ sơ thành công!",
		})
	}
}

func (d *Dispatcher) handleGetQuiz() {
	q := d.profileUc.GetQuizQuestions()
	PushJSON("onQuizQuestions", map[string]any{
		"ok":        true,
		"questions": q,
	})
}

func (d *Dispatcher) handleSubmitQuiz(raw json.RawMessage) {
	var req struct {
		Answers map[int]int `json:"answers"`
	}
	if err := json.Unmarshal(raw, &req); err == nil {
		res := d.profileUc.SubmitAssessment(req.Answers)
		PushJSON("onQuizSubmitted", map[string]any{
			"ok":      true,
			"result":  res,
			"profile": d.profileUc.GetProfile(),
		})
	}
}
