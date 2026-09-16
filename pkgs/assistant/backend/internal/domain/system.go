package domain

type SystemIssue struct {
	ID          string `json:"id"`
	Type        string `json:"type"`     // "nixos_config", "systemd_error", "idle_app", "hardware_warning"
	Severity    string `json:"severity"` // "error", "warning", "info"
	Title       string `json:"title"`
	Description string `json:"description"`
	Suggestion  string `json:"suggestion"`
	FixCommand  string `json:"fix_command,omitempty"`
	Timestamp   string `json:"timestamp"`
}

type IdleAppReport struct {
	PID         string `json:"pid"`
	Name        string `json:"name"`
	Command     string `json:"command"`
	MemoryMB    string `json:"memory_mb"`
	IdleTimeMin int    `json:"idle_time_min"`
	Suggestion  string `json:"suggestion"`
}
