// ============================================================================
// features/eyeleo/controller.js — Bộ điều khiển bảo vệ mắt EyeLeo (Slim)
// ============================================================================

import { els, hide } from "../../core/dom.js";
import { native } from "../../core/native.js";
import { loadConfig } from "./config.js";
import { openSettingsModal, closeSettingsModal, readSettingsFromForm } from "./modal.js";
import {
    showPrebreakNotification,
    triggerShortBreak,
    endShortBreak,
    triggerLongBreak,
    endLongBreak,
} from "./breaks.js";

const IDLE_CHECK_EVERY_SECONDS = 15;

export class EyeLeoController {
    constructor() {
        this.config = loadConfig();
        this.workSeconds = 0;
        this.lastShortBreakAt = 0;
        this.lastLongBreakAt = 0;
        this.prebreakFired = false;
        this.activeBreak = null;
        this.ticker = null;
        this.breakCountdown = null;
        this.initEvents();
    }

    initEvents() {
        els.btnCloseEyeleoSettings.addEventListener("click", () => closeSettingsModal());
        els.btnSaveSettings.addEventListener("click", () => {
            readSettingsFromForm(this.config);
            closeSettingsModal();
        });
        els.btnPrebreakDismiss.addEventListener("click", () => hide(els.eyeleoPrebreakToast));
        els.btnShortbreakSkip.addEventListener("click", () => endShortBreak(this));
        els.btnLongbreakPostpone.addEventListener("click", () => this.postponeLongBreak(2 * 60));
        els.btnLongbreakSkip.addEventListener("click", () => {
            if (!this.config.strictMode) endLongBreak(this);
        });

        window.onIdleTimeUpdate = (idleMs) => this.handleIdleTime(idleMs);
    }

    handleIdleTime(idleMs) {
        if (!this.config.autoIdle || idleMs < this.config.idleThresholdMs) return;
        if (this.workSeconds > 60) {
            this.workSeconds = 0;
            this.lastShortBreakAt = 0;
            this.lastLongBreakAt = 0;
            this.prebreakFired = false;
        }
    }

    start() {
        if (this.ticker) clearInterval(this.ticker);
        this.ticker = setInterval(() => {
            if (!this.config.enabled || this.activeBreak) return;
            this.workSeconds++;

            if (this.workSeconds % IDLE_CHECK_EVERY_SECONDS === 0) {
                native.getIdleTime();
            }

            const shortIntervalSec = this.config.shortIntervalMinutes * 60;
            const longIntervalSec = this.config.longIntervalMinutes * 60;

            if (this.config.prebreakNotify && !this.prebreakFired) {
                const secUntilLong = longIntervalSec - (this.workSeconds - this.lastLongBreakAt);
                if (secUntilLong > 0 && secUntilLong <= 30) {
                    this.prebreakFired = true;
                    showPrebreakNotification(secUntilLong);
                }
            }

            if (this.workSeconds - this.lastLongBreakAt >= longIntervalSec) {
                triggerLongBreak(this);
                return;
            }

            if (this.workSeconds - this.lastShortBreakAt >= shortIntervalSec) {
                triggerShortBreak(this);
            }
        }, 1000);
    }

    postponeLongBreak(seconds) {
        if (this.breakCountdown) clearInterval(this.breakCountdown);
        hide(els.eyeleoLongbreakOverlay);
        document.body.classList.remove("exercise-stretch");
        this.activeBreak = null;
        this.workSeconds = this.config.longIntervalMinutes * 60 - seconds;
        this.lastLongBreakAt = 0;
        this.prebreakFired = false;
    }

    openSettingsModal() {
        openSettingsModal(this.config);
    }
}

let controller = null;

export function initEyeLeo() {
    controller = new EyeLeoController();
    controller.start();
    return controller;
}

export function openEyeleoSettings() {
    if (controller) controller.openSettingsModal();
}
