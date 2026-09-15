/**
 * BamOS Assistant Widget Logic
 * - Quản lý gửi nhận tin nhắn với Backend qua SSE (/api/chat/stream)
 * - Giao tiếp với Host page thông qua window.parent.postMessage
 * - Render Markdown đơn giản, an toàn
 */

// Lấy base URL từ chính trang đang phục vụ iframe này
const API_BASE = window.location.origin;

const messagesContainer = document.getElementById("messages-container");
const chatInput = document.getElementById("chat-input");
const btnSend = document.getElementById("btn-send");
const btnClose = document.getElementById("btn-close");
const btnClear = document.getElementById("btn-clear");
const toggleRag = document.getElementById("toggle-rag");
const modelLabel = document.getElementById("model-label");
const typingStatus = document.getElementById("typing-status");

let chatHistory = [];
let isGenerating = false;

// 1. Tải thông tin bot từ Backend
async function fetchBotInfo() {
    try {
        const res = await fetch(`${API_BASE}/api/info`);
        if (res.ok) {
            const data = await res.json();
            modelLabel.textContent = `${data.model} (Ready)`;
        } else {
            modelLabel.textContent = "SLM Copilot";
        }
    } catch (e) {
        modelLabel.textContent = "Offline";
    }
}
fetchBotInfo();

// 2. Tự động co giãn chiều cao của Textarea
chatInput.addEventListener("input", function () {
    this.style.height = "auto";
    this.style.height = Math.min(this.scrollHeight, 80) + "px";
});

// 3. Phím Enter để gửi (Shift+Enter để xuống dòng)
chatInput.addEventListener("keydown", function (e) {
    if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
});

btnSend.addEventListener("click", sendMessage);

// 4. Xóa lịch sử
btnClear.addEventListener("click", function () {
    if (isGenerating) return;
    chatHistory = [];
    messagesContainer.innerHTML = `
        <div class="message-row bot">
            <div class="msg-bubble">
                Đã làm mới cuộc hội thoại! Em sẵn sàng hỗ trợ bạn câu hỏi tiếp theo ạ 🐾.
            </div>
        </div>
    `;
});

// 5. Nút đóng -> gửi tín hiệu lên Host Window
btnClose.addEventListener("click", function () {
    window.parent.postMessage({ type: "BAMOS_WIDGET_CLOSE" }, "*");
});

// 6. Gửi tin nhắn và xử lý SSE Stream
async function sendMessage() {
    const text = chatInput.value.trim();
    if (!text || isGenerating) return;

    // Reset input
    chatInput.value = "";
    chatInput.style.height = "auto";
    isGenerating = true;
    btnSend.disabled = true;
    typingStatus.textContent = "Đang suy nghĩ...";

    // Render User message
    appendMessage("user", text);

    // Chuẩn bị Bot message container
    const botRow = appendMessage("bot", "");
    const botBubble = botRow.querySelector(".msg-bubble");
    botBubble.classList.add("typing-cursor");

    let fullResponse = "";

    try {
        const response = await fetch(`${API_BASE}/api/chat/stream`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                question: text,
                use_rag: toggleRag.checked,
                history: chatHistory.slice(-6), // Gửi 6 turn gần nhất
            }),
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const reader = response.body.getReader();
        const decoder = new TextDecoder("utf-8");
        let buffer = "";

        while (true) {
            const { value, done } = await reader.read();
            if (done) break;

            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split("\n");
            buffer = lines.pop() || "";

            for (const line of lines) {
                const trimmed = line.trim();
                if (!trimmed) continue;

                if (trimmed.startsWith("data:")) {
                    const dataStr = trimmed.slice(5).trim();
                    try {
                        const parsed = JSON.parse(dataStr);
                        if (parsed.chunk) {
                            fullResponse += parsed.chunk;
                            botBubble.innerHTML = formatMarkdown(fullResponse);
                            scrollToBottom();
                        }
                        if (parsed.error) {
                            fullResponse += `\n⚠️ *Lỗi:* ${parsed.error}`;
                            botBubble.innerHTML = formatMarkdown(fullResponse);
                        }
                    } catch (e) {
                        // ignore JSON parse error for plain events
                    }
                }
            }
        }

        // Cập nhật lịch sử
        chatHistory.push({ role: "user", content: text });
        chatHistory.push({ role: "assistant", content: fullResponse });

    } catch (err) {
        console.error("Lỗi khi chat với BamOS Widget:", err);
        botBubble.innerHTML = `<span style="color: #EF4444;">⚠️ Không thể kết nối tới BamOS Core: ${err.message}. Hãy chắc chắn Assistant đang chạy trên máy tính.</span>`;
    } finally {
        isGenerating = false;
        btnSend.disabled = false;
        typingStatus.textContent = "";
        botBubble.classList.remove("typing-cursor");
        scrollToBottom();
        chatInput.focus();
    }
}

function appendMessage(role, content) {
    const row = document.createElement("div");
    row.className = `message-row ${role}`;
    
    const bubble = document.createElement("div");
    bubble.className = "msg-bubble";
    bubble.innerHTML = role === "user" ? escapeHtml(content) : formatMarkdown(content);

    row.appendChild(bubble);
    messagesContainer.appendChild(row);
    scrollToBottom();
    return row;
}

function scrollToBottom() {
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
}

function escapeHtml(str) {
    return str
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

/** Format markdown đơn giản (bold, code, codeblock, link, line break) */
function formatMarkdown(text) {
    if (!text) return "";
    let html = escapeHtml(text);

    // Code blocks ```code```
    html = html.replace(/```([a-zA-Z0-9]*)\n([\s\S]*?)```/g, (match, lang, code) => {
        return `<pre><code>${code.trim()}</code></pre>`;
    });

    // Inline code `code`
    html = html.replace(/`([^`]+)`/g, "<code>$1</code>");

    // Bold **text** hoặc <b>
    html = html.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>");

    // List items
    html = html.replace(/^- (.*)$/gim, "• $1");

    // Newlines -> <br> (ngoài pre)
    html = html.replace(/\n/g, "<br>");

    return html;
}

// 7. Lắng nghe trạng thái mở/đóng từ Host page
window.addEventListener("message", function (event) {
    if (event.data && event.data.type === "BAMOS_WIDGET_STATE") {
        if (event.data.open) {
            setTimeout(() => chatInput.focus(), 250);
        }
    }
});
