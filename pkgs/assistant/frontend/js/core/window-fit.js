// ============================================================================
// core/window-fit.js — Co giãn cửa sổ khít đúng nội dung
// ----------------------------------------------------------------------------
// Cửa sổ GTK trong suốt nhưng KHÔNG được chiếm một vùng lớn vô ích. Module đo
// vùng bao (bounding box) của:
//   • khung chat + chú cún (neo góc dưới-phải),
//   • menu sổ xuống thiết lập (khi mở), và
//   • THẺ của mọi bảng thiết lập đang mở (cũng neo góc dưới-phải),
// rồi yêu cầu tầng C co giãn vừa khít. Vì mọi phần tử cùng neo một góc, kết quả
// đo KHÔNG phụ thuộc kích thước cửa sổ ⇒ không vòng lặp và không nhảy vị trí.
//
// Tầng C giữ cố định góc dưới-phải (mốc neo đã lưu khi người dùng kéo thả), nên
// mở/đóng bảng thiết lập chỉ làm cửa sổ LỚN/NHỎ ra mà chú cún đứng yên.
//
// Khi bất kỳ bảng thiết lập hoặc overlay toàn màn hình nào mở ra, cửa sổ GTK
// lập tức mở rộng ra toàn vùng làm việc (toàn màn hình trong suốt) để hiển thị
// đầy đủ 100% nội dung, không bao giờ bị cắt/che lấp.
// ============================================================================

import { els, isHidden } from "./dom.js";
import { native } from "./native.js";

const MIN_WIDTH = 80;
const MIN_HEIGHT = 80;
const MAX_WINDOW_HEIGHT = 864; // khớp MAX_FIT_HEIGHT bên Go
const TOAST_TOP = 20; // khớp .eyeleo-prebreak-toast { top: 20px }
const TOAST_GAP = 6;
const MODAL_CHROME = 140; // thẻ bảng: tiêu đề + lề dọc (ước lượng an toàn)

// Các bảng thiết lập và overlay: khi mở ra sẽ mở rộng cửa sổ ra toàn vùng làm việc (toàn màn hình trong suốt)
// để không bị giới hạn kích thước, nội dung hiển thị thoải mái và ghim cố định góc dưới bên phải.
const FULL_UI_IDS = [
    "eyeleo-longbreak-overlay",
    "rag-settings-modal",
    "llm-settings-modal",
    "recent-sessions-modal",
    "about-modal",
    "eyeleo-settings-modal",
    "system-inspect-modal",
    "waka-modal",
    "profile-modal",
    "embed-settings-modal",
    "domain-editor-modal",
    "appearance-settings-modal",
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

/** Các phần tử tham gia vào vùng khít khi ở chế độ thông thường. */
function fitElements() {
    const nodes = [
        els.petWrapper,
        els.speechBubble,
        els.eyeleoShortbreakBubble,
    ];

    // Menu thiết lập ⚙ (khi mở sổ xuống)
    const menu = els.settingsMenu || document.getElementById("settings-menu");
    if (visible(menu)) {
        nodes.push(menu);
    }

    return nodes.filter(Boolean);
}

/** Các phần tử cần mở rộng cửa sổ (overlay toàn màn hình hoặc bảng thiết lập). */
function fullUiElements() {
    return FULL_UI_IDS.map((id) => document.getElementById(id)).filter(Boolean);
}

/** Kiểm tra xem có bất kỳ bảng thiết lập hoặc overlay nào đang mở hay không. */
function anyFullUi() {
    // 1. Kiểm tra danh sách id đã biết
    for (const id of FULL_UI_IDS) {
        const el = document.getElementById(id);
        if (visible(el)) return true;
    }
    // 2. Dự phòng an toàn: kiểm tra bất kỳ modal-backdrop nào không có class hidden
    const openModals = document.querySelectorAll(".modal-backdrop:not(.hidden)");
    if (openModals.length > 0) return true;

    return false;
}

/** Id các overlay / modal đang hiển thị (nhật ký chẩn đoán). */
function visibleFullIds() {
    return FULL_UI_IDS.filter((id) => visible(document.getElementById(id)));
}

/** Mô tả ngắn các phần tử đang tham gia vùng khít (nhật ký chẩn đoán). */
function describeFitElements() {
    const parts = [`vp=${window.innerWidth}x${window.innerHeight}`];
    for (const el of fitElements()) {
        if (!visible(el)) continue;
        const rect = el.getBoundingClientRect();
        parts.push(
            `${el.id || el.className.split(" ")[0]}:${Math.round(rect.width)}x${Math.round(rect.height)}@${Math.round(rect.left)},${Math.round(rect.top)}`,
        );
    }
    return parts.join(" | ");
}

function measure() {
    const pad = cssNumber("--fit-pad", 24);

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

// Giới hạn kích thước phía C (do_window_fit) để việc tự kiểm tra không đòi hỏi
// vượt mức (gây resize lặp vô hạn khi màn hình nhỏ).
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
        native.log(`full=${wantFull} [${visibleFullIds().join(", ")}]`);
        native.setWindowFull(wantFull);
    }
    if (fullActive) return;

    const size = measure();
    if (!size) return;

    const key = `${size.width}x${size.height}`;
    // WM có thể đổi kích thước cửa sổ khi ẩn/hiện/thu nhỏ. Nếu kích thước HIỆN
    // TẠI lệch khỏi nội dung (đã tính giới hạn phía C) thì áp lại — nhờ đó chú
    // cún và khung chat luôn khít đúng chỗ sau khi hiện lại.
    const mismatch =
        Math.abs(window.innerWidth - clampWidth(size.width)) > 3 ||
        Math.abs(window.innerHeight - clampHeight(size.height)) > 3;
    if (key === lastKey && !mismatch) return;
    lastKey = key;
    native.log(`fit ${key} :: ${describeFitElements()}`);
    native.setContentSize(size.width, size.height);
}

// Gộp các thay đổi liên tiếp thành một lần co giãn duy nhất mỗi ~60ms
function schedule() {
    if (scheduled) return;
    scheduled = true;
    setTimeout(() => requestAnimationFrame(apply), 60);
}

export function initWindowFit() {
    const pad = cssNumber("--fit-pad", 24);
    const petArea = cssNumber("--pet-area", 185);
    const rawAvail = (window.screen && window.screen.availHeight) || 800;

    // Chiều cao tối đa của khung chat tính từ MÀN HÌNH
    const maxBubble = Math.max(
        180,
        Math.floor(rawAvail - petArea - pad * 2 - 40),
    );
    document.documentElement.style.setProperty(
        "--bubble-max-height",
        `${maxBubble}px`,
    );

    // Bề rộng màn hình
    document.documentElement.style.setProperty(
        "--screen-width",
        `${window.screen.availWidth}px`,
    );

    // Chiều cao tối đa của THÂN bảng thiết lập
    const modalMax = Math.max(
        350,
        Math.floor(rawAvail - MODAL_CHROME - 60),
    );
    document.documentElement.style.setProperty(
        "--modal-max-height",
        `${modalMax}px`,
    );

    native.log(
        `screen avail=${window.screen.availWidth}x${window.screen.availHeight} => maxBubble=${maxBubble} modalMax=${modalMax}`,
    );

    // 1. ResizeObserver trên các khối cơ bản
    const baseNodes = [
        els.petWrapper,
        els.speechBubble,
        els.eyeleoShortbreakBubble,
        els.settingsMenu,
        els.eyeleoPrebreakToast,
    ].filter(Boolean);

    if (window.ResizeObserver) {
        const resizeObserver = new ResizeObserver(schedule);
        for (const el of baseNodes) resizeObserver.observe(el);
    }

    // 2. MutationObserver theo dõi toàn diện trên toàn cây DOM #app-container
    // (Bắt trọn mọi hành động đóng/mở class 'hidden' của modal, menu, bubble)
    const container = document.getElementById("app-container") || document.body;
    if (window.MutationObserver) {
        const domObserver = new MutationObserver((mutations) => {
            schedule();
        });
        domObserver.observe(container, {
            attributes: true,
            attributeFilter: ["class", "style"],
            subtree: true,
            childList: true,
        });
    }

    window.addEventListener("resize", schedule);
    window.addEventListener("load", schedule);
    if (els.speechBubble) {
        els.speechBubble.addEventListener("transitionend", schedule);
    }

    schedule();
}

