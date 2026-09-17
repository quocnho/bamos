// ============================================================================
// features/eyeleo/breaks.js — Trình kích hoạt và kết thúc nghỉ ngắn / nghỉ dài
// ============================================================================

import { els, show, hide } from "../../core/dom.js";
import { formatClock } from "../../core/utils.js";
import { playChime } from "../../core/audio.js";
import { native } from "../../core/native.js";
import { happy, hideBubble } from "../../pet/pet.js";
import { EYE_EXERCISES, EXERCISE_CLASSES } from "./exercises.js";

export function clearExerciseClasses() {
    document.body.classList.remove(...EXERCISE_CLASSES);
}

export function showPrebreakNotification(remainingSeconds) {
    els.prebreakSeconds.textContent = remainingSeconds;
    native.raiseNotification();
    setTimeout(() => show(els.eyeleoPrebreakToast), 400);
    setTimeout(() => hide(els.eyeleoPrebreakToast), 15000);
}

export function triggerShortBreak(ctrl) {
    ctrl.activeBreak = "short";
    ctrl.lastShortBreakAt = ctrl.workSeconds;
    hide(els.eyeleoPrebreakToast);
    hideBubble();
    native.raiseNotification();

    const exercise = EYE_EXERCISES[Math.floor(Math.random() * EYE_EXERCISES.length)];
    els.shortbreakExerciseName.textContent = exercise.name;
    els.shortbreakIcon.textContent = exercise.icon;
    els.shortbreakInstruction.textContent = exercise.instruction;

    clearExerciseClasses();
    document.body.classList.add(exercise.cssClass);

    playChime("bell", ctrl.config.soundEnabled);
    show(els.eyeleoShortbreakBubble);

    let remaining = ctrl.config.shortDurationSeconds;
    const total = remaining;
    els.shortbreakCountdown.textContent = `${remaining}s`;
    els.shortbreakProgress.style.width = "100%";

    if (ctrl.breakCountdown) clearInterval(ctrl.breakCountdown);
    ctrl.breakCountdown = setInterval(() => {
        remaining--;
        const pct = Math.max(0, (remaining / total) * 100);
        els.shortbreakProgress.style.width = `${pct}%`;
        els.shortbreakCountdown.textContent = `${remaining}s`;
        if (remaining <= 0) {
            clearInterval(ctrl.breakCountdown);
            endShortBreak(ctrl);
        }
    }, 1000);
}

export function endShortBreak(ctrl) {
    if (ctrl.breakCountdown) clearInterval(ctrl.breakCountdown);
    hide(els.eyeleoShortbreakBubble);
    clearExerciseClasses();
    ctrl.activeBreak = null;
    playChime("finish", ctrl.config.soundEnabled);
    happy();
}

export function triggerLongBreak(ctrl) {
    ctrl.activeBreak = "long";
    ctrl.lastLongBreakAt = ctrl.workSeconds;
    ctrl.lastShortBreakAt = ctrl.workSeconds;
    ctrl.prebreakFired = false;
    hide(els.eyeleoPrebreakToast);
    hideBubble();
    hide(els.eyeleoShortbreakBubble);
    native.raiseNotification();

    clearExerciseClasses();
    document.body.classList.add("exercise-stretch");

    if (ctrl.config.strictMode) {
        show(els.strictModeIndicator);
        els.btnLongbreakSkip.style.display = "none";
    } else {
        hide(els.strictModeIndicator);
        els.btnLongbreakSkip.style.display = "";
    }

    playChime("bell", ctrl.config.soundEnabled);
    show(els.eyeleoLongbreakOverlay);

    let remaining = ctrl.config.longDurationSeconds;
    els.longbreakClock.textContent = formatClock(remaining);

    if (ctrl.breakCountdown) clearInterval(ctrl.breakCountdown);
    ctrl.breakCountdown = setInterval(() => {
        remaining--;
        els.longbreakClock.textContent = formatClock(remaining);
        if (remaining <= 0) {
            clearInterval(ctrl.breakCountdown);
            endLongBreak(ctrl);
        }
    }, 1000);
}

export function endLongBreak(ctrl) {
    if (ctrl.breakCountdown) clearInterval(ctrl.breakCountdown);
    hide(els.eyeleoLongbreakOverlay);
    document.body.classList.remove("exercise-stretch");
    ctrl.activeBreak = null;
    ctrl.prebreakFired = false;
    playChime("finish", ctrl.config.soundEnabled);
    happy();
}
