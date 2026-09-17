// ============================================================================
// core/window-measure.js — Đo lường kích thước các phần tử giao diện
// ============================================================================

import { els, isHidden } from "./dom.js";

export const MIN_WIDTH = 80;
export const MIN_HEIGHT = 80;
export const MAX_WINDOW_HEIGHT = 864;
export const TOAST_TOP = 20;
export const TOAST_GAP = 6;
export const MODAL_CHROME = 140;

export const MODAL_IDS = [
    "rag-settings-modal",
    "llm-settings-modal",
    "recent-sessions-modal",
    "about-modal",
    "eyeleo-settings-modal",
    "system-inspect-modal",
    "waka-modal",
    "profile-modal",
];

export const FULL_UI_IDS = ["eyeleo-longbreak-overlay"];

export function visible(el) {
    return Boolean(el) && !isHidden(el);
}

export function cssNumber(name, fallback) {
    const raw = getComputedStyle(document.documentElement).getPropertyValue(name);
    const value = parseFloat(raw);
    return Number.isFinite(value) ? value : fallback;
}

export function fitElements() {
    const nodes = [els.petWrapper, els.speechBubble, els.eyeleoShortbreakBubble];
    for (const id of MODAL_IDS) {
        const backdrop = document.getElementById(id);
        if (!visible(backdrop)) continue;
        const card = backdrop.querySelector(".modal-card");
        if (card) nodes.push(card);
    }
    return nodes;
}

export function measure() {
    const pad = cssNumber("--fit-pad", 20);
    let left = Infinity;
    let top = Infinity;
    let right = -Infinity;
    let bottom = -Infinity;

    for (const el of fitElements()) {
        if (!visible(el)) continue;
        left = Math.min(left, el.offsetLeft);
        top = Math.min(top, el.offsetTop);
        right = Math.max(right, el.offsetLeft + el.offsetWidth);
        bottom = Math.max(bottom, el.offsetTop + el.offsetHeight);
    }

    if (!Number.isFinite(left)) return null;

    if (visible(els.eyeleoPrebreakToast)) {
        top -= els.eyeleoPrebreakToast.offsetHeight + TOAST_TOP + TOAST_GAP;
    }

    return {
        width: Math.max(MIN_WIDTH, Math.ceil(right - left) + pad * 2),
        height: Math.max(MIN_HEIGHT, Math.ceil(bottom - top) + pad * 2),
    };
}
