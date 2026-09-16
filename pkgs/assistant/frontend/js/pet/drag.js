// ============================================================================
// pet/drag.js — Tương tác chuột với thú cưng (Loại bỏ kéo thả tự do)
// ----------------------------------------------------------------------------
// Theo chuẩn UI mới, cửa sổ được cố định chuẩn xác theo 4 góc màn hình (Docking).
// Các thao tác chuột vào thú cưng được chuyển thành tương tác cảm xúc:
//  - Bấm 1 lần vào thú cưng            → Đánh thức AI / Mở khung chat.
//  - Bấm đúp (double-click) vào thú cưng → Cho thú cưng ngủ canh nhà.
//  - Vuốt ve (di chuột có nhấn)        → Tung tim yêu thương ❤️.
// ============================================================================

import { els } from "../core/dom.js";
import { wake, sleep, petTouch } from "./pet.js";

const DOUBLE_CLICK_MS = 240;
let clickTimer = null;
let isMouseDown = false;

// Phân biệt bấm 1 lần (đánh thức) và bấm đúp (đi ngủ).
function handlePetClick() {
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

function onPetMouseDown(e) {
    isMouseDown = true;
}

function onPetMouseUp(e) {
    if (isMouseDown) {
        isMouseDown = false;
        handlePetClick();
    }
}

export function initDrag() {
    if (els.petWrapper) {
        els.petWrapper.addEventListener("mousedown", onPetMouseDown);
        els.petWrapper.addEventListener("mouseup", onPetMouseUp);
        els.petWrapper.addEventListener("click", (e) => {
            e.stopPropagation();
        });
    }
}
