// ============================================================================
// features/suggestions.js — Chip gợi ý câu hỏi nhanh
// ============================================================================

import { $$ } from "../core/dom.js";
import { setInputValue, send } from "../chat/chat.js";

/** Gắn sự kiện cho các chip gợi ý: điền câu hỏi mẫu rồi gửi ngay. */
export function initSuggestions() {
    $$(".chip").forEach((chip) => {
        chip.addEventListener("click", () => {
            const query = chip.getAttribute("data-query");
            if (!query) return;
            setInputValue(query);
            send();
        });
    });
}
