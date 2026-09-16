// ============================================================================
// features/suggestions.js — Chip gợi ý từ khóa + thống kê tần suất
// ----------------------------------------------------------------------------
// • Danh sách chip được dựng ĐỘNG theo tần suất từ khóa người dùng đã hỏi.
// • Bắt đầu từ vài chip mặc định (Bam Info, Phần cứng, Ứng dụng chạy...),
//   sau đó tự học thêm câu hỏi mới và tăng dần số lần hỏi.
// • Rê chuột lên chip sẽ hiện tooltip: câu hỏi đầy đủ + số lần đã hỏi.
//
// Dữ liệu lưu trong localStorage nên giữ nguyên giữa các lần mở ứng dụng.
// ============================================================================

import { els } from "../core/dom.js";
import { bus } from "../core/bus.js";
import { setInputValue, send } from "../chat/chat.js";
import { showTooltip, hideTooltip } from "../core/tooltip.js";

const STORAGE_KEY = "bamai_chip_stats";
const MAX_LEARNED = 12; // số câu hỏi tự học tối đa được lưu
const MAX_VISIBLE = 8; // số chip hiển thị nhiều nhất

// Chip mặc định (đồng thời là mẫu câu hỏi gửi đi).
const SEED_ITEMS = [
    { label: "Bam Info", icon: "⚡", query: "bam info" },
    { label: "Bam Health", icon: "🛡️", query: "bam health" },
    { label: "Phần cứng", icon: "💻", query: "Thông tin phần cứng hệ thống" },
    {
        label: "Ứng dụng chạy",
        icon: "📊",
        query: "Đang chạy những ứng dụng nào",
    },
    {
        label: "Đọc config",
        icon: "📄",
        query: "Đọc file /etc/nixos/configuration.nix",
    },
];

/** @type {Map<string, {label:string, icon:string, query:string, count:number, last:number, seed:boolean}>} */
const items = new Map();

// ---------------------------------------------------------------------------
// Lưu trữ
// ---------------------------------------------------------------------------

function load() {
    let stored = null;
    try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (raw) stored = JSON.parse(raw);
    } catch (err) {
        console.warn("[BamAI chip] Không đọc được thống kê:", err);
    }

    if (!stored || !Array.isArray(stored.items) || stored.items.length === 0) {
        seedDefaults();
        return;
    }
    for (const item of stored.items) {
        if (!item || !item.query) continue;
        items.set(item.query, {
            label: item.label || truncate(item.query),
            icon: item.icon || "🔎",
            query: item.query,
            count: Number(item.count) || 0,
            last: Number(item.last) || 0,
            seed: Boolean(item.seed),
        });
    }
    // Bổ sung lại các chip mặc định bị thiếu (ví dụ sau khi nâng cấp).
    for (const seed of SEED_ITEMS) {
        if (!items.has(seed.query)) {
            items.set(seed.query, { ...seed, count: 0, last: 0, seed: true });
        }
    }
}

function seedDefaults() {
    for (const seed of SEED_ITEMS) {
        items.set(seed.query, { ...seed, count: 0, last: 0, seed: true });
    }
}

function save() {
    try {
        localStorage.setItem(
            STORAGE_KEY,
            JSON.stringify({ version: 1, items: Array.from(items.values()) }),
        );
    } catch (err) {
        console.warn("[BamAI chip] Không lưu được thống kê:", err);
    }
}

// ---------------------------------------------------------------------------
// Học từ khóa
// ---------------------------------------------------------------------------

function normalize(text) {
    return String(text || "")
        .toLowerCase()
        .replace(/\s+/g, " ")
        .trim();
}

function truncate(text, max = 28) {
    const value = String(text || "");
    return value.length > max ? `${value.slice(0, max - 1)}…` : value;
}

/** Tìm chip khớp nhất với câu hỏi; trả về điểm khớp (0 = không khớp). */
function matchScore(question, item) {
    const q = normalize(question);
    const target = normalize(item.query);
    if (!q || !target) return 0;
    if (q === target) return 100;

    // So khớp theo tỉ lệ token chung để nhận diện câu hỏi gần giống.
    const qTokens = new Set(q.split(" ").filter((t) => t.length > 2));
    const targetTokens = target.split(" ").filter((t) => t.length > 2);
    if (targetTokens.length === 0 || qTokens.size === 0) return 0;

    let common = 0;
    for (const token of targetTokens) {
        if (qTokens.has(token)) common++;
    }
    const ratio = common / targetTokens.length;
    if (ratio >= 0.75) return Math.round(60 + ratio * 20);
    return 0;
}

/** Ghi nhận một câu hỏi: tăng tần suất chip khớp hoặc học chip mới. */
export function trackQuestion(question) {
    const text = String(question || "").trim();
    if (text.length < 4) return;

    let best = null;
    let bestScore = 0;
    for (const item of items.values()) {
        const score = matchScore(text, item);
        if (score > bestScore) {
            bestScore = score;
            best = item;
        }
    }

    if (best && bestScore >= 60) {
        best.count += 1;
        best.last = Date.now();
    } else {
        learnQuestion(text);
    }

    save();
    render();
}

function learnQuestion(question) {
    const key = question;
    const existing = items.get(key);
    if (existing) {
        existing.count += 1;
        existing.last = Date.now();
        return;
    }

    items.set(key, {
        label: truncate(question),
        icon: "🔎",
        query: question,
        count: 1,
        last: Date.now(),
        seed: false,
    });

    // Giới hạn số câu hỏi tự học: bỏ mục cũ nhất / ít dùng nhất.
    const learned = Array.from(items.values()).filter((item) => !item.seed);
    if (learned.length > MAX_LEARNED) {
        learned.sort((a, b) => a.count - b.count || a.last - b.last);
        const surplus = learned.length - MAX_LEARNED;
        for (let i = 0; i < surplus; i++) {
            items.delete(learned[i].query);
        }
    }
}

// ---------------------------------------------------------------------------
// Dựng giao diện
// ---------------------------------------------------------------------------

function visibleItems() {
    return Array.from(items.values())
        .sort((a, b) => b.count - a.count || b.last - a.last)
        .slice(0, MAX_VISIBLE);
}

export function render() {
    const container = els.smartChips;
    if (!container) return;

    container.textContent = "";
    for (const item of visibleItems()) {
        const chip = document.createElement("button");
        chip.className = "chip";
        chip.dataset.query = item.query;
        chip.textContent = `${item.icon} ${item.label}`;

        chip.addEventListener("mouseenter", () => {
            const times = item.count > 0 ? ` • đã hỏi ${item.count} lần` : "";
            showTooltip(
                chip,
                `${item.icon} ${item.label}`,
                `${item.query}${times}`,
            );
        });
        chip.addEventListener("mouseleave", hideTooltip);

        container.appendChild(chip);
    }
}

export function initSuggestions() {
    load();
    render();

    // Chip được dựng động → dùng uỷ quyền sự kiện trên container.
    if (els.smartChips) {
        els.smartChips.addEventListener("click", (e) => {
            const chip = e.target.closest(".chip");
            if (!chip) return;
            const query = chip.dataset.query;
            if (!query) return;
            hideTooltip();
            setInputValue(query);
            send();
        });
    }

    // chat.js phát sự kiện này mỗi khi người dùng gửi câu hỏi.
    bus.on("chat:asked", (question) => trackQuestion(question));
}
