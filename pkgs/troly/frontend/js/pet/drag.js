// ============================================================================
// pet/drag.js — Tương tác chuột với chú cún (Cố định vị trí, không kéo thả)
// ----------------------------------------------------------------------------
// Giao diện cố định sát góc dưới bên phải màn hình làm chuẩn.
//  - Bấm 1 lần vào chú cún          → đánh thức AI / mở bong bóng chat.
//  - Bấm đúp (double-click) vào cún → cho cún đi ngủ canh nhà.
// ============================================================================

import { els } from "../core/dom.js";
import { wake, sleep } from "./pet.js";

const DOUBLE_CLICK_MS = 250;
let clickTimer = null;

// Phân biệt bấm 1 lần (đánh thức) và bấm đúp (đi ngủ).
function handlePetClick(e) {
    // Không xử lý nếu click trúng các nút tương tác (thanh input, nút settings,...)
    if (e && e.target && e.target.closest && e.target.closest("button, input, .pet-head-input-bar")) {
        return;
    }

    if (clickTimer !== null) {
        clearTimeout(clickTimer);
        clickTimer = null;
        sleep();
        return;
    }
    clickTimer = setTimeout(() => {
        clickTimer = null;
        wake();
    }, DOUBLE_CLICK_MS);
}

export function initDrag() {
    if (els.petWrapper) {
        els.petWrapper.addEventListener("click", handlePetClick);
    }
}

