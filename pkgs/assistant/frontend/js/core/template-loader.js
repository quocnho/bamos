// ============================================================================
// core/template-loader.js — Nạp các components giao diện vào #app-container
// ============================================================================

const TEMPLATES = [
    "templates/eyeleo/prebreak-toast.html",
    "templates/eyeleo/shortbreak-bubble.html",
    "templates/eyeleo/longbreak-overlay.html",
    "templates/chat-bubble.html",
    "templates/modals/modal-rag.html",
    "templates/modals/modal-llm.html",
    "templates/modals/modal-eyeleo.html",
    "templates/modals/modal-recent.html",
    "templates/modals/modal-about.html",
    "templates/modals/modal-system.html",
    "templates/modals/modal-waka.html",
    "templates/modals/modal-profile.html",
    "templates/modals/modal-embed.html",
    "templates/modals/modal-domain-editor.html",
    "templates/modals/modal-appearance.html",
    "templates/mascot-puppy.html",
];

export async function loadTemplates(containerId = "app-container") {
    const container = document.getElementById(containerId);
    if (!container) return;

    const fetches = TEMPLATES.map(async (path) => {
        try {
            const resp = await fetch(path);
            if (!resp.ok) {
                console.error(`[BamAI] Lỗi tải template ${path}: ${resp.status}`);
                return "";
            }
            return await resp.text();
        } catch (err) {
            console.error(`[BamAI] Ngoại lệ nạp template ${path}:`, err);
            return "";
        }
    });

    const htmlParts = await Promise.all(fetches);
    
    // Gắn trực tiếp trước các phần tử tĩnh ngoài khung (như chip-tooltip, settings-menu)
    const refNode = document.getElementById("chip-tooltip") || container.firstChild;
    const tempDiv = document.createElement("div");
    tempDiv.innerHTML = htmlParts.join("\n");

    while (tempDiv.firstChild) {
        if (refNode && refNode.parentNode === container) {
            container.insertBefore(tempDiv.firstChild, refNode);
        } else {
            container.appendChild(tempDiv.firstChild);
        }
    }
}
