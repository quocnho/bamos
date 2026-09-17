// ============================================================================
// core/window-fit.js — Co giãn cửa sổ khít đúng nội dung (Slim)
// ============================================================================

import { els } from "./dom.js";
import { native } from "./native.js";
import {
    MIN_WIDTH,
    MIN_HEIGHT,
    MAX_WINDOW_HEIGHT,
    MODAL_CHROME,
    MODAL_IDS,
    FULL_UI_IDS,
    visible,
    cssNumber,
    measure,
} from "./window-measure.js";

let scheduled = false;
let fullActive = false;
let lastKey = "";

function fullUiElements() {
    return FULL_UI_IDS.map((id) => document.getElementById(id));
}

function anyFullUi() {
    return fullUiElements().some(visible);
}

function observeElements() {
    const nodes = [els.petWrapper, els.speechBubble, els.eyeleoShortbreakBubble, els.eyeleoPrebreakToast, els.chatStream];
    for (const id of MODAL_IDS) {
        const backdrop = document.getElementById(id);
        if (!backdrop) continue;
        nodes.push(backdrop);
        const card = backdrop.querySelector(".modal-card");
        if (card) nodes.push(card);
    }
    for (const id of FULL_UI_IDS) nodes.push(document.getElementById(id));
    return nodes.filter(Boolean);
}

function clampWidth(w) {
    const availW = (window.screen && window.screen.availWidth) || 1920;
    return Math.min(w, availW - 8);
}

function clampHeight(h) {
    const availH = (window.screen && window.screen.availHeight) || 800;
    return Math.min(h, MAX_WINDOW_HEIGHT, availH - 8);
}

function apply() {
    scheduled = false;
    const wantFull = anyFullUi();
    if (wantFull !== fullActive) {
        fullActive = wantFull;
        native.setWindowFull(wantFull);
    }
    if (fullActive) return;

    const size = measure();
    if (!size) return;

    const key = `${size.width}x${size.height}`;
    const mismatch =
        Math.abs(window.innerWidth - clampWidth(size.width)) > 3 ||
        Math.abs(window.innerHeight - clampHeight(size.height)) > 3;
    if (key === lastKey && !mismatch) return;
    lastKey = key;
    native.setContentSize(size.width, size.height);
}

function schedule() {
    if (scheduled) return;
    scheduled = true;
    setTimeout(() => requestAnimationFrame(apply), 90);
}

export function initWindowFit() {
    const pad = cssNumber("--fit-pad", 20);
    const petArea = cssNumber("--pet-area", 185);
    const rawAvail = (window.screen && window.screen.availHeight) || 800;

    const maxBubble = Math.max(180, Math.floor(Math.min(rawAvail - petArea - pad * 2 - 40, MAX_WINDOW_HEIGHT - petArea - pad * 2)));
    document.documentElement.style.setProperty("--bubble-max-height", `${maxBubble}px`);
    document.documentElement.style.setProperty("--screen-width", `${window.screen.availWidth}px`);

    const modalMax = Math.max(200, Math.floor(Math.min(rawAvail - petArea - pad * 2 - 40, MAX_WINDOW_HEIGHT - MODAL_CHROME)));
    document.documentElement.style.setProperty("--modal-max-height", `${modalMax}px`);

    const observed = observeElements();
    if (window.ResizeObserver) {
        const observer = new ResizeObserver(schedule);
        for (const el of observed) observer.observe(el);
    }
    if (window.MutationObserver) {
        const observer = new MutationObserver(schedule);
        for (const el of observed) {
            observer.observe(el, { attributes: true, attributeFilter: ["class", "style"] });
        }
        if (els.chatStream) {
            new MutationObserver(schedule).observe(els.chatStream, { childList: true, subtree: true });
        }
    }

    window.addEventListener("resize", schedule);
    window.addEventListener("load", schedule);
    if (els.speechBubble) {
        els.speechBubble.addEventListener("transitionend", schedule);
    }
    schedule();
}
