// ============================================================================
// core/window-fit.js — Co giãn cửa sổ khít đúng nội dung (khung chat + pet)
// ----------------------------------------------------------------------------
// Cửa sổ GTK trong suốt nhưng KHÔNG được chiếm một vùng lớn vô ích trên màn
// hình. Module này đo vùng bao (bounding box) của khung chat + chú cún rồi yêu
// cầu tầng C co giãn cửa sổ vừa khít:
//   • mép TRÊN / TRÁI / PHẢI sát khung chat
//   • mép DƯỚI sát đáy chú cún
//
// Cơ chế:
//   • Đo bằng offset* (kích thước LAYOUT, không phụ thuộc transform/animation).
//   • Mọi phần tử neo theo góc dưới-phải ⇒ đổi kích thước không làm nội dung
//     nhảy, và kết quả đo KHÔNG phụ thuộc kích thước cửa sổ (không vòng lặp).
//   • Khi mở bảng thiết lập / màn hình nghỉ dài (overlay toàn màn hình) thì mở
//     rộng cửa sổ ra vùng làm việc; đóng lại thì thu về khung khít.
// ============================================================================

import { els, isHidden } from "./dom.js";
import { native } from "./native.js";

const MIN_WIDTH = 80;
const MIN_HEIGHT = 80;
const MAX_WINDOW_HEIGHT = 864; // khớp MAX_FIT_HEIGHT bên Go
const TOAST_TOP = 20; // khớp .eyeleo-prebreak-toast { top: 20px }
const TOAST_GAP = 6;

const FULL_UI_IDS = [
    "rag-settings-modal",
    "llm-settings-modal",
    "eyeleo-settings-modal",
    "eyeleo-longbreak-overlay",
];

let scheduled = false;
let fullActive = false;
let lastKey = "";

function visible(el) {
    return Boolean(el) && !isHidden(el);
}

function cssNumber(name, fallback) {
    const raw = getComputedStyle(document.documentElement).getPropertyValue(
        name,
    );
    const value = parseFloat(raw);
    return Number.isFinite(value) ? value : fallback;
}

/** Các phần tử tham gia vào vùng khít. */
function fitElements() {
    return [els.petWrapper, els.speechBubble, els.eyeleoShortbreakBubble];
}

/** Các phần tử cần mở rộng cửa sổ (overlay toàn màn hình). */
function fullUiElements() {
    return FULL_UI_IDS.map((id) => document.getElementById(id));
}

function anyFullUi() {
    return fullUiElements().some(visible);
}

function measure() {
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

    // Thông báo trước giờ nghỉ neo ở top:TOAST_TOP nên phải chừa thêm một
    // khoảng CỐ ĐỊNH phía trên (không lấy theo offsetTop để tránh vòng lặp).
    if (visible(els.eyeleoPrebreakToast)) {
        top -= els.eyeleoPrebreakToast.offsetHeight + TOAST_TOP + TOAST_GAP;
    }

    return {
        width: Math.max(MIN_WIDTH, Math.ceil(right - left) + pad * 2),
        height: Math.max(MIN_HEIGHT, Math.ceil(bottom - top) + pad * 2),
    };
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
    if (key === lastKey) return;
    lastKey = key;
    native.setContentSize(size.width, size.height);
}

// Gộp các thay đổi liên tiếp (streaming làm khung chat cao dần) thành một lần
// co giãn duy nhất mỗi ~90ms để cửa sổ giãn mượt, không rung.
function schedule() {
    if (scheduled) return;
    scheduled = true;
    setTimeout(() => requestAnimationFrame(apply), 90);
}

export function initWindowFit() {
    // Chiều cao tối đa của khung chat tính từ MÀN HÌNH (không dùng vh của cửa
    // sổ, vì cửa sổ co giãn theo nội dung sẽ gây vòng lặp).
    const pad = cssNumber("--fit-pad", 20);
    const petArea = cssNumber("--pet-area", 185);
    const rawAvail = (window.screen && window.screen.availHeight) || 800;
    // Cửa sổ tối đa MAX_WINDOW_HEIGHT px; phần nội dung dài hơn sẽ CUỘN trong
    // khung chat (.bubble-body có overflow-y: auto).
    const maxBubble = Math.max(
        180,
        Math.floor(
            Math.min(
                rawAvail - petArea - pad * 2 - 40,
                MAX_WINDOW_HEIGHT - petArea - pad * 2,
            ),
        ),
    );
    document.documentElement.style.setProperty(
        "--bubble-max-height",
        `${maxBubble}px`,
    );
    native.log(
        `screen avail=${window.screen.availWidth}x${window.screen.availHeight} => maxBubble=${maxBubble}`,
    );

    if (window.ResizeObserver) {
        const observer = new ResizeObserver(schedule);
        for (const el of fitElements()) {
            if (el) observer.observe(el);
        }
    }

    if (window.MutationObserver) {
        const observer = new MutationObserver(schedule);
        for (const el of [...fitElements(), ...fullUiElements()]) {
            if (el) {
                observer.observe(el, {
                    attributes: true,
                    attributeFilter: ["class", "style"],
                });
            }
        }
        // Nội dung chat lớn dần trong lúc streaming cũng làm khung chat đổi kích thước.
        if (els.chatStream) {
            new MutationObserver(schedule).observe(els.chatStream, {
                childList: true,
                subtree: true,
            });
        }
    }

    window.addEventListener("resize", schedule);
    window.addEventListener("load", schedule);
    if (els.speechBubble) {
        els.speechBubble.addEventListener("transitionend", schedule);
    }

    schedule();
}
