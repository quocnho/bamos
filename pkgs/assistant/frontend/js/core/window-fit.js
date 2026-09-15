// ============================================================================
// core/window-fit.js — Co giãn cửa sổ khít đúng nội dung
// ----------------------------------------------------------------------------
// Cửa sổ GTK trong suốt nhưng KHÔNG được chiếm một vùng lớn vô ích. Module đo
// vùng bao (bounding box) của:
//   • khung chat + chú cún (neo góc dưới-phải), và
//   • THẺ của mọi bảng thiết lập đang mở (cũng neo góc dưới-phải),
// rồi yêu cầu tầng C co giãn vừa khít. Vì mọi phần tử cùng neo một góc, kết quả
// đo KHÔNG phụ thuộc kích thước cửa sổ ⇒ không vòng lặp và không nhảy vị trí.
//
// Tầng C giữ cố định góc dưới-phải (mốc neo đã lưu khi người dùng kéo thả), nên
// mở/đóng bảng thiết lập chỉ làm cửa sổ LỚN/NHỎ ra mà chú cún đứng yên.
//
// Chỉ overlay THỰC SỰ toàn màn hình (màn hình nghỉ dài) mới mở rộng ra vùng làm
// việc; các bảng thiết lập thì "bám dính" trong cửa sổ chính.
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
];

const MODAL_IDS = [];

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
    const nodes = [
        els.petWrapper,
        els.speechBubble,
        els.eyeleoShortbreakBubble,
    ];

    // Thẻ của mọi bảng thiết lập đang mở (đo thẻ, KHÔNG đo lớp phủ nền vì lớp
    // phủ phủ kín cửa sổ sẽ gây vòng lặp phụ thuộc kích thước).
    for (const id of MODAL_IDS) {
        const backdrop = document.getElementById(id);
        if (!visible(backdrop)) continue;
        const card = backdrop.querySelector(".modal-card");
        if (card) nodes.push(card);
    }

    return nodes;
}

/** Các phần tử cần mở rộng cửa sổ (overlay toàn màn hình). */
function fullUiElements() {
    return FULL_UI_IDS.map((id) => document.getElementById(id));
}

/**
 * Mọi phần tử cần THEO DÕI thay đổi để đo lại — kể cả phần tử đang ẨN.
 * Quan trọng: phải theo dõi lớp phủ (backdrop) của các bảng ngay từ đầu, nếu chỉ
 * theo dõi phần tử đang hiển thị thì lúc mở bảng sẽ không ai kích hoạt đo lại.
 */
function observeElements() {
    const nodes = [
        els.petWrapper,
        els.speechBubble,
        els.eyeleoShortbreakBubble,
        els.eyeleoPrebreakToast,
        els.chatStream,
    ];

    for (const id of MODAL_IDS) {
        const backdrop = document.getElementById(id);
        if (!backdrop) continue;
        nodes.push(backdrop);
        const card = backdrop.querySelector(".modal-card");
        if (card) nodes.push(card);
    }

    for (const id of FULL_UI_IDS) nodes.push(document.getElementById(id));

    return nodes.filter(Boolean);
}

function anyFullUi() {
    return fullUiElements().some(visible);
}

/** Id các overlay toàn màn hình đang hiển thị (nhật ký chẩn đoán). */
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

// Gộp các thay đổi liên tiếp (streaming làm khung chat cao dần) thành một lần
// co giãn duy nhất mỗi ~90ms để cửa sổ giãn mượt, không rung.
function schedule() {
    if (scheduled) return;
    scheduled = true;
    setTimeout(() => requestAnimationFrame(apply), 90);
}

export function initWindowFit() {
    const pad = cssNumber("--fit-pad", 20);
    const petArea = cssNumber("--pet-area", 185);
    const rawAvail = (window.screen && window.screen.availHeight) || 800;

    // Chiều cao tối đa của khung chat tính từ MÀN HÌNH (không dùng vh của cửa
    // sổ, vì cửa sổ co giãn theo nội dung sẽ gây vòng lặp).
    const maxBubble = Math.max(
        180,
        Math.floor(rawAvail - petArea - pad * 2 - 40),
    );
    document.documentElement.style.setProperty(
        "--bubble-max-height",
        `${maxBubble}px`,
    );

    // Bề rộng màn hình (không phụ thuộc kích thước cửa sổ) để giới hạn bề rộng
    // thẻ bảng — dùng 100vw sẽ khiến thẻ co theo cửa sổ và phải co giãn nhiều bước.
    document.documentElement.style.setProperty(
        "--screen-width",
        `${window.screen.availWidth}px`,
    );

    // Chiều cao tối đa của THÂN bảng thiết lập: mở rộng theo toàn bộ màn hình,
    // trừ lề an toàn để người dùng cuộn xem thoải mái.
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

    const observed = observeElements();

    if (window.ResizeObserver) {
        const observer = new ResizeObserver(schedule);
        for (const el of observed) observer.observe(el);
    }

    if (window.MutationObserver) {
        const observer = new MutationObserver(schedule);
        for (const el of observed) {
            observer.observe(el, {
                attributes: true,
                attributeFilter: ["class", "style"],
            });
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
