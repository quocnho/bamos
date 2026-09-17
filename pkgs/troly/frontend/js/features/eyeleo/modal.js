// ============================================================================
// features/eyeleo/modal.js — Quản lý form thiết lập EyeLeo
// ============================================================================

import { els, show, hide } from "../../core/dom.js";
import { happy } from "../../pet/pet.js";
import { saveConfig } from "./config.js";

export function openSettingsModal(config) {
    els.setEyeleoActive.checked = config.enabled;
    els.setShortInterval.value = String(config.shortIntervalMinutes);
    els.setShortDuration.value = String(config.shortDurationSeconds);
    els.setLongInterval.value = String(config.longIntervalMinutes);
    els.setLongDuration.value = String(Math.round(config.longDurationSeconds / 60));
    els.setStrictMode.checked = config.strictMode;
    els.setPrebreakNotify.checked = config.prebreakNotify;
    els.setAutoIdle.checked = config.autoIdle;
    els.setSoundEnabled.checked = config.soundEnabled;

    show(els.eyeleoSettingsModal);
}

export function closeSettingsModal() {
    hide(els.eyeleoSettingsModal);
}

export function readSettingsFromForm(config) {
    config.enabled = els.setEyeleoActive.checked;
    config.shortIntervalMinutes = parseInt(els.setShortInterval.value, 10);
    config.shortDurationSeconds = parseInt(els.setShortDuration.value, 10);
    config.longIntervalMinutes = parseInt(els.setLongInterval.value, 10);
    config.longDurationSeconds = parseInt(els.setLongDuration.value, 10) * 60;
    config.strictMode = els.setStrictMode.checked;
    config.prebreakNotify = els.setPrebreakNotify.checked;
    config.autoIdle = els.setAutoIdle.checked;
    config.soundEnabled = els.setSoundEnabled.checked;

    saveConfig(config);
    happy();
}
