/**
 * BamOS Assistant - Embeddable Web Widget Loader
 * Chuẩn kiến trúc tương tự Live Helper Chat / Intercom:
 * - Tự động nhận diện host & port từ document.currentScript.src
 * - Tạo fixed container, nút mascot nổi (floating pet trigger)
 * - Tạo iframe cách ly style 100% để hiển thị widget chat
 * - Đồng bộ tương tác hai chiều qua window.postMessage
 */
(function () {
    "use strict";

    if (window.__BAMOS_ASSISTANT_EMBEDDED__) return;
    window.__BAMOS_ASSISTANT_EMBEDDED__ = true;

    // 1. Xác định base URL của máy chủ Assistant (mặc định http://127.0.0.1:9195)
    let baseUrl = "http://127.0.0.1:9195";
    const currentScript = document.currentScript || (function () {
        const scripts = document.getElementsByTagName("script");
        return scripts[scripts.length - 1];
    })();

    let customPos = "";
    let customColor = "";

    if (currentScript) {
        if (currentScript.src) {
            try {
                const parsed = new URL(currentScript.src);
                baseUrl = parsed.origin;
            } catch (e) {
                // fallback
            }
        }
        customPos = currentScript.getAttribute("data-position") || "";
        customColor = currentScript.getAttribute("data-color") || "";
    }

    // 2. Tạo CSS cách ly cho Widget Host container
    const style = document.createElement("style");
    style.id = "bamos-widget-styles";
    style.textContent = `
        #bamos-widget-root {
            position: fixed;
            bottom: 24px;
            right: 24px;
            z-index: 2147483647; /* Đỉnh cao nhất của DOM */
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            pointer-events: none;
        }
        #bamos-widget-root.pos-bottom-left {
            right: auto;
            left: 24px;
            align-items: flex-start;
        }
        #bamos-widget-button {
            width: 62px;
            height: 62px;
            border-radius: 50%;
            background: linear-gradient(135deg, #FF9F43 0%, #EE5253 100%);
            box-shadow: 0 8px 24px rgba(238, 82, 83, 0.4), 0 2px 6px rgba(0,0,0,0.15);
            border: 2.5px solid #FFFFFF;
            cursor: pointer;
            pointer-events: auto;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
            user-select: none;
            outline: none;
        }
        #bamos-widget-button:hover {
            transform: scale(1.08) translateY(-2px);
            box-shadow: 0 12px 28px rgba(238, 82, 83, 0.5), 0 4px 10px rgba(0,0,0,0.2);
        }
        #bamos-widget-button:active {
            transform: scale(0.95);
        }
        #bamos-widget-button .mascot-icon {
            font-size: 30px;
            line-height: 1;
            filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));
            transition: transform 0.3s ease;
        }
        #bamos-widget-button.open .mascot-icon {
            transform: rotate(90deg) scale(0.9);
        }
        #bamos-widget-badge {
            position: absolute;
            top: -2px;
            right: -2px;
            width: 14px;
            height: 14px;
            background: #10B981;
            border: 2px solid #FFFFFF;
            border-radius: 50%;
            box-shadow: 0 0 8px #10B981;
        }
        #bamos-widget-iframe-box {
            width: 380px;
            height: 580px;
            max-width: calc(100vw - 32px);
            max-height: calc(100vh - 110px);
            margin-bottom: 16px;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 16px 40px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(255, 255, 255, 0.15);
            pointer-events: auto;
            transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
            opacity: 0;
            transform: scale(0.85) translateY(20px);
            transform-origin: bottom right;
            display: none;
        }
        #bamos-widget-iframe-box.visible {
            display: block;
            opacity: 1;
            transform: scale(1) translateY(0);
        }
        #bamos-widget-iframe {
            width: 100%;
            height: 100%;
            border: none;
            background: transparent;
        }
        @media (max-width: 480px) {
            #bamos-widget-root {
                bottom: 16px;
                right: 16px;
            }
            #bamos-widget-iframe-box {
                width: calc(100vw - 32px);
                height: calc(100vh - 90px);
            }
        }
    `;
    document.head.appendChild(style);

    // 3. Khởi tạo DOM container
    const root = document.createElement("div");
    root.id = "bamos-widget-root";

    const iframeBox = document.createElement("div");
    iframeBox.id = "bamos-widget-iframe-box";

    const iframe = document.createElement("iframe");
    iframe.id = "bamos-widget-iframe";
    iframe.src = baseUrl + "/widget.html";
    iframe.allow = "clipboard-read; clipboard-write; microphone";
    iframeBox.appendChild(iframe);

    const btn = document.createElement("button");
    btn.id = "bamos-widget-button";
    btn.title = "Trò chuyện với BamOS Mascot Assistant";
    btn.innerHTML = `
        <span class="mascot-icon">🐶</span>
        <span id="bamos-widget-badge" title="AI Sẵn sàng"></span>
    `;

    root.appendChild(iframeBox);
    root.appendChild(btn);

    if (customPos === "bottom-left") {
        root.classList.add("pos-bottom-left");
    }
    if (customColor) {
        btn.style.background = customColor;
    }

    // Thêm vào body khi DOM sẵn sàng
    function attachToDOM() {
        if (document.body) {
            document.body.appendChild(root);
        } else {
            window.addEventListener("DOMContentLoaded", function () {
                document.body.appendChild(root);
            });
        }
    }
    attachToDOM();

    // 4. Trạng thái Toggle & postMessage
    let isOpen = false;

    function toggleWidget(forceState) {
        isOpen = typeof forceState === "boolean" ? forceState : !isOpen;
        if (isOpen) {
            iframeBox.classList.add("visible");
            btn.classList.add("open");
            btn.querySelector(".mascot-icon").textContent = "✕";
            // Gửi thông điệp báo cho iframe biết đã mở
            if (iframe.contentWindow) {
                iframe.contentWindow.postMessage({ type: "BAMOS_WIDGET_STATE", open: true }, "*");
            }
        } else {
            iframeBox.classList.remove("visible");
            btn.classList.remove("open");
            btn.querySelector(".mascot-icon").textContent = "🐶";
            if (iframe.contentWindow) {
                iframe.contentWindow.postMessage({ type: "BAMOS_WIDGET_STATE", open: false }, "*");
            }
        }
    }

    btn.addEventListener("click", function (e) {
        e.stopPropagation();
        toggleWidget();
    });

    // 5. Lắng nghe thông điệp từ Iframe con
    window.addEventListener("message", function (event) {
        if (!event.data || typeof event.data !== "object") return;
        if (event.data.type === "BAMOS_WIDGET_CLOSE") {
            toggleWidget(false);
        } else if (event.data.type === "BAMOS_WIDGET_RESIZE") {
            if (event.data.width && event.data.height) {
                iframeBox.style.width = event.data.width + "px";
                iframeBox.style.height = event.data.height + "px";
            }
        }
    });

    // Xuất API toàn cục để website host có thể gọi bằng Javascript nếu muốn
    window.BamOSWidget = {
        open: function () { toggleWidget(true); },
        close: function () { toggleWidget(false); },
        toggle: function () { toggleWidget(); },
        getBaseUrl: function () { return baseUrl; }
    };
})();
