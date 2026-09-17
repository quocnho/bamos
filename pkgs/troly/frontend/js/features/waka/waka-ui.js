// ============================================================================
// features/wakatracker-ui.js — Giao diện WakaTracker & Lịch nhắc việc
// ============================================================================

import { els, show, hide } from "../../core/dom.js";
import { native } from "../../core/native.js";

export function openWakaModal() {
    show(els.wakaModal);
    refreshWakaStats();
}

function refreshWakaStats() {
    native.wakaStats();
}

export function handleWakaStats(stats) {
    if (!stats || !stats.ok) return;

    if (els.wakaTodayHours) {
        els.wakaTodayHours.textContent = stats.today_hours_text || "0.0 giờ";
    }
    if (els.waka7daysHours) {
        els.waka7daysHours.textContent = stats.seven_days_hours || "0.0 giờ";
    }

    // Render Categories
    const catContainer = els.wakaCategoriesList;
    if (catContainer) {
        catContainer.innerHTML = "";
        const cats = stats.today_categories || {};
        const entries = Object.entries(cats);
        if (entries.length === 0) {
            catContainer.innerHTML = `<div class="model-empty">Chưa có dữ liệu làm việc hôm nay.</div>`;
        } else {
            let total = 0;
            entries.forEach(([_, sec]) => (total += sec));
            entries.forEach(([name, sec]) => {
                const percent = total > 0 ? Math.round((sec / total) * 100) : 0;
                const mins = Math.round(sec / 60);
                const row = document.createElement("div");
                row.style.cssText = "margin-bottom: 6px; font-size: 12px;";
                row.innerHTML = `
                    <div style="display: flex; justify-content: space-between; margin-bottom: 2px;">
                        <span><b>${escapeHtml(name)}</b></span>
                        <span style="color: #64748b;">${mins} phút (${percent}%)</span>
                    </div>
                    <div style="background: #e2e8f0; border-radius: 4px; height: 6px; overflow: hidden;">
                        <div style="background: #2a9d8f; height: 100%; width: ${percent}%;"></div>
                    </div>
                `;
                catContainer.appendChild(row);
            });
        }
    }

    // Render Reminders
    renderReminders(stats.reminders || []);
}

function renderReminders(reminders) {
    const list = els.wakaRemindersList;
    if (!list) return;
    list.innerHTML = "";
    if (reminders.length === 0) {
        list.innerHTML = `<div class="model-empty">Chưa có lời nhắc nào.</div>`;
        return;
    }

    reminders.forEach((r) => {
        const item = document.createElement("div");
        item.style.cssText = "display: flex; align-items: center; justify-content: space-between; background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px 10px; font-size: 12px;";
        const textStyle = r.completed ? "text-decoration: line-through; color: #94a3b8;" : "color: #1e293b; font-weight: 600;";

        item.innerHTML = `
            <div style="display: flex; align-items: center; gap: 8px;">
                <input type="checkbox" ${r.completed ? "checked" : ""} data-rem-id="${r.id}" />
                <span style="${textStyle}">${escapeHtml(r.title)}</span>
                ${r.due_time ? `<span style="font-size: 10.5px; background: rgba(42, 157, 143, 0.1); color: #2a9d8f; padding: 2px 5px; border-radius: 4px;">⏰ ${escapeHtml(r.due_time)}</span>` : ""}
            </div>
            <span style="font-size: 10.5px; color: #94a3b8;">${r.created_at || ""}</span>
        `;

        const chk = item.querySelector("input[type='checkbox']");
        chk.addEventListener("change", () => {
            native.toggleReminder(r.id);
        });

        list.appendChild(item);
    });
}

function addNewReminder() {
    const title = els.wakaNewReminderTitle ? els.wakaNewReminderTitle.value.trim() : "";
    const dueTime = els.wakaNewReminderTime ? els.wakaNewReminderTime.value.trim() : "";
    if (!title) return;

    native.addReminder(title, dueTime);
    if (els.wakaNewReminderTitle) els.wakaNewReminderTitle.value = "";
    if (els.wakaNewReminderTime) els.wakaNewReminderTime.value = "";
    setTimeout(refreshWakaStats, 100);
}

function escapeHtml(str) {
    if (!str) return "";
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

export function initWakaTrackerUI() {
    if (els.btnCloseWaka) {
        els.btnCloseWaka.addEventListener("click", () => hide(els.wakaModal));
    }
    if (els.btnWakaAddReminder) {
        els.btnWakaAddReminder.addEventListener("click", addNewReminder);
    }
    if (els.wakaNewReminderTitle) {
        els.wakaNewReminderTitle.addEventListener("keydown", (e) => {
            if (e.key === "Enter") addNewReminder();
        });
    }
}
