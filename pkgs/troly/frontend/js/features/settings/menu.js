// ============================================================================
// features/settings/menu.js — Menu sổ xuống của nút Thiết lập ⚙ trên header
// ----------------------------------------------------------------------------
// Mở khi RÊ CHUỘT tới nút hoặc BẤM nút; đóng khi rời chuột, bấm ra ngoài, Esc.
// Bấm vào nút để "ghim" menu mở (không tự đóng khi rời chuột) — bấm lần nữa để
// bỏ ghim.
//
// Menu nằm NGOÀI .bubble (vì .bubble có overflow:hidden nên sẽ bị cắt) và được
// định vị theo toạ độ màn hình của nút ⚙. Menu luôn nằm trong vùng bao của
// khung chat + chú cún nên cửa sổ không cần giãn thêm.
// ============================================================================

import { els, show, hide, isHidden } from "../../core/dom.js";
import { native } from "../../core/native.js";
import { openSettingsPanel } from "./panels.js";

const MENU_GAP = 6; // khoảng cách dưới nút
const EDGE_MARGIN = 8; // chừa mép cửa sổ
const CLOSE_DELAY_MS = 260;

let closeTimer = null;
let pinned = false;

let activeTrigger = null;

function cancelClose() {
    if (closeTimer !== null) {
        clearTimeout(closeTimer);
        closeTimer = null;
    }
}

/** Đặt menu gần nút trigger (header ⚙ hoặc ngực cún ⚙), luôn nằm trong cửa sổ. */
function position() {
    const menu = els.settingsMenu;
    const button = activeTrigger || els.petChestSettingsBtn || els.btnSettings;
    if (!menu || !button) return;

    const rect = button.getBoundingClientRect();
    const width = menu.offsetWidth || 236;
    const height = menu.offsetHeight || 180;
    const maxLeft = Math.max(
        EDGE_MARGIN,
        window.innerWidth - width - EDGE_MARGIN,
    );
    const left = Math.min(Math.max(EDGE_MARGIN, rect.right - width), maxLeft);

    // Nếu trigger là nút ngực cún (ở dưới), mở menu hướng lên trên để không tràn cửa sổ
    if (button === els.petChestSettingsBtn) {
        const top = Math.max(EDGE_MARGIN, rect.top - height - MENU_GAP);
        menu.style.left = `${Math.round(left)}px`;
        menu.style.top = `${Math.round(top)}px`;
    } else {
        menu.style.left = `${Math.round(left)}px`;
        menu.style.top = `${Math.round(rect.bottom + MENU_GAP)}px`;
    }
}

export function openSettingsMenu(trigger) {
    cancelClose();
    if (trigger) activeTrigger = trigger;
    const menu = els.settingsMenu;
    if (!menu) return;
    show(menu);
    if (activeTrigger) activeTrigger.classList.add("active");
    position();
}

export function closeSettingsMenu() {
    cancelClose();
    pinned = false;
    hide(els.settingsMenu);
    if (els.btnSettings) els.btnSettings.classList.remove("active");
    if (els.petChestSettingsBtn) els.petChestSettingsBtn.classList.remove("active");
    activeTrigger = null;
}

function scheduleClose() {
    if (pinned) return;
    cancelClose();
    closeTimer = setTimeout(() => {
        closeTimer = null;
        closeSettingsMenu();
    }, CLOSE_DELAY_MS);
}

export function initSettingsMenu() {
    const button = els.btnSettings;
    const chestButton = els.petChestSettingsBtn;
    const menu = els.settingsMenu;
    if (!menu) return;

    if (button) {
        button.addEventListener("mouseenter", () => {
            if (!pinned) openSettingsMenu(button);
        });
        button.addEventListener("mouseleave", scheduleClose);
        button.addEventListener("click", (e) => {
            e.stopPropagation();
            if (pinned && activeTrigger === button) {
                closeSettingsMenu();
            } else {
                pinned = true;
                openSettingsMenu(button);
            }
        });
    }

    if (chestButton) {
        chestButton.addEventListener("click", (e) => {
            e.stopPropagation();
            if (pinned && activeTrigger === chestButton) {
                closeSettingsMenu();
            } else {
                pinned = true;
                openSettingsMenu(chestButton);
            }
        });
    }

    menu.addEventListener("mouseenter", cancelClose);
    menu.addEventListener("mouseleave", scheduleClose);

    // Bấm một mục: mở bảng tương ứng rồi đóng menu.
    menu.addEventListener("click", (e) => {
        const item = e.target.closest ? e.target.closest("[data-panel]") : null;
        if (!item) return;
        e.stopPropagation();
        closeSettingsMenu();
        openSettingsPanel(item.dataset.panel);
    });

    // Bấm ra ngoài hoặc Escape thì đóng.
    document.addEventListener("click", (e) => {
        if (isHidden(menu)) return;
        if ((button && button.contains(e.target)) || (chestButton && chestButton.contains(e.target)) || menu.contains(e.target)) return;
        closeSettingsMenu();
    });
    document.addEventListener("keydown", (e) => {
        if (e.key === "Escape") closeSettingsMenu();
    });

    // Cửa sổ đổi kích thước (khung chat giãn) làm nút dịch chuyển -> canh lại.
    window.addEventListener("resize", () => {
        if (!isHidden(menu)) position();
    });
}
