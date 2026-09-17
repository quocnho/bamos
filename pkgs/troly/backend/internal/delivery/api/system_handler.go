package api

import (
	"context"
	"encoding/json"
	"net/http"

	"troly/backend/internal/domain"
	"troly/backend/internal/usecase/profile"
	"troly/backend/internal/usecase/system"
	"troly/backend/internal/usecase/waka"
)

type SystemHandler struct {
	profileUc *profile.ProfileUsecase
	wakaUc    *waka.WakaUsecase
	inspectUc *system.InspectUsecase
}

func NewSystemHandler(profileUc *profile.ProfileUsecase, wakaUc *waka.WakaUsecase, inspectUc *system.InspectUsecase) *SystemHandler {
	return &SystemHandler{
		profileUc: profileUc,
		wakaUc:    wakaUc,
		inspectUc: inspectUc,
	}
}

func (h *SystemHandler) HandleProfile(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		p := h.profileUc.GetProfile()
		JSON(w, http.StatusOK, p)
	case http.MethodPost:
		var p domain.UserProfileData
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			Error(w, http.StatusBadRequest, "Invalid request body")
			return
		}
		h.profileUc.UpdateProfile(p)
		JSON(w, http.StatusOK, h.profileUc.GetProfile())
	default:
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

func (h *SystemHandler) HandleWaka(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	sum := h.wakaUc.GetSummary()
	JSON(w, http.StatusOK, sum)
}

func (h *SystemHandler) HandleInspect(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	ctx := context.Background()
	logs, _ := h.inspectUc.InspectRecentLogs(ctx)
	confs, _ := h.inspectUc.CheckNixOSConfiguration()
	idle := h.inspectUc.DetectIdleBackgroundApps()
	issues := append(logs, confs...)
	JSON(w, http.StatusOK, map[string]interface{}{
		"issues":    issues,
		"idle_apps": idle,
	})
}
