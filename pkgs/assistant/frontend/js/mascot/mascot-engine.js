// ============================================================================
// mascot/mascot-engine.js — Trình quản lý Đa Linh Vật & State Machine
// ============================================================================

import { els } from "../core/dom.js";
import { wailsBridge } from "../core/wails-bridge.js";
import { MASCOT_MODELS } from "./models.js";

let currentMascotType = "puppy";

export function getActiveMascot() {
    return currentMascotType;
}

export function setMascot(type) {
    if (!type || !MASCOT_MODELS[type]) type = "puppy";
    currentMascotType = type;

    const wrapper = els.petWrapper || document.getElementById("pet-wrapper");
    if (!wrapper) return;

    // Giữ lại heart-burst và zzz-bubble
    const heart = document.getElementById("heart-burst");
    const zzz = document.getElementById("zzz-bubble");
    const existingSvg = document.getElementById("puppy-svg");

    if (existingSvg) {
        existingSvg.remove();
    }

    const tempDiv = document.createElement("div");
    tempDiv.innerHTML = MASCOT_MODELS[type].trim();
    const newSvg = tempDiv.firstElementChild;

    if (newSvg) {
        wrapper.appendChild(newSvg);
    }
}

export function initMascotEngine() {
    // Lắng nghe sự kiện chuyển đổi linh vật từ giao diện thiết lập
    wailsBridge.on("mascot:change", (newType) => {
        setMascot(newType);
    });
}
