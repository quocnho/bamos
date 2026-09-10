// ============================================================================
// features/eyeleo/controller.js — Bộ điều khiển bảo vệ mắt EyeLeo
// ----------------------------------------------------------------------------
// Ba cấp độ nhắc nhở theo chuẩn công thái học thị giác:
//   1. Cảnh báo trước 30 giây khi sắp tới giờ nghỉ dài.
//   2. Nghỉ ngắn 8 giây kèm bài tập mắt và hoạt hoạ chú cún.
//   3. Nghỉ dài (mặc định 5 phút) với tuỳ chọn chế độ nghiêm ngặt.
// Ngoài ra tự phát hiện người dùng rời máy (idle) để đặt lại chu kỳ làm việc.
// ============================================================================

import { els, show, hide } from "../../core/dom.js";
import { formatClock } from "../../core/utils.js";
import { playChime } from "../../core/audio.js";
import { native } from "../../core/native.js";
import { happy, hideBubble } from "../../pet/pet.js";
import { loadConfig, saveConfig } from "./config.js";
import { EYE_EXERCISES, EXERCISE_CLASSES } from "./exercises.js";

// Cứ 15 giây hỏi hệ điều hành một lần để biết người dùng có rời máy không.
const IDLE_CHECK_EVERY_SECONDS = 15;

function clearExerciseClasses() {
    document.body.classList.remove(...EXERCISE_CLASSES);
}

export class EyeLeoController {
    constructor() {
        this.config = loadConfig();

        // Bộ đếm chu kỳ làm việc
        this.workSeconds = 0;
        this.lastShortBreakAt = 0;
        this.lastLongBreakAt = 0;
        this.prebreakFired = false;
        this.activeBreak = null; // 'short' | 'long' | null

        this.ticker = null;
        this.breakCountdown = null;

        this.initEvents();
    }

    // -------------------------------------------------------------------------
    // Khởi tạo sự kiện
    // -------------------------------------------------------------------------
    initEvents() {
        els.btnCloseEyeleoSettings.addEventListener("click", () =>
            this.closeSettingsModal(),
        );
        els.btnSaveSettings.addEventListener("click", () => {
            this.readSettingsFromForm();
            this.closeSettingsModal();
        });

        els.btnPrebreakDismiss.addEventListener("click", () =>
            hide(els.eyeleoPrebreakToast),
        );
        els.btnShortbreakSkip.addEventListener("click", () =>
            this.endShortBreak(),
        );
        els.btnLongbreakPostpone.addEventListener("click", () =>
            this.postponeLongBreak(2 * 60),
        );

        els.btnLongbreakSkip.addEventListener("click", () => {
            if (!this.config.strictMode) this.endLongBreak();
        });

        // Backend Go gửi thời gian rảnh (idle) từ Mutter qua kênh native.
        window.onIdleTimeUpdate = (idleMs) => this.handleIdleTime(idleMs);
    }

    handleIdleTime(idleMs) {
        if (!this.config.autoIdle || idleMs < this.config.idleThresholdMs)
            return;
        // Người dùng đã rời máy quá ngưỡng -> đặt lại chu kỳ làm việc.
        if (this.workSeconds > 60) {
            console.log(
                `[EyeLeo] Người dùng không hoạt động ${Math.round(idleMs / 1000)}s -> đặt lại chu kỳ.`,
            );
            this.workSeconds = 0;
            this.lastShortBreakAt = 0;
            this.lastLongBreakAt = 0;
            this.prebreakFired = false;
        }
    }

    // -------------------------------------------------------------------------
    // Bộ đếm chính
    // -------------------------------------------------------------------------
    start() {
        if (this.ticker) clearInterval(this.ticker);

        this.ticker = setInterval(() => {
            if (!this.config.enabled || this.activeBreak) return;

            this.workSeconds++;

            // Định kỳ hỏi thời gian idle từ hệ điều hành.
            if (this.workSeconds % IDLE_CHECK_EVERY_SECONDS === 0) {
                native.getIdleTime();
            }

            const shortIntervalSec = this.config.shortIntervalMinutes * 60;
            const longIntervalSec = this.config.longIntervalMinutes * 60;

            // 1. Cảnh báo trước 30 giây (Pre-break notification).
            if (this.config.prebreakNotify && !this.prebreakFired) {
                const secUntilLong =
                    longIntervalSec - (this.workSeconds - this.lastLongBreakAt);
                if (secUntilLong > 0 && secUntilLong <= 30) {
                    this.showPrebreakNotification(secUntilLong);
                }
            }

            // 2. Nghỉ dài.
            if (this.workSeconds - this.lastLongBreakAt >= longIntervalSec) {
                this.triggerLongBreak();
                return;
            }

            // 3. Nghỉ ngắn.
            if (this.workSeconds - this.lastShortBreakAt >= shortIntervalSec) {
                this.triggerShortBreak();
            }
        }, 1000);
    }

    playChime(type = "bell") {
        playChime(type, this.config.soundEnabled);
    }

    // -------------------------------------------------------------------------
    // 1. Cảnh báo trước giờ nghỉ dài
    // -------------------------------------------------------------------------
    // 1. Cảnh báo trước 30 giây (Pre-break notification).
    // Đưa cửa sổ BamAI lên trên cùng TRƯỚC, rồi mới hiện thông báo để người
    // dùng chắc chắn nhìn thấy nhắc nhở.
    showPrebreakNotification(remainingSeconds) {
        this.prebreakFired = true;
        els.prebreakSeconds.textContent = remainingSeconds;

        native.activateAndRaise();
        setTimeout(() => show(els.eyeleoPrebreakToast), 150);
        setTimeout(() => hide(els.eyeleoPrebreakToast), 10000);
    }

    // -------------------------------------------------------------------------
    // 2. Nghỉ ngắn (mặc định 8 giây)
    // -------------------------------------------------------------------------
    triggerShortBreak() {
        this.activeBreak = "short";
        this.lastShortBreakAt = this.workSeconds;
        hide(els.eyeleoPrebreakToast);
        hideBubble();

        native.activateAndRaise();

        // Chọn ngẫu nhiên một bài tập mắt.
        const exercise =
            EYE_EXERCISES[Math.floor(Math.random() * EYE_EXERCISES.length)];
        els.shortbreakExerciseName.textContent = exercise.name;
        els.shortbreakIcon.textContent = exercise.icon;
        els.shortbreakInstruction.textContent = exercise.instruction;

        clearExerciseClasses();
        document.body.classList.add(exercise.cssClass);

        this.playChime("bell");
        show(els.eyeleoShortbreakBubble);

        let remaining = this.config.shortDurationSeconds;
        const total = remaining;
        els.shortbreakCountdown.textContent = `${remaining}s`;
        els.shortbreakProgress.style.width = "100%";

        if (this.breakCountdown) clearInterval(this.breakCountdown);
        this.breakCountdown = setInterval(() => {
            remaining--;
            const pct = Math.max(0, (remaining / total) * 100);
            els.shortbreakProgress.style.width = `${pct}%`;
            els.shortbreakCountdown.textContent = `${remaining}s`;

            if (remaining <= 0) {
                clearInterval(this.breakCountdown);
                this.endShortBreak();
            }
        }, 1000);
    }

    endShortBreak() {
        if (this.breakCountdown) clearInterval(this.breakCountdown);
        hide(els.eyeleoShortbreakBubble);
        clearExerciseClasses();
        this.activeBreak = null;
        this.playChime("finish");
        happy();
    }

    // -------------------------------------------------------------------------
    // 3. Nghỉ dài (mặc định 5 phút)
    // -------------------------------------------------------------------------
    triggerLongBreak() {
        this.activeBreak = "long";
        this.lastLongBreakAt = this.workSeconds;
        this.lastShortBreakAt = this.workSeconds; // Nghỉ dài cũng làm mới nghỉ ngắn
        this.prebreakFired = false;
        hide(els.eyeleoPrebreakToast);
        hideBubble();
        hide(els.eyeleoShortbreakBubble);

        native.activateAndRaise();

        // Chú cún chuyển sang tư thế vươn vai.
        clearExerciseClasses();
        document.body.classList.add("exercise-stretch");

        // Chế độ nghiêm ngặt: ẩn hoàn toàn nút bỏ qua.
        if (this.config.strictMode) {
            show(els.strictModeIndicator);
            els.btnLongbreakSkip.style.display = "none";
        } else {
            hide(els.strictModeIndicator);
            els.btnLongbreakSkip.style.display = "";
        }

        this.playChime("bell");
        show(els.eyeleoLongbreakOverlay);

        let remaining = this.config.longDurationSeconds;
        this.updateLongbreakClock(remaining);

        if (this.breakCountdown) clearInterval(this.breakCountdown);
        this.breakCountdown = setInterval(() => {
            remaining--;
            this.updateLongbreakClock(remaining);

            if (remaining <= 0) {
                clearInterval(this.breakCountdown);
                this.endLongBreak();
            }
        }, 1000);
    }

    updateLongbreakClock(seconds) {
        els.longbreakClock.textContent = formatClock(seconds);
    }

    postponeLongBreak(seconds) {
        if (this.breakCountdown) clearInterval(this.breakCountdown);
        hide(els.eyeleoLongbreakOverlay);
        document.body.classList.remove("exercise-stretch");
        this.activeBreak = null;
        // Lùi mốc thời gian để nghỉ dài sẽ nhắc lại sau `seconds` giây.
        this.workSeconds = this.config.longIntervalMinutes * 60 - seconds;
        this.lastLongBreakAt = 0;
        this.prebreakFired = false;
    }

    endLongBreak() {
        if (this.breakCountdown) clearInterval(this.breakCountdown);
        hide(els.eyeleoLongbreakOverlay);
        document.body.classList.remove("exercise-stretch");
        this.activeBreak = null;
        this.prebreakFired = false;
        this.playChime("finish");
        happy();
    }

    // -------------------------------------------------------------------------
    // 4. Modal cài đặt
    // -------------------------------------------------------------------------
    openSettingsModal() {
        els.setEyeleoActive.checked = this.config.enabled;
        els.setShortInterval.value = String(this.config.shortIntervalMinutes);
        els.setShortDuration.value = String(this.config.shortDurationSeconds);
        els.setLongInterval.value = String(this.config.longIntervalMinutes);
        els.setLongDuration.value = String(
            Math.round(this.config.longDurationSeconds / 60),
        );
        els.setStrictMode.checked = this.config.strictMode;
        els.setPrebreakNotify.checked = this.config.prebreakNotify;
        els.setAutoIdle.checked = this.config.autoIdle;
        els.setSoundEnabled.checked = this.config.soundEnabled;

        show(els.eyeleoSettingsModal);
    }

    closeSettingsModal() {
        hide(els.eyeleoSettingsModal);
    }

    readSettingsFromForm() {
        const config = this.config;
        config.enabled = els.setEyeleoActive.checked;
        config.shortIntervalMinutes = parseInt(els.setShortInterval.value, 10);
        config.shortDurationSeconds = parseInt(els.setShortDuration.value, 10);
        config.longIntervalMinutes = parseInt(els.setLongInterval.value, 10);
        config.longDurationSeconds =
            parseInt(els.setLongDuration.value, 10) * 60;
        config.strictMode = els.setStrictMode.checked;
        config.prebreakNotify = els.setPrebreakNotify.checked;
        config.autoIdle = els.setAutoIdle.checked;
        config.soundEnabled = els.setSoundEnabled.checked;

        saveConfig(config);

        happy();
    }
}

let controller = null;

/** Khởi tạo và chạy bộ đếm EyeLeo. */
export function initEyeLeo() {
    controller = new EyeLeoController();
    controller.start();
    return controller;
}

/** Mở bảng thiết lập EyeLeo từ bên ngoài (menu GNOME Shell, IPC...). */
export function openEyeleoSettings() {
    if (controller) controller.openSettingsModal();
}
