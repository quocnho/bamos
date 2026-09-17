// ============================================================================
// features/suggestions/suggestions.js — Hiển thị và tương tác Chip gợi ý
// ============================================================================

import { els } from "../../core/dom.js";
import { bus } from "../../core/bus.js";
import { setInputValue, send } from "../../chat/chat.js";
import { showTooltip, hideTooltip } from "../../core/tooltip.js";
import { loadStats, trackQuestion, visibleItems } from "./stats.js";

export function render() {
    const container = els.smartChips;
    if (!container) return;

    container.textContent = "";
    for (const item of visibleItems()) {
        const chip = document.createElement("button");
        chip.className = "chip";
        chip.dataset.query = item.query;
        chip.textContent = `${item.icon} ${item.label}`;

        chip.addEventListener("mouseenter", () => {
            const times = item.count > 0 ? ` • đã hỏi ${item.count} lần` : "";
            showTooltip(
                chip,
                `${item.icon} ${item.label}`,
                `${item.query}${times}`,
            );
        });
        chip.addEventListener("mouseleave", hideTooltip);

        container.appendChild(chip);
    }
}

export function initSuggestions() {
    loadStats();
    render();

    if (els.smartChips) {
        els.smartChips.addEventListener("click", (e) => {
            const chip = e.target.closest(".chip");
            if (!chip) return;
            const query = chip.dataset.query;
            if (!query) return;
            hideTooltip();
            setInputValue(query);
            send();
        });
    }

    bus.on("chat:asked", (question) => {
        trackQuestion(question);
        render();
    });
}
