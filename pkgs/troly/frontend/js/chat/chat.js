// ============================================================================
// chat/chat.js — Điều khiển hội thoại với AI (Clean & Modularized)
// ============================================================================

import { els, show, hide } from "../core/dom.js";
import { bus } from "../core/bus.js";
import { setPetState, isRagEnabled, getAddressing } from "../core/state.js";
import { native } from "../core/native.js";
import { escapeHtml } from "../core/utils.js";
import { renderVisualMarkdown } from "./markdown.js";
import { createAttachmentManager } from "./attachments.js";
import { welcomeBlock, userBlock, aiBlock } from "./chat-render.js";
import { handleStreamClick } from "./chat-actions.js";
import {
    appendTurn,
    currentHistory,
    getCurrentSession,
    nextTurnIndex,
} from "./sessions.js";

const attachments = createAttachmentManager();
let fullAccumulatedReply = "";
let streamSessionId = null;

function streamBelongsToCurrentSession() {
    return !streamSessionId || getCurrentSession().id === streamSessionId;
}

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

export function showMessage(html) {
    appendHtml(html);
}

export function focusInput() {
    if (els.headChatInput) {
        els.headChatInput.focus();
    } else if (els.chatInput) {
        els.chatInput.focus();
    }
}

export function setPlaceholder(text) {
    if (els.chatInput) els.chatInput.placeholder = text;
    if (els.headChatInput) els.headChatInput.placeholder = text;
}

export function setInputValue(text) {
    if (els.chatInput) els.chatInput.value = text;
    if (els.headChatInput) els.headChatInput.value = text;
}

export function renderTranscript() {
    if (!els.chatStream) return;
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

function setSendButtonState(isStreaming) {
    if (els.headBtnSend) {
        if (isStreaming) {
            els.headBtnSend.classList.add("is-stop");
            els.headBtnSend.textContent = "⏹";
            els.headBtnSend.title = "Dừng câu trả lời (Stop)";
        } else {
            els.headBtnSend.classList.remove("is-stop");
            els.headBtnSend.textContent = "➤";
            els.headBtnSend.title = "Gửi yêu cầu";
        }
    }
    if (els.btnStopStream) {
        if (isStreaming) show(els.btnStopStream);
        else hide(els.btnStopStream);
    }
}

export function send() {
    // Nếu đang sinh câu trả lời thì bấm nút sẽ dừng yêu cầu
    if (streamSessionId) {
        stopGeneration();
        return false;
    }

    const attachment = attachments.peek();
    let question = "";
    if (els.headChatInput && els.headChatInput.value.trim()) {
        question = els.headChatInput.value.trim();
        els.headChatInput.value = "";
    } else if (els.chatInput && els.chatInput.value.trim()) {
        question = els.chatInput.value.trim();
    }

    if (!question && !attachment) return false;

    // Mở khung chat ra để hiển thị câu hỏi và lời đáp
    show(els.speechBubble);

    bus.emit("session:ensure-awake");
    bus.emit("session:touch");

    let displayUserMsg = question;
    if (attachment) {
        attachments.consume();
        const userTitle = getAddressing() || "Người dùng";
        if (attachment.type === "image") {
            displayUserMsg = `🖼️ [Đính kèm ảnh: ${attachment.name}] ${question}`;
            question = `[${userTitle} gửi kèm tệp ảnh ${attachment.name}]\n${question}`;
        } else {
            displayUserMsg = `📄 [Đính kèm file: ${attachment.name}] ${question}`;
            const intro = question || `${userTitle} gửi tệp ${attachment.name}, hãy đọc và phân tích tóm tắt nội dung này nhé!`;
            question = `=== NỘI DUNG TỆP ĐÍNH KÈM: ${attachment.name} ===\n${attachment.content}\n===================================\n${intro}`;
        }
    }

    if (els.chatInput) els.chatInput.value = "";
    if (els.headChatInput) els.headChatInput.value = "";
    fullAccumulatedReply = "";
    setSendButtonState(true);

    const history = currentHistory();
    const userIndex = appendTurn("user", displayUserMsg);
    const answerIndex = nextTurnIndex();

    appendHtml(userBlock(displayUserMsg, userIndex));
    appendHtml(aiBlock("", answerIndex, { streaming: true }));

    els.statusLabel.textContent = isRagEnabled() ? "Đang đọc tri thức..." : "Đang suy nghĩ...";
    setPetState("thinking");
    bus.emit("chat:asked", displayUserMsg);

    streamSessionId = getCurrentSession().id;
    native.ask(question, isRagEnabled(), history);
    return true;
}

export function handleWaking(progressMsg) {
    els.statusLabel.textContent = progressMsg;
    setPetState("thinking");
}

export function handleReady(started) {
    setPetState("idle");
    els.statusLabel.textContent = "Sẵn sàng phục vụ";
    if (started) {
        showMessage(`
    <div class="msg msg-ai">
      <div class="msg-body">
        ✨ <b>Gâu gâu!</b> Toàn bộ dịch vụ AI và RAG đã sẵn sàng 100%! ${escapeHtml(getAddressing())} hãy hỏi em bất cứ điều gì nhé!
      </div>
    </div>`);
    }
    focusInput();
    bus.emit("session:touch");
}

export function handleChunk(chunkText, isFirst) {
    if (!streamBelongsToCurrentSession()) return;
    setPetState("talking");
    els.statusLabel.textContent = "Em đang trả lời...";
    setSendButtonState(true);

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
    if (!streamBelongsToCurrentSession()) {
        streamSessionId = null;
        setSendButtonState(false);
        setPetState("idle");
        return;
    }
    streamSessionId = null;
    setPetState("idle");
    setSendButtonState(false);
    els.statusLabel.textContent = "Sẵn sàng phục vụ";

    const target = replyElement();
    if (target && fullAccumulatedReply) {
        target.innerHTML = renderVisualMarkdown(fullAccumulatedReply);
    }
    if (fullAccumulatedReply.trim()) {
        appendTurn("assistant", fullAccumulatedReply);
    }
    bus.emit("session:touch");
}

export function handleError(errMsg) {
    streamSessionId = null;
    setPetState("idle");
    setSendButtonState(false);
    els.statusLabel.textContent = "Gặp lỗi rồi!";
    const target = replyElement();
    if (target) {
        target.innerHTML = `<span style="color: #E53E3E; font-weight: bold;">Lỗi: ${escapeHtml(errMsg)}</span>`;
    }
    bus.emit("session:touch");
}

function stopGeneration(e) {
    if (e) e.stopPropagation();
    native.stopGeneration();
    setSendButtonState(false);
    setPetState("idle");
    els.statusLabel.textContent = "Đã dừng câu trả lời theo yêu cầu";

    const target = replyElement();
    if (target) {
        target.innerHTML += '<div style="color: #E76F51; font-size: 11.5px; margin-top: 6px;"><i>⏹ (Đã dừng trả lời)</i></div>';
    }
    if (fullAccumulatedReply.trim()) appendTurn("assistant", fullAccumulatedReply);
    streamSessionId = null;
    bus.emit("session:touch");
}

export function initChat() {
    attachments.bind();
    if (els.btnSend) els.btnSend.addEventListener("click", send);
    if (els.chatInput) {
        els.chatInput.addEventListener("keydown", (e) => {
            if (e.key === "Enter") send();
        });
        els.chatInput.addEventListener("focus", () => {
            bus.emit("session:ensure-awake");
            bus.emit("session:touch");
        });
    }

    if (els.headBtnSend) els.headBtnSend.addEventListener("click", send);
    if (els.headChatInput) {
        els.headChatInput.addEventListener("keydown", (e) => {
            if (e.key === "Enter") send();
        });
        els.headChatInput.addEventListener("focus", () => {
            bus.emit("session:ensure-awake");
            bus.emit("session:touch");
        });
    }

    if (els.btnStopStream) els.btnStopStream.addEventListener("click", stopGeneration);
    if (els.chatStream) els.chatStream.addEventListener("click", handleStreamClick);
}
