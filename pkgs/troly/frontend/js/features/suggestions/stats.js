// ============================================================================
// features/suggestions/stats.js — Quản lý lưu trữ & học hỏi tần suất từ khóa
// ============================================================================

const STORAGE_KEY = "bamai_chip_stats";
const MAX_LEARNED = 12; // số câu hỏi tự học tối đa được lưu
const MAX_VISIBLE = 8; // số chip hiển thị nhiều nhất

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
export const items = new Map();

export function loadStats() {
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

export function saveStats() {
    try {
        localStorage.setItem(
            STORAGE_KEY,
            JSON.stringify({ version: 1, items: Array.from(items.values()) }),
        );
    } catch (err) {
        console.warn("[BamAI chip] Không lưu được thống kê:", err);
    }
}

function normalize(text) {
    return String(text || "").toLowerCase().replace(/\s+/g, " ").trim();
}

export function truncate(text, max = 28) {
    const value = String(text || "");
    return value.length > max ? `${value.slice(0, max - 1)}…` : value;
}

function matchScore(question, item) {
    const q = normalize(question);
    const target = normalize(item.query);
    if (!q || !target) return 0;
    if (q === target) return 100;

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

    saveStats();
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

    const learned = Array.from(items.values()).filter((item) => !item.seed);
    if (learned.length > MAX_LEARNED) {
        learned.sort((a, b) => a.count - b.count || a.last - b.last);
        const surplus = learned.length - MAX_LEARNED;
        for (let i = 0; i < surplus; i++) {
            items.delete(learned[i].query);
        }
    }
}

export function visibleItems() {
    return Array.from(items.values())
        .sort((a, b) => b.count - a.count || b.last - a.last)
        .slice(0, MAX_VISIBLE);
}
