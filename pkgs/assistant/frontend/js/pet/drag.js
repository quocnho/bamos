// ============================================================================
// pet/drag.js — Kéo thả cửa sổ & tương tác chuột với chú cún
// ----------------------------------------------------------------------------
// Cửa sổ trong suốt không có thanh tiêu đề, nên ta tự xử lý:
//  - Kéo chú cún hoặc header bong bóng → nhờ Go di chuyển cửa sổ.
//  - Bấm 1 lần vào chú cún            → đánh thức AI.
//  - Bấm đúp (double-click) vào cún   → cho cún ngủ canh nhà.
// ============================================================================

import { els } from "../core/dom.js";
import { native } from "../core/native.js";
import { wake, sleep } from "./pet.js";

const DRAG_THRESHOLD_PX = 5;
const DOUBLE_CLICK_MS = 240;

let dragging = false;
let startX = 0;
let startY = 0;
let clickTimer = null;

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
    dragging = false;
    startX = e.screenX;
    startY = e.screenY;

    const onMouseMove = (moveEvent) => {
        const dx = Math.abs(moveEvent.screenX - startX);
        const dy = Math.abs(moveEvent.screenY - startY);
        if (dx > DRAG_THRESHOLD_PX || dy > DRAG_THRESHOLD_PX) {
            dragging = true;
            window.removeEventListener("mousemove", onMouseMove);
            native.dragWindow();
        }
    };

    const onMouseUp = () => {
        window.removeEventListener("mousemove", onMouseMove);
        window.removeEventListener("mouseup", onMouseUp);
        // Không di chuyển -> coi là một cú click để trò chuyện / đi ngủ.
        if (!dragging) handlePetClick();
    };

    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseup", onMouseUp);
}

function onHeaderMouseDown(e) {
    if (e.target.tagName !== "BUTTON") {
        native.dragWindow();
    }
}

export function initDrag() {
    els.petWrapper.addEventListener("mousedown", onPetMouseDown);
    if (els.bubbleHeader) {
        els.bubbleHeader.addEventListener("mousedown", onHeaderMouseDown);
    }
}
