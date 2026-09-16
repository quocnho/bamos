// ============================================================================
// features/appearance/appearance-ui.js — Điều khiển Thiết Lập Giao Diện & Thú Cưng
// ============================================================================

import { els, show, hide, $$ } from "../../core/dom.js";
import { wailsBridge } from "../../core/wails-bridge.js";

let currentConfig = {
    theme_style: "default",
    dock_position: "bottom-right",
    window_scale: "normal",
    mascot_type: "puppy",
};

export function openAppearanceSettings() {
    if (!els.appearanceSettingsModal) return;
    show(els.appearanceSettingsModal);
    syncUIWithConfig();
}

export function closeAppearanceSettings() {
    if (!els.appearanceSettingsModal) return;
    hide(els.appearanceSettingsModal);
}

function syncUIWithConfig() {
    // 1. Mascot Active Card
    $$(".mascot-card").forEach((card) => {
        card.classList.toggle("active", card.dataset.mascot === currentConfig.mascot_type);
    });

    // 2. Theme Active Card
    $$(".theme-card").forEach((card) => {
        card.classList.toggle("active", card.dataset.theme === currentConfig.theme_style);
    });

    // 3. Dock Active Cell
    $$(".dock-cell").forEach((cell) => {
        cell.classList.toggle("active", cell.dataset.dock === currentConfig.dock_position);
    });

    // 4. Scale Selector
    $$(".scale-btn").forEach((btn) => {
        btn.classList.toggle("active", btn.dataset.scale === currentConfig.window_scale);
    });
}

function applyThemeDirectly(themeName) {
    document.documentElement.setAttribute("data-theme", themeName || "default");
}

function applyScaleDirectly(scale) {
    let scaleVal = "1";
    if (scale === "compact") scaleVal = "0.85";
    if (scale === "large") scaleVal = "1.15";
    document.documentElement.style.setProperty("--app-scale", scaleVal);
}

function applyDockDirectly(dockPos) {
    document.documentElement.setAttribute("data-dock", dockPos || "bottom-right");
}

export function handleSettingsLoaded(result) {
    if (result && result.settings) {
        const s = result.settings;
        currentConfig.theme_style = s.theme_style || "default";
        currentConfig.dock_position = s.dock_position || "bottom-right";
        currentConfig.window_scale = s.window_scale || "normal";
        currentConfig.mascot_type = s.mascot_type || "puppy";

        applyThemeDirectly(currentConfig.theme_style);
        applyScaleDirectly(currentConfig.window_scale);
        applyDockDirectly(currentConfig.dock_position);
        syncUIWithConfig();

        // Báo cho mascot engine chuyển thú cưng nếu cần
        wailsBridge.emit("mascot:change", currentConfig.mascot_type);
    }
}

export function handleSettingsSaved(result) {
    if (!result) return;
    if (els.appearanceSaveStatus) {
        els.appearanceSaveStatus.textContent = result.ok
            ? "✅ Đã lưu và áp dụng giao diện thành công!"
            : `❌ Lỗi: ${result.message}`;
        els.appearanceSaveStatus.className = `settings-status ${result.ok ? "success" : "error"}`;
        setTimeout(() => {
            if (els.appearanceSaveStatus) els.appearanceSaveStatus.textContent = "";
        }, 3000);
    }
}

export function initAppearanceUI() {
    if (els.btnCloseAppearanceSettings) {
        els.btnCloseAppearanceSettings.addEventListener("click", closeAppearanceSettings);
    }

    // Tương tác chọn Mascot
    document.addEventListener("click", (e) => {
        const mascotCard = e.target.closest(".mascot-card");
        if (mascotCard && mascotCard.dataset.mascot) {
            currentConfig.mascot_type = mascotCard.dataset.mascot;
            $$(".mascot-card").forEach((c) => c.classList.remove("active"));
            mascotCard.classList.add("active");
            wailsBridge.emit("mascot:change", currentConfig.mascot_type);
        }

        const themeCard = e.target.closest(".theme-card");
        if (themeCard && themeCard.dataset.theme) {
            currentConfig.theme_style = themeCard.dataset.theme;
            $$(".theme-card").forEach((c) => c.classList.remove("active"));
            themeCard.classList.add("active");
            applyThemeDirectly(currentConfig.theme_style);
        }

        const dockCell = e.target.closest(".dock-cell");
        if (dockCell && dockCell.dataset.dock) {
            currentConfig.dock_position = dockCell.dataset.dock;
            $$(".dock-cell").forEach((c) => c.classList.remove("active"));
            dockCell.classList.add("active");
            applyDockDirectly(currentConfig.dock_position);
        }

        const scaleBtn = e.target.closest(".scale-btn");
        if (scaleBtn && scaleBtn.dataset.scale) {
            currentConfig.window_scale = scaleBtn.dataset.scale;
            $$(".scale-btn").forEach((b) => b.classList.remove("active"));
            scaleBtn.classList.add("active");
            applyScaleDirectly(currentConfig.window_scale);
        }
    });

    // Nút Lưu thiết lập
    if (els.btnSaveAppearance) {
        els.btnSaveAppearance.addEventListener("click", async () => {
            if (els.appearanceSaveStatus) {
                els.appearanceSaveStatus.textContent = "⏳ Đang lưu thiết lập...";
                els.appearanceSaveStatus.className = "settings-status info";
            }
            try {
                await wailsBridge.call("saveSettings", {
                    theme_style: currentConfig.theme_style,
                    dock_position: currentConfig.dock_position,
                    window_scale: currentConfig.window_scale,
                    mascot_type: currentConfig.mascot_type,
                });
            } catch (err) {
                console.error("Lỗi lưu appearance settings:", err);
            }
        });
    }
}
