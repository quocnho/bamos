// ============================================================================
// core/audio.js — Chuông thư giãn tổng hợp bằng Web Audio API
// ----------------------------------------------------------------------------
// Không cần tệp âm thanh: mọi âm thanh được tổng hợp trực tiếp bằng
// Oscillator + GainNode nên nhẹ và không phụ thuộc tài nguyên ngoài.
// ============================================================================

// AudioContext được tạo muộn (lazy) và tái sử dụng cho mọi lần phát chuông.
let audioCtx = null;

function context() {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return null;
    if (!audioCtx) audioCtx = new AudioCtx();
    if (audioCtx.state === "suspended") audioCtx.resume();
    return audioCtx;
}

/** Chuông bát xoay Tây Tạng: quét 528Hz -> 1056Hz, tắt dần êm ái. */
function playBell(ctx, now) {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = "sine";
    osc.frequency.setValueAtTime(528, now);
    osc.frequency.exponentialRampToValueAtTime(1056, now + 0.35);

    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 1.6);

    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 1.6);
}

/** Hai tiếng "ting" nhẹ nhàng báo hoàn thành kỳ nghỉ. */
function playFinish(ctx, now) {
    [587.33, 880].forEach((freq, index) => {
        const startAt = now + index * 0.18;
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();

        osc.type = "triangle";
        osc.frequency.setValueAtTime(freq, startAt);
        gain.gain.setValueAtTime(0.2, startAt);
        gain.gain.exponentialRampToValueAtTime(0.001, startAt + 0.8);

        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(startAt);
        osc.stop(startAt + 0.8);
    });
}

/**
 * Phát chuông thư giãn.
 * @param {'bell'|'finish'} type Loại âm thanh.
 * @param {boolean} enabled Người dùng có bật âm thanh hay không.
 */
export function playChime(type = "bell", enabled = true) {
    if (!enabled) return;
    try {
        const ctx = context();
        if (!ctx) return;
        const now = ctx.currentTime;
        if (type === "finish") {
            playFinish(ctx, now);
        } else {
            playBell(ctx, now);
        }
    } catch (err) {
        console.warn("[BamAI Audio] Không thể phát âm thanh:", err);
    }
}
