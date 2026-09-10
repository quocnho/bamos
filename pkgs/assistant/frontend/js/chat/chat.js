// ============================================================================
// chat/chat.js — Điều khiển hội thoại với AI
// ----------------------------------------------------------------------------
// • Hội thoại được NỐI TIẾP: mỗi câu hỏi/trả lời được THÊM vào khung chat,
//   không xoá các lượt trước (trước đây mỗi lần gửi lại thay thế toàn bộ nội
//   dung nên trông như "phiên mới" và mất mạch hội thoại).
// • Ngữ cảnh gửi cho model suy ra từ transcript của phiên (chat/sessions.js).
// • Mỗi khối có nút sao chép; khối chat cuộn được khi nội dung dài.
//
// Module này KHÔNG import pet.js; phát sự kiện qua bus để tránh import vòng.
// ============================================================================

import { els, show, hide } from "../core/dom.js";
import { bus } from "../core/bus.js";
import { setPetState, isRagEnabled, getAddressing } from "../core/state.js";
import { native } from "../core/native.js";
import { escapeHtml, stripHtml } from "../core/utils.js";
import { copyText } from "../core/clipboard.js";
import { renderVisualMarkdown } from "./markdown.js";
import { createAttachmentManager } from "./attachments.js";
import {
    appendTurn,
    currentHistory,
    getCurrentSession,
    nextTurnIndex,
} from "./sessions.js";

const attachments = createAttachmentManager();

let fullAccumulatedReply = "";
// Phiên đang nhận câu trả lời. Nếu người dùng đổi phiên giữa lúc stream thì
// token/done đến sau sẽ bị bỏ qua để không rơi vào phiên mới.
let streamSessionId = null;

/** Dòng trả lời hiện tại có còn thuộc phiên đang mở không? */
function streamBelongsToCurrentSession() {
    return !streamSessionId || getCurrentSession().id === streamSessionId;
}

// ---------------------------------------------------------------------------
// Truy vấn nhanh các element động (được tạo lại mỗi lần đổi innerHTML)
// ---------------------------------------------------------------------------
function replyElement() {
    return document.getElementById("current-reply");
}

function scrollToBottom() {
    if (els.chatStream) els.chatStream.scrollTop = els.chatStream.scrollHeight;
}

function appendHtml(html) {
    if (!els.chatStream) return;
    els.chatStream.insertAdjacentHTML("beforeend", html);
    scrollToBottom();
}

// ---------------------------------------------------------------------------
// API công khai cho các module khác
// ---------------------------------------------------------------------------

/** Thêm một khối thông báo của hệ thống (không thuộc transcript). */
export function showMessage(html) {
    appendHtml(html);
}

export function focusInput() {
    if (els.chatInput) els.chatInput.focus();
}

export function setPlaceholder(text) {
    if (els.chatInput) els.chatInput.placeholder = text;
}

export function setInputValue(text) {
    if (els.chatInput) els.chatInput.value = text;
}

// ---------------------------------------------------------------------------
// Dựng khối câu hỏi / câu trả lời
// ---------------------------------------------------------------------------

function welcomeBlock() {
    return `
    <div class="welcome-msg">
      🐶 <b>Xin chào ${escapeHtml(getAddressing())}!</b> Em đang ở đây, sẵn sàng hỗ trợ ạ! Hãy nhấp vào ô chat để bắt đầu nhé!
    </div>`;
}

function userBlock(text, turnIndex) {
    return `
    <div class="msg msg-user" data-turn="${turnIndex}">
      <div class="msg-head">
        <span class="msg-role">🧑 ${escapeHtml(getAddressing())}</span>
        <button class="msg-copy" title="Sao chép câu hỏi">📋</button>
      </div>
      <div class="msg-body">${escapeHtml(text)}</div>
    </div>`;
}

function aiBlock(raw, turnIndex, { streaming = false } = {}) {
    const body = raw
        ? renderVisualMarkdown(raw)
        : "<i>Em đang tra cứu và xử lý...</i>";
    const id = streaming ? ' id="current-reply"' : "";
    const copy = streaming
        ? ""
        : '<button class="msg-copy" title="Sao chép câu trả lời">📋</button>';
    return `
    <div class="msg msg-ai" data-turn="${turnIndex}">
      <div class="msg-head">
        <span class="msg-role">🐶 BamAI</span>
        ${copy}
      </div>
      <div class="msg-body"${id}>${body}</div>
    </div>`;
}

/**
 * Dựng lại toàn bộ khung chat từ transcript của phiên hiện tại.
 * Dùng khi mở lại một phiên cũ hoặc tạo phiên mới.
 */
export function renderTranscript() {
    if (!els.chatStream) return;

    // Vừa chuyển sang phiên khác khi đang trả lời: dừng backend và dọn trạng thái
    // stream cũ để token còn lại không ghi vào phiên mới.
    if (streamSessionId && streamSessionId !== getCurrentSession().id) {
        native.stopGeneration();
        streamSessionId = null;
        fullAccumulatedReply = "";
        hide(els.btnStopStream);
    }

    const transcript = getCurrentSession().transcript;

    if (transcript.length === 0) {
        els.chatStream.innerHTML = welcomeBlock();
        return;
    }

    els.chatStream.innerHTML = transcript
        .map((turn, index) =>
            turn.role === "user"
                ? userBlock(turn.text, index)
                : aiBlock(turn.text, index),
        )
        .join("");
    scrollToBottom();
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

    // Ngữ cảnh = các lượt TRƯỚC đó (chưa gồm câu hỏi này).
    const history = currentHistory();

    // Thêm câu hỏi vào transcript + hiển thị, rồi tạo khối trả lời trống.
    const userIndex = appendTurn("user", displayUserMsg);
    const answerIndex = nextTurnIndex();

    appendHtml(userBlock(displayUserMsg, userIndex));
    appendHtml(aiBlock("", answerIndex, { streaming: true }));

    els.statusLabel.textContent = isRagEnabled()
        ? "Đang đọc tri thức..."
        : "Đang suy nghĩ...";
    setPetState("thinking");

    // Thống kê tần suất từ khóa (features/suggestions.js lắng nghe).
    bus.emit("chat:asked", displayUserMsg);

    streamSessionId = getCurrentSession().id;
    native.ask(question, isRagEnabled(), history);
    return true;
}

// ---------------------------------------------------------------------------
// Callback streaming từ Go backend
// ---------------------------------------------------------------------------

export function handleWaking(progressMsg) {
    els.statusLabel.textContent = progressMsg;
    setPetState("thinking");
}

export function handleReady(started) {
    setPetState("idle");
    els.statusLabel.textContent = "Sẵn sàng phục vụ";
    // Chỉ chào mừng khi VỪA khởi động lại dịch vụ; nếu AI vốn đã chạy (mở lại
    // khung chat) thì im lặng để không spam thông báo.
    if (started) {
        showMessage(`
    <div class="msg msg-ai">
      <div class="msg-body">
        ✨ <b>Gâu gâu!</b> Toàn bộ dịch vụ AI và RAG đã sẵn sàng 100%! ${escapeHtml(getAddressing())} hãy hỏi em bất cứ điều gì nhé!
      </div>
    </div>
  `);
    }
    focusInput();
    bus.emit("session:touch");
}

export function handleChunk(chunkText, isFirst) {
    if (!streamBelongsToCurrentSession()) return;

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

export function handleDone() {
    // Câu trả lời thuộc phiên đã bị đóng → bỏ qua, không ghi vào phiên mới.
    if (!streamBelongsToCurrentSession()) {
        streamSessionId = null;
        hide(els.btnStopStream);
        setPetState("idle");
        return;
    }
    streamSessionId = null;
    setPetState("idle");
    hide(els.btnStopStream);
    els.statusLabel.textContent = "Sẵn sàng phục vụ";

    const target = replyElement();
    if (target && fullAccumulatedReply) {
        target.innerHTML = renderVisualMarkdown(fullAccumulatedReply);
    }
    // Lưu câu trả lời vào phiên (nguồn sự thật cho ngữ cảnh các lượt sau).
    if (fullAccumulatedReply.trim()) {
        appendTurn("assistant", fullAccumulatedReply);
    }
    bus.emit("session:touch");
}

export function handleError(errMsg) {
    streamSessionId = null;
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
// Nút dừng và nút sao chép
// ---------------------------------------------------------------------------

function stopGeneration(e) {
    if (e) e.stopPropagation();
    native.stopGeneration();
    hide(els.btnStopStream);
    setPetState("idle");
    els.statusLabel.textContent = "Đã dừng câu trả lời theo yêu cầu";

    const target = replyElement();
    if (target) {
        target.innerHTML +=
            '<div style="color: #E76F51; font-size: 11.5px; margin-top: 6px;"><i>⏹ (Đã dừng trả lời)</i></div>';
    }
    // Vẫn lưu phần đã trả lời được vào phiên để giữ mạch hội thoại.
    if (fullAccumulatedReply.trim())
        appendTurn("assistant", fullAccumulatedReply);
    streamSessionId = null;
    bus.emit("session:touch");
}

function flashCopy(button, ok) {
    button.classList.toggle("copied", ok);
    button.textContent = ok ? "✅" : "⚠️";
    setTimeout(() => {
        button.classList.remove("copied");
        button.textContent = "📋";
    }, 1200);
}

function onStreamClick(e) {
    const button =
        e.target && e.target.closest ? e.target.closest(".msg-copy") : null;
    if (!button) return;

    const msg = button.closest(".msg");
    const index = msg && msg.dataset ? Number(msg.dataset.turn) : NaN;
    const turn = Number.isInteger(index)
        ? getCurrentSession().transcript[index]
        : null;
    const text = turn ? stripHtml(turn.text) : "";
    if (!text) return;

    copyText(text).then((ok) => flashCopy(button, ok));
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

    els.chatInput.addEventListener("focus", () => {
        bus.emit("session:ensure-awake");
        bus.emit("session:touch");
    });

    els.btnStopStream.addEventListener("click", stopGeneration);
    els.chatStream.addEventListener("click", onStreamClick);
}
