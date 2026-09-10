// ============================================================================
// chat/chat.js — Điều khiển hội thoại với AI
// ----------------------------------------------------------------------------
// Chứa toàn bộ logic gửi câu hỏi, nhận phản hồi streaming và cập nhật giao
// diện khung chat. Module này KHÔNG import pet.js; thay vào đó phát sự kiện
// qua bus ("session:ensure-awake", "session:touch") để tránh import vòng.
// ============================================================================

import { els, show, hide } from "../core/dom.js";
import { bus } from "../core/bus.js";
import { setPetState, isRagEnabled, setRagEnabled } from "../core/state.js";
import { native } from "../core/native.js";
import { escapeHtml } from "../core/utils.js";
import { renderVisualMarkdown } from "./markdown.js";
import { createAttachmentManager } from "./attachments.js";

const attachments = createAttachmentManager();

let fullAccumulatedReply = "";

// ---------------------------------------------------------------------------
// Truy vấn nhanh các element động (được tạo lại mỗi lần đổi innerHTML)
// ---------------------------------------------------------------------------
function replyElement() {
    return document.getElementById("current-reply");
}

function scrollToBottom() {
    if (els.chatStream) els.chatStream.scrollTop = els.chatStream.scrollHeight;
}

// ---------------------------------------------------------------------------
// API công khai cho các module khác
// ---------------------------------------------------------------------------

/** Thay toàn bộ nội dung khung chat bằng một khối HTML. */
export function showMessage(html) {
    if (!els.chatStream) return;
    els.chatStream.innerHTML = html;
    scrollToBottom();
}

/** Đặt lại con trỏ vào ô nhập liệu. */
export function focusInput() {
    if (els.chatInput) els.chatInput.focus();
}

/** Đổi placeholder ô nhập liệu. */
export function setPlaceholder(text) {
    if (els.chatInput) els.chatInput.placeholder = text;
}

/** Gán giá trị ô nhập liệu (dùng cho chip gợi ý / kéo thả tệp). */
export function setInputValue(text) {
    if (els.chatInput) els.chatInput.value = text;
}

/** Gửi câu hỏi hiện tại trong ô nhập liệu. Trả về true nếu đã gửi. */
export function send() {
    const attachment = attachments.peek();
    let question = els.chatInput ? els.chatInput.value.trim() : "";

    if (!question && !attachment) return false;

    // Đảm bảo AI đã thức và làm mới bộ đếm nghỉ.
    bus.emit("session:ensure-awake");
    bus.emit("session:touch");

    let displayUserMsg = question;
    if (attachment) {
        attachments.consume();
        if (attachment.type === "image") {
            displayUserMsg = `🖼️ [Đính kèm ảnh: ${attachment.name}] ${question}`;
            question = `[Chủ nhân gửi kèm tệp ảnh ${attachment.name}]\n${question}`;
        } else {
            displayUserMsg = `📄 [Đính kèm file: ${attachment.name}] ${question}`;
            const intro =
                question ||
                `Chủ nhân gửi tệp ${attachment.name}, hãy đọc và phân tích tóm tắt nội dung này nhé!`;
            question = `=== NỘI DUNG TỆP ĐÍNH KÈM: ${attachment.name} ===\n${attachment.content}\n===================================\n${intro}`;
        }
    }

    els.chatInput.value = "";
    fullAccumulatedReply = "";
    show(els.btnStopStream);

    els.chatStream.innerHTML = `
    <div class="user-query"><b>Chủ nhân:</b> ${escapeHtml(displayUserMsg)}</div>
    <div class="ai-reply" id="current-reply"><i>Em đang tra cứu và xử lý...</i></div>
  `;
    scrollToBottom();

    els.statusLabel.textContent = isRagEnabled()
        ? "Đang đọc tri thức..."
        : "Đang suy nghĩ...";
    setPetState("thinking");

    native.ask(question, isRagEnabled());
    return true;
}

// ---------------------------------------------------------------------------
// Callback streaming từ Go backend
// ---------------------------------------------------------------------------

/** AI bắt đầu khởi động (nạp model, RAG...). */
export function handleWaking(progressMsg) {
    els.statusLabel.textContent = progressMsg;
    setPetState("thinking");
}

/** AI + RAG đã sẵn sàng. */
export function handleReady() {
    setPetState("idle");
    els.statusLabel.textContent = "Sẵn sàng phục vụ Chủ nhân!";
    showMessage(`
    <div class="ai-reply">
      ✨ <b>Gâu gâu!</b> Toàn bộ dịch vụ AI và RAG đã sẵn sàng 100%! Chủ nhân hãy hỏi em bất cứ điều gì nhé!
    </div>
  `);
    focusInput();
    bus.emit("session:touch");
}

/** Nhận từng mảnh văn bản trong lúc model trả lời. */
export function handleChunk(chunkText, isFirst) {
    setPetState("talking");
    els.statusLabel.textContent = "Em đang trả lời...";
    show(els.btnStopStream);

    const target = replyElement();
    if (target) {
        if (isFirst || target.querySelector("i")) {
            target.innerHTML = "";
            fullAccumulatedReply = "";
        }
        fullAccumulatedReply += chunkText;
        target.innerHTML = renderVisualMarkdown(fullAccumulatedReply);
        scrollToBottom();
    }
    bus.emit("session:touch");
}

/** Model trả lời xong. */
export function handleDone() {
    setPetState("idle");
    hide(els.btnStopStream);
    els.statusLabel.textContent = "Sẵn sàng phục vụ Chủ nhân!";

    const target = replyElement();
    if (target && fullAccumulatedReply) {
        target.innerHTML = renderVisualMarkdown(fullAccumulatedReply);
    }
    bus.emit("session:touch");
}

/** Có lỗi trong quá trình suy luận. */
export function handleError(errMsg) {
    setPetState("idle");
    hide(els.btnStopStream);
    els.statusLabel.textContent = "Gặp lỗi rồi!";

    const target = replyElement();
    if (target) {
        target.innerHTML = `<span style="color: #E53E3E; font-weight: bold;">Lỗi: ${escapeHtml(errMsg)}</span>`;
    }
    bus.emit("session:touch");
}

// ---------------------------------------------------------------------------
// Hành động trên giao diện
// ---------------------------------------------------------------------------

function toggleRag() {
    setRagEnabled(!isRagEnabled());
    applyRagUi();
    focusInput();
}

function applyRagUi() {
    const enabled = isRagEnabled();
    els.btnRagToggle.classList.toggle("active", enabled);
    els.ragBadge.classList.toggle("off", !enabled);
    els.ragBadge.textContent = enabled ? "📚 RAG" : "⚡ LLM";
}

function stopGeneration(e) {
    if (e) e.stopPropagation();
    console.log("[BamAI] Chủ nhân yêu cầu dừng cưỡng chế câu trả lời...");
    native.stopGeneration();
    hide(els.btnStopStream);
    setPetState("idle");
    els.statusLabel.textContent = "Đã dừng câu trả lời theo yêu cầu";

    const target = replyElement();
    if (target) {
        target.innerHTML +=
            '<div style="color: #E76F51; font-size: 11.5px; margin-top: 6px;"><i>⏹ (Đã dừng trả lời)</i></div>';
    }
    bus.emit("session:touch");
}

// ---------------------------------------------------------------------------
// Khởi tạo
// ---------------------------------------------------------------------------
export function initChat() {
    attachments.bind();

    els.btnSend.addEventListener("click", send);

    els.chatInput.addEventListener("keydown", (e) => {
        if (e.key === "Enter") send();
    });

    // Click/focus ô chat: đánh thức AI nếu cần và làm mới bộ đếm nghỉ.
    els.chatInput.addEventListener("focus", () => {
        bus.emit("session:ensure-awake");
        bus.emit("session:touch");
    });

    els.btnRagToggle.addEventListener("click", toggleRag);
    els.btnStopStream.addEventListener("click", stopGeneration);

    applyRagUi();
}
