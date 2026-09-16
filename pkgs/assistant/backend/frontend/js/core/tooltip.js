// ============================================================================
// core/tooltip.js — Tooltip nhỏ cho chip từ khóa
// ----------------------------------------------------------------------------
// Dùng phần tử #chip-tooltip (position: fixed) để hiển thị câu hỏi đầy đủ và
// số lần đã hỏi, giúp người dùng biết chip sẽ gửi đi nội dung gì.
// ============================================================================

import { els, show, hide } from "./dom.js";

const VIEWPORT_MARGIN = 8;

function position(anchor, tip) {
    const rect = anchor.getBoundingClientRect();
    const tipRect = tip.getBoundingClientRect();

    let left = rect.left + rect.width / 2 - tipRect.width / 2;
    let top = rect.top - tipRect.height - 8;

    left = Math.max(
        VIEWPORT_MARGIN,
        Math.min(left, window.innerWidth - tipRect.width - VIEWPORT_MARGIN),
    );
    if (top < VIEWPORT_MARGIN) {
        top = rect.bottom + 8;
    }

    tip.style.left = `${Math.round(left)}px`;
    tip.style.top = `${Math.round(top)}px`;
}

/**
 * Hiển thị tooltip gắn với một phần tử.
 * @param {HTMLElement} anchor
 * @param {string} title
 * @param {string} body
 */
export function showTooltip(anchor, title, body) {
    const tip = els.chipTooltip;
    if (!tip || !anchor) return;

    tip.textContent = "";

    const titleEl = document.createElement("div");
    titleEl.className = "tip-title";
    titleEl.textContent = title;

    const bodyEl = document.createElement("div");
    bodyEl.className = "tip-body";
    bodyEl.textContent = body;

    tip.appendChild(titleEl);
    tip.appendChild(bodyEl);

    show(tip);
    position(anchor, tip);
}

export function hideTooltip() {
    hide(els.chipTooltip);
}
