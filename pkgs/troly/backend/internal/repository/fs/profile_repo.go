package fs

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"

	"troly/backend/internal/domain"
)

type ProfileRepo struct {
	mu       sync.RWMutex
	filePath string
	Profile  domain.UserProfileData
}

func NewProfileRepo() *ProfileRepo {
	home, _ := os.UserHomeDir()
	dir := filepath.Join(home, ".local", "share", "bamos")
	_ = os.MkdirAll(dir, 0755)
	file := filepath.Join(dir, "user_profile.json")

	repo := &ProfileRepo{
		filePath: file,
		Profile: domain.UserProfileData{
			FullName:     "Chủ nhân",
			Addressing:   "Chủ nhân",
			CurrentLevel: "Chưa đánh giá",
			Domains:      []string{"NixOS & Linux", "Lập trình Backend", "AI & RAG"},
			Preferences: domain.UserPreferences{
				ThemeColor: "teal",
				ThemeMode:  "dark",
				NightLight: true,
				SoundChime: true,
			},
		},
	}
	repo.Load()
	return repo
}

func (r *ProfileRepo) Load() {
	r.mu.Lock()
	defer r.mu.Unlock()

	data, err := os.ReadFile(r.filePath)
	if err == nil {
		_ = json.Unmarshal(data, &r.Profile)
	}
	if len(r.Profile.Domains) == 0 {
		r.Profile.Domains = []string{"NixOS & Linux", "Lập trình Backend", "AI & RAG"}
	}
}

func (r *ProfileRepo) Save() error {
	r.mu.Lock()
	defer r.mu.Unlock()

	data, err := json.MarshalIndent(r.Profile, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(r.filePath, data, 0644)
}

func (r *ProfileRepo) Get() domain.UserProfileData {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.Profile
}

func (r *ProfileRepo) Set(p domain.UserProfileData) {
	r.mu.Lock()
	r.Profile = p
	r.mu.Unlock()
	_ = r.Save()
}
