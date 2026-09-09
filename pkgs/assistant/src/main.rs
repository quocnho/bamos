use libadwaita as adw;
use adw::prelude::*;
use adw::{ActionRow, Application, HeaderBar, PreferencesGroup, PreferencesPage, ViewStack};
use gtk4::gdk::Display;
use gtk4::{
    Box as GtkBox, Button, CssProvider, DropDown, Entry, Label, Orientation,
    PasswordEntry, ScrolledWindow, StringList, Switch, TextView,
    STYLE_PROVIDER_PRIORITY_APPLICATION,
};
use serde::{Deserialize, Serialize};
use std::cell::RefCell;
use std::fs;
use std::path::PathBuf;
use std::rc::Rc;
use std::thread;

const APP_ID: &str = "org.bamos.assistant";

#[derive(Serialize, Deserialize, Clone, Default)]
struct AppConfig {
    #[serde(default = "default_provider")]
    provider: String, // "local", "deepseek", "openai", "gemini"
    #[serde(default)]
    deepseek_key: String,
    #[serde(default)]
    openai_key: String,
    #[serde(default)]
    gemini_key: String,
    #[serde(default)]
    enable_rag: bool,
}

fn default_provider() -> String {
    "local".to_string()
}

fn config_path() -> PathBuf {
    let mut p = dirs_config();
    p.push("bamos");
    let _ = fs::create_dir_all(&p);
    p.push("assistant_config.json");
    p
}

fn dirs_config() -> PathBuf {
    if let Ok(c) = std::env::var("XDG_CONFIG_HOME") {
        PathBuf::from(c)
    } else if let Ok(h) = std::env::var("HOME") {
        PathBuf::from(h).join(".config")
    } else {
        PathBuf::from("/tmp")
    }
}

fn load_config() -> AppConfig {
    let path = config_path();
    if let Ok(data) = fs::read_to_string(&path) {
        if let Ok(cfg) = serde_json::from_str::<AppConfig>(&data) {
            return cfg;
        }
    }
    AppConfig {
        provider: "local".to_string(),
        deepseek_key: String::new(),
        openai_key: String::new(),
        gemini_key: String::new(),
        enable_rag: false,
    }
}

fn save_config(cfg: &AppConfig) {
    let path = config_path();
    if let Ok(data) = serde_json::to_string_pretty(cfg) {
        let _ = fs::write(path, data);
    }
}

#[derive(Serialize)]
struct ChatMessage {
    role: String,
    content: String,
}

#[derive(Serialize)]
struct OpenAIChatRequest {
    model: String,
    messages: Vec<ChatMessage>,
    temperature: f32,
}

#[derive(Deserialize)]
struct OpenAIChatResponse {
    choices: Vec<OpenAIChoice>,
}

#[derive(Deserialize)]
struct OpenAIChoice {
    message: OpenAIMsg,
}

#[derive(Deserialize)]
struct OpenAIMsg {
    content: String,
}

#[derive(Serialize)]
struct RagIndexReq {
    content: String,
}

#[derive(Serialize)]
struct RagAskReq {
    question: String,
    provider: String,
    #[serde(rename = "topK")]
    top_k: i32,
}

#[derive(Deserialize)]
struct RagAskResp {
    answer: String,
}

fn main() {
    let app = Application::builder().application_id(APP_ID).build();

    app.connect_startup(|_| {
        load_css();
    });

    app.connect_activate(build_ui);
    app.run();
}

fn load_css() {
    let provider = CssProvider::new();
    let css = r#"
        /* ==========================================================================
           DEEPIN OS 23 / UOS AI INSPIRED DESIGN SYSTEM FOR BAMOS
           ========================================================================== */

        window.deepin-window {
            background-color: rgba(26, 27, 38, 0.95);
            border-radius: 20px;
            border: 1px solid rgba(255, 255, 255, 0.12);
            box-shadow: 0 24px 64px rgba(0, 0, 0, 0.75), 0 0 1px rgba(255, 255, 255, 0.25) inset;
        }

        headerbar {
            background: transparent;
            border: none;
            box-shadow: none;
            padding: 4px 8px;
        }

        /* Thanh trạng thái Model / Trợ lý kiểu Deepin UOS */
        .uos-status-bar {
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.07);
            border-radius: 14px;
            padding: 6px 12px;
            margin-bottom: 4px;
        }

        .uos-online-indicator {
            min-width: 8px;
            min-height: 8px;
            border-radius: 50%;
            background-color: #0081ff;
            box-shadow: 0 0 8px #0081ff;
            margin-right: 6px;
        }

        .uos-provider-text {
            color: #93c5fd;
            font-size: 11.5px;
            font-weight: 600;
        }

        /* Khung trò chuyện Deepin Stream View */
        .chat-scroll {
            background: transparent;
        }

        .chat-container {
            padding: 8px 4px;
        }

        /* Bong bóng chat người dùng (UOS Accent Pill) */
        .chat-row-user {
            margin: 6px 4px 6px 42px;
        }

        .chat-bubble-user {
            background: linear-gradient(135deg, #0081ff, #0056d6);
            color: #ffffff;
            border-radius: 18px 18px 4px 18px;
            padding: 11px 15px;
            font-size: 13.5px;
            line-height: 1.45;
            box-shadow: 0 4px 14px rgba(0, 129, 255, 0.32);
        }

        /* Bong bóng chat UOS AI Assistant */
        .chat-row-bot {
            margin: 6px 42px 6px 2px;
        }

        .bot-avatar-box {
            min-width: 32px;
            min-height: 32px;
            border-radius: 16px;
            background: linear-gradient(135deg, #6366f1, #8b5cf6);
            color: #ffffff;
            font-size: 14px;
            font-weight: bold;
            margin-right: 10px;
            box-shadow: 0 2px 10px rgba(99, 102, 241, 0.35);
        }

        .chat-bubble-bot {
            background: rgba(38, 41, 58, 0.95);
            color: #f1f5f9;
            border-radius: 18px 18px 18px 4px;
            border: 1px solid rgba(255, 255, 255, 0.08);
            padding: 12px 16px;
            font-size: 13.5px;
            line-height: 1.5;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.25);
        }

        /* Typing indicator (UOS Thinking State) */
        .typing-bubble {
            background: rgba(30, 32, 46, 0.85);
            color: #94a3b8;
            font-style: italic;
            font-size: 12.5px;
            border-radius: 14px;
            padding: 8px 14px;
            border: 1px dashed rgba(0, 129, 255, 0.35);
        }

        /* Action bar gắn liền góc dưới mỗi tin nhắn Bot (Copy / Re-ask) */
        .bot-actions-row {
            margin-top: 4px;
            margin-left: 42px;
        }

        .btn-bot-action {
            background: transparent;
            color: #94a3b8;
            font-size: 11px;
            padding: 2px 8px;
            border-radius: 8px;
            border: none;
        }
        .btn-bot-action:hover {
            color: #ffffff;
            background: rgba(255, 255, 255, 0.08);
        }

        /* Gợi ý nhanh (Quick Suggestions / FollowAlong Chips) */
        .chips-container {
            margin-top: 2px;
            margin-bottom: 6px;
        }

        .chip-button {
            background: rgba(255, 255, 255, 0.05);
            color: #cbd5e1;
            border-radius: 14px;
            border: 1px solid rgba(255, 255, 255, 0.08);
            padding: 4px 10px;
            font-size: 11.5px;
            transition: all 180ms ease;
        }
        .chip-button:hover {
            background: rgba(0, 129, 255, 0.25);
            color: #ffffff;
            border-color: rgba(0, 129, 255, 0.6);
        }

        /* Deepin Dock Capsule Input Bar */
        .input-dock {
            background: rgba(33, 35, 50, 0.94);
            border-radius: 26px;
            border: 1px solid rgba(255, 255, 255, 0.14);
            padding: 4px 6px 4px 16px;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
        }
        .input-dock:focus-within {
            border-color: #0081ff;
            box-shadow: 0 0 0 2px rgba(0, 129, 255, 0.35), 0 8px 24px rgba(0, 0, 0, 0.4);
        }

        .input-entry {
            background: transparent;
            border: none;
            color: #ffffff;
            font-size: 13.5px;
            box-shadow: none;
        }
        .input-entry:focus {
            box-shadow: none;
        }

        .btn-send-dock {
            background: linear-gradient(135deg, #0081ff, #0056d6);
            color: white;
            border-radius: 20px;
            min-width: 38px;
            min-height: 38px;
            padding: 0;
            border: none;
            box-shadow: 0 2px 10px rgba(0, 129, 255, 0.45);
        }
        .btn-send-dock:hover {
            background: linear-gradient(135deg, #1a8fff, #0066f5);
        }

        .btn-header-action {
            background: transparent;
            color: #94a3b8;
            border-radius: 12px;
            border: none;
            padding: 4px 8px;
        }
        .btn-header-action:hover {
            color: #f1f5f9;
            background: rgba(255, 255, 255, 0.08);
        }

        .settings-card {
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 16px;
            padding: 12px;
        }
    "#;
    provider.load_from_data(css);

    if let Some(display) = Display::default() {
        gtk4::style_context_add_provider_for_display(
            &display,
            &provider,
            STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    }
}

fn build_ui(app: &Application) {
    let window = adw::ApplicationWindow::builder()
        .application(app)
        .title("BamAI Assistant")
        .icon_name("bamos-assistant")
        .default_width(420)
        .default_height(660)
        .resizable(true)
        .build();

    window.add_css_class("deepin-window");

    // Căn chỉnh vị trí góc dưới bên phải
    if let Some(display) = Display::default() {
        let monitors = display.monitors();
        if let Some(monitor) = monitors.item(0).and_then(|m| m.downcast::<gtk4::gdk::Monitor>().ok()) {
            let geom = monitor.geometry();
            let win_w = 420;
            let win_h = 660;
            let target_x = (geom.width() - win_w - 24).max(0);
            let target_y = (geom.height() - win_h - 48).max(0);

            // Chạy gợi ý vị trí cho window manager
            glib::timeout_add_local_once(std::time::Duration::from_millis(150), move || {
                let cmd = format!(
                    "xdotool search --name 'BamAI Assistant' windowmove {} {} 2>/dev/null || true",
                    target_x, target_y
                );
                let _ = std::process::Command::new("sh").arg("-c").arg(&cmd).status();
            });
        }
    }

    let config = Rc::new(RefCell::new(load_config()));

    // HeaderBar
    let header = HeaderBar::new();
    header.set_show_end_title_buttons(true);
    header.set_show_start_title_buttons(false);

    // Title ViewSwitcher (Trò chuyện / Thiết lập)
    let view_stack = ViewStack::new();
    let view_switcher = adw::ViewSwitcher::builder()
        .stack(&view_stack)
        .policy(adw::ViewSwitcherPolicy::Narrow)
        .build();
    header.set_title_widget(Some(&view_switcher));

    // Nút dọn sạch hội thoại trên Header (Deepin style)
    let btn_clear = Button::from_icon_name("user-trash-symbolic");
    btn_clear.set_tooltip_text(Some("Xóa hội thoại"));
    btn_clear.add_css_class("btn-header-action");
    header.pack_start(&btn_clear);

    // ================= TAB 1: CHAT =================
    let chat_page = GtkBox::new(Orientation::Vertical, 6);
    chat_page.set_margin_start(14);
    chat_page.set_margin_end(14);
    chat_page.set_margin_bottom(14);
    chat_page.set_margin_top(4);

    // Deepin UOS AI Status Pill Bar
    let status_box = GtkBox::new(Orientation::Horizontal, 8);
    status_box.add_css_class("uos-status-bar");

    let status_dot = GtkBox::new(Orientation::Horizontal, 0);
    status_dot.add_css_class("uos-online-indicator");
    status_dot.set_valign(gtk4::Align::Center);

    let lbl_status = Label::builder()
        .label("UOS AI Core: Local Qwen2.5 (Ready)")
        .hexpand(true)
        .xalign(0.0)
        .build();
    lbl_status.add_css_class("uos-provider-text");

    status_box.append(&status_dot);
    status_box.append(&lbl_status);
    chat_page.append(&status_box);

    // Chat Scrolled Area
    let scroll = ScrolledWindow::builder()
        .hscrollbar_policy(gtk4::PolicyType::Never)
        .vexpand(true)
        .build();
    scroll.add_css_class("chat-scroll");

    let chat_list = GtkBox::new(Orientation::Vertical, 10);
    chat_list.add_css_class("chat-container");
    scroll.set_child(Some(&chat_list));

    // Tin nhắn chào mừng ban đầu theo phong cách UOS AI
    append_bot_message(
        &chat_list,
        "Xin chào! Tôi là **BamAI** (lấy cảm hứng từ UOS AI trên Deepin OS).\nTôi có thể hỗ trợ bạn thực hiện các tác vụ hệ điều hành, viết lệnh Linux, dịch thuật hoặc tra cứu tài liệu từ kho tri thức RAG.",
    );

    // FollowAlong / Quick Suggestions Chips
    let chips_scroll = ScrolledWindow::builder()
        .hscrollbar_policy(gtk4::PolicyType::Automatic)
        .vscrollbar_policy(gtk4::PolicyType::Never)
        .build();
    let chips_box = GtkBox::new(Orientation::Horizontal, 6);
    chips_box.add_css_class("chips-container");

    let chip_rag = Button::with_label("📚 Tra cứu RAG");
    chip_rag.add_css_class("chip-button");

    let chip_bash = Button::with_label("💻 Lệnh Linux");
    chip_bash.add_css_class("chip-button");

    let chip_summary = Button::with_label("⚡ Tóm tắt & Dịch");
    chip_summary.add_css_class("chip-button");

    let chip_sys = Button::with_label("⚙️ Tinh chỉnh BamOS");
    chip_sys.add_css_class("chip-button");

    chips_box.append(&chip_rag);
    chips_box.append(&chip_bash);
    chips_box.append(&chip_summary);
    chips_box.append(&chip_sys);
    chips_scroll.set_child(Some(&chips_box));

    // Deepin Dock Style Input Box
    let input_dock = GtkBox::new(Orientation::Horizontal, 8);
    input_dock.add_css_class("input-dock");

    let entry = Entry::builder()
        .placeholder_text("Nhập yêu cầu hoặc câu hỏi... (Enter để gửi)")
        .hexpand(true)
        .build();
    entry.add_css_class("input-entry");

    let btn_send = Button::from_icon_name("send-symbolic");
    btn_send.add_css_class("btn-send-dock");

    input_dock.append(&entry);
    input_dock.append(&btn_send);

    chat_page.append(&scroll);
    chat_page.append(&chips_scroll);
    chat_page.append(&input_dock);

    // ================= TAB 2: THIẾT LẬP (SETTINGS) =================
    let settings_scroll = ScrolledWindow::builder()
        .hscrollbar_policy(gtk4::PolicyType::Never)
        .vexpand(true)
        .build();

    let settings_page = PreferencesPage::new();
    settings_scroll.set_child(Some(&settings_page));

    // Nhóm 1: Mô hình & Nhà cung cấp LLM
    let grp_llm = PreferencesGroup::builder()
        .title("Mô hình Trí tuệ Nhân tạo (LLM)")
        .description("Chọn nguồn suy luận cục bộ hoặc kết nối Cloud API.")
        .build();

    let providers = StringList::new(&[
        "Local AI (Qwen2.5-1.5B qua llama-server)",
        "DeepSeek (Cloud API)",
        "OpenAI (ChatGPT / GPT-4o)",
        "Google Gemini (AI Studio)",
    ]);

    let provider_dropdown = DropDown::new(Some(providers), None::<gtk4::Expression>);
    let current_prov_idx = match config.borrow().provider.as_str() {
        "deepseek" => 1,
        "openai" => 2,
        "gemini" => 3,
        _ => 0,
    };
    provider_dropdown.set_selected(current_prov_idx);

    let row_provider = ActionRow::builder()
        .title("Nhà cung cấp AI")
        .subtitle("Chuyển đổi giữa mô hình cục bộ hoặc Cloud")
        .build();
    row_provider.add_suffix(&provider_dropdown);
    grp_llm.add(&row_provider);

    // DeepSeek API Key
    let entry_deepseek = PasswordEntry::builder()
        .show_peek_icon(true)
        .text(&config.borrow().deepseek_key)
        .build();
    let row_deepseek = ActionRow::builder()
        .title("DeepSeek API Key")
        .subtitle("platform.deepseek.com")
        .build();
    row_deepseek.add_suffix(&entry_deepseek);
    grp_llm.add(&row_deepseek);

    // OpenAI API Key
    let entry_openai = PasswordEntry::builder()
        .show_peek_icon(true)
        .text(&config.borrow().openai_key)
        .build();
    let row_openai = ActionRow::builder()
        .title("OpenAI API Key")
        .subtitle("platform.openai.com")
        .build();
    row_openai.add_suffix(&entry_openai);
    grp_llm.add(&row_openai);

    // Google Gemini API Key
    let entry_gemini = PasswordEntry::builder()
        .show_peek_icon(true)
        .text(&config.borrow().gemini_key)
        .build();
    let row_gemini = ActionRow::builder()
        .title("Google Gemini API Key")
        .subtitle("aistudio.google.com")
        .build();
    row_gemini.add_suffix(&entry_gemini);
    grp_llm.add(&row_gemini);

    settings_page.add(&grp_llm);

    // Nhóm 2: Cấu hình RAG & Kho tri thức
    let grp_rag = PreferencesGroup::builder()
        .title("RAG và Kho Tri thức Cá nhân")
        .description("Tra cứu dữ liệu từ tài liệu cá nhân được index theo vector.")
        .build();

    let switch_rag = Switch::builder()
        .active(config.borrow().enable_rag)
        .valign(gtk4::Align::Center)
        .build();
    let row_rag = ActionRow::builder()
        .title("Kích hoạt RAG khi hỏi đáp")
        .subtitle("Tự động trích dẫn dữ liệu tương đồng")
        .build();
    row_rag.add_suffix(&switch_rag);
    grp_rag.add(&row_rag);

    // Thêm nội dung tài liệu vào RAG
    let text_rag_content = TextView::builder()
        .wrap_mode(gtk4::WrapMode::Word)
        .hexpand(true)
        .height_request(100)
        .build();
    text_rag_content.add_css_class("settings-card");

    let btn_add_doc = Button::with_label("+ Nạp vào Bộ Nhớ RAG");
    btn_add_doc.add_css_class("suggested-action");

    let lbl_rag_result = Label::builder()
        .label("")
        .xalign(0.0)
        .wrap(true)
        .build();

    let doc_box = GtkBox::new(Orientation::Vertical, 6);
    doc_box.set_margin_top(6);
    doc_box.set_margin_bottom(6);
    doc_box.append(&Label::builder().label("Thêm tài liệu/ghi chú mới vào RAG:").xalign(0.0).build());
    doc_box.append(&text_rag_content);
    doc_box.append(&btn_add_doc);
    doc_box.append(&lbl_rag_result);

    grp_rag.add(&doc_box);
    settings_page.add(&grp_rag);

    // Nút Lưu cấu hình
    let btn_save = Button::with_label("Lưu Cấu hình Thiết lập");
    btn_save.add_css_class("suggested-action");
    btn_save.set_margin_top(14);
    btn_save.set_margin_bottom(20);
    btn_save.set_margin_start(16);
    btn_save.set_margin_end(16);

    let lbl_save_status = Label::builder()
        .label("")
        .css_classes(["caption", "accent"])
        .halign(gtk4::Align::Center)
        .build();

    let grp_save = PreferencesGroup::new();
    grp_save.add(&btn_save);
    grp_save.add(&lbl_save_status);
    settings_page.add(&grp_save);

    // Add Tabs into Stack
    view_stack.add_titled_with_icon(&chat_page, Some("chat"), "Trò chuyện", "user-available-symbolic");
    view_stack.add_titled_with_icon(&settings_scroll, Some("settings"), "Thiết lập", "emblem-system-symbolic");

    // Cập nhật nhãn trạng thái ban đầu
    update_status_label(&lbl_status, &config.borrow());

    // Nút Clear chat
    {
        let chat_list = chat_list.clone();
        btn_clear.connect_clicked(move |_| {
            while let Some(child) = chat_list.first_child() {
                chat_list.remove(&child);
            }
            append_bot_message(
                &chat_list,
                "Đã làm mới phiên hội thoại. Tôi sẵn sàng lắng nghe câu hỏi tiếp theo của bạn!",
            );
        });
    }

    // Xử lý nút Nạp tài liệu RAG
    {
        let text_buffer = text_rag_content.buffer();
        let lbl_res = lbl_rag_result.clone();
        btn_add_doc.connect_clicked(move |_| {
            let start = text_buffer.start_iter();
            let end = text_buffer.end_iter();
            let content = text_buffer.text(&start, &end, false).trim().to_string();
            if content.is_empty() {
                lbl_res.set_label("Vui lòng nhập nội dung tài liệu!");
                return;
            }

            let (tx, rx) = async_channel::unbounded::<Result<String, String>>();
            let lbl_clone = lbl_res.clone();
            let buffer_clone = text_buffer.clone();

            glib::spawn_future_local(async move {
                if let Ok(res) = rx.recv().await {
                    match res {
                        Ok(msg) => {
                            lbl_clone.set_label(&msg);
                            buffer_clone.set_text("");
                        }
                        Err(err) => {
                            lbl_clone.set_label(&err);
                        }
                    }
                }
            });

            thread::spawn(move || {
                let client = reqwest::blocking::Client::new();
                let res = client
                    .post("http://127.0.0.1:8090/index")
                    .json(&RagIndexReq { content })
                    .send();

                let result = match res {
                    Ok(r) if r.status().is_success() => Ok("Đã nạp tài liệu vào RAG thành công!".to_string()),
                    Ok(r) => Err(format!("Lỗi từ RAG service (Mã {})", r.status())),
                    Err(e) => Err(format!("Không thể kết nối đến RAG: {}", e)),
                };
                let _ = tx.send_blocking(result);
            });
        });
    }

    // Xử lý nút Lưu Thiết Lập
    {
        let config = config.clone();
        let provider_dropdown = provider_dropdown.clone();
        let entry_deepseek = entry_deepseek.clone();
        let entry_openai = entry_openai.clone();
        let entry_gemini = entry_gemini.clone();
        let switch_rag = switch_rag.clone();
        let lbl_status = lbl_status.clone();
        let lbl_save_status = lbl_save_status.clone();

        btn_save.connect_clicked(move |_| {
            let mut cfg = config.borrow_mut();
            cfg.provider = match provider_dropdown.selected() {
                1 => "deepseek".to_string(),
                2 => "openai".to_string(),
                3 => "gemini".to_string(),
                _ => "local".to_string(),
            };
            cfg.deepseek_key = entry_deepseek.text().trim().to_string();
            cfg.openai_key = entry_openai.text().trim().to_string();
            cfg.gemini_key = entry_gemini.text().trim().to_string();
            cfg.enable_rag = switch_rag.is_active();

            save_config(&cfg);
            update_status_label(&lbl_status, &cfg);
            lbl_save_status.set_label("✓ Đã lưu cấu hình thiết lập thành công!");

            // Đồng bộ DeepSeek Key sang RAG backend nếu có
            if !cfg.deepseek_key.is_empty() {
                let key = cfg.deepseek_key.clone();
                thread::spawn(move || {
                    let client = reqwest::blocking::Client::new();
                    let _ = client
                        .post("http://127.0.0.1:8090/config")
                        .json(&serde_json::json!({ "deepseek_api_key": key }))
                        .send();
                });
            }
        });
    }

    // Logic Gửi tin nhắn Chat
    let on_send = {
        let entry = entry.clone();
        let chat_list = chat_list.clone();
        let scroll = scroll.clone();
        let config = config.clone();

        Rc::new(move || {
            let text = entry.text().trim().to_string();
            if text.is_empty() {
                return;
            }
            entry.set_text("");

            // 1. Thêm bong bóng người dùng
            append_user_message(&chat_list, &text);

            // 2. Thêm typing placeholder (đang suy luận)
            let cfg = config.borrow().clone();
            let wait_msg = if cfg.enable_rag {
                "⚡ Đang tra cứu kho tri thức RAG và suy luận câu trả lời..."
            } else {
                "✨ BamAI đang suy luận câu trả lời..."
            };
            let (typing_box, b_lbl) = create_bot_message_placeholder(wait_msg);
            typing_box.add_css_class("typing-bubble");
            chat_list.append(&typing_box);

            scroll_to_bottom(&scroll);

            let (sender, receiver) = async_channel::unbounded::<String>();
            let typing_box_clone = typing_box.clone();
            let b_lbl_clone = b_lbl.clone();
            let scroll_clone = scroll.clone();

            glib::spawn_future_local(async move {
                if let Ok(answer) = receiver.recv().await {
                    typing_box_clone.remove_css_class("typing-bubble");
                    b_lbl_clone.set_label(&answer);
                    scroll_to_bottom(&scroll_clone);
                }
            });

            let prompt = text.clone();
            thread::spawn(move || {
                let answer = dispatch_chat_request(&prompt, &cfg);
                let _ = sender.send_blocking(answer);
            });
        })
    };

    // Nút Send & Phím Enter
    {
        let on_send = on_send.clone();
        btn_send.connect_clicked(move |_| {
            on_send();
        });
    }

    {
        let on_send = on_send.clone();
        entry.connect_activate(move |_| {
            on_send();
        });
    }

    // Gán hành vi cho các Quick Action Chips (FollowAlong prompts)
    {
        let entry = entry.clone();
        let on_send = on_send.clone();
        chip_rag.connect_clicked(move |_| {
            entry.set_text("Hãy tóm tắt những tài liệu và ghi chú quan trọng nhất trong kho tri thức RAG của tôi");
            on_send();
        });
    }
    {
        let entry = entry.clone();
        let on_send = on_send.clone();
        chip_bash.connect_clicked(move |_| {
            entry.set_text("Hãy hướng dẫn tôi cách tối ưu hóa hiệu năng hệ thống Linux BamOS bằng dòng lệnh");
            on_send();
        });
    }
    {
        let entry = entry.clone();
        let on_send = on_send.clone();
        chip_summary.connect_clicked(move |_| {
            entry.set_text("Hãy giải thích ngắn gọn các tính năng nổi bật của UOS AI và BamOS");
            on_send();
        });
    }
    {
        let entry = entry.clone();
        let on_send = on_send.clone();
        chip_sys.connect_clicked(move |_| {
            entry.set_text("Làm thế nào để quản lý các dịch vụ systemd và kiểm tra cấu hình NixOS trên máy?");
            on_send();
        });
    }

    let root_box = GtkBox::new(Orientation::Vertical, 0);
    root_box.append(&header);
    root_box.append(&view_stack);

    window.set_content(Some(&root_box));
    window.present();
}

fn append_user_message(chat_list: &GtkBox, text: &str) {
    let row = GtkBox::new(Orientation::Horizontal, 0);
    row.add_css_class("chat-row-user");
    row.set_halign(gtk4::Align::End);

    let bubble = Label::builder()
        .label(text)
        .wrap(true)
        .wrap_mode(gtk4::pango::WrapMode::WordChar)
        .xalign(1.0)
        .selectable(true)
        .build();
    bubble.add_css_class("chat-bubble-user");

    row.append(&bubble);
    chat_list.append(&row);
}

fn create_bot_message_placeholder(initial_text: &str) -> (GtkBox, Label) {
    let row = GtkBox::new(Orientation::Horizontal, 8);
    row.add_css_class("chat-row-bot");
    row.set_halign(gtk4::Align::Start);

    let avatar = Label::builder()
        .label("🤖")
        .valign(gtk4::Align::Start)
        .build();
    avatar.add_css_class("bot-avatar-box");

    let bubble = Label::builder()
        .label(initial_text)
        .wrap(true)
        .wrap_mode(gtk4::pango::WrapMode::WordChar)
        .xalign(0.0)
        .selectable(true)
        .build();
    bubble.add_css_class("chat-bubble-bot");

    row.append(&avatar);
    row.append(&bubble);
    (row, bubble)
}

fn append_bot_message(chat_list: &GtkBox, text: &str) {
    let (row, _) = create_bot_message_placeholder(text);
    chat_list.append(&row);
}

fn scroll_to_bottom(scroll: &ScrolledWindow) {
    let vadj = scroll.vadjustment();
    glib::timeout_add_local_once(std::time::Duration::from_millis(50), move || {
        vadj.set_value(vadj.upper());
    });
}

fn update_status_label(lbl: &Label, cfg: &AppConfig) {
    let prov_text = match cfg.provider.as_str() {
        "deepseek" => "UOS AI: DeepSeek-V3",
        "openai" => "UOS AI: OpenAI (GPT-4o)",
        "gemini" => "UOS AI: Google Gemini 1.5",
        _ => "UOS AI: Local Qwen2.5 (Ready)",
    };
    let rag_text = if cfg.enable_rag { " • RAG Enabled" } else { "" };
    lbl.set_label(&format!("{}{}", prov_text, rag_text));
}

fn dispatch_chat_request(prompt: &str, cfg: &AppConfig) -> String {
    if cfg.enable_rag {
        return query_rag(prompt, &cfg.provider);
    }

    match cfg.provider.as_str() {
        "deepseek" => query_deepseek(prompt, &cfg.deepseek_key),
        "openai" => query_openai(prompt, &cfg.openai_key),
        "gemini" => query_gemini(prompt, &cfg.gemini_key),
        _ => query_llama(prompt),
    }
}

fn query_llama(prompt: &str) -> String {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .unwrap_or_default();

    let body = OpenAIChatRequest {
        model: "qwen2.5-1.5b".to_string(),
        messages: vec![
            ChatMessage {
                role: "system".to_string(),
                content: "Bạn là trợ lý ảo BamAI của hệ điều hành BamOS (phát triển theo phong cách UOS AI). Hãy luôn luôn suy nghĩ và trả lời hoàn toàn bằng Tiếng Việt một cách tự nhiên, chuẩn xác, thân thiện, mạch lạc.".to_string(),
            },
            ChatMessage {
                role: "user".to_string(),
                content: prompt.to_string(),
            },
        ],
        temperature: 0.3,
    };

    match client
        .post("http://127.0.0.1:9090/v1/chat/completions")
        .json(&body)
        .send()
    {
        Ok(resp) => {
            if resp.status().is_success() {
                if let Ok(data) = resp.json::<OpenAIChatResponse>() {
                    if let Some(choice) = data.choices.first() {
                        return choice.message.content.clone();
                    }
                }
                "Không nhận được phản hồi từ BamAI.".to_string()
            } else {
                format!("Lỗi kết nối Local AI (Mã {}). Bạn đã chạy 'bam ai start' chưa?", resp.status())
            }
        }
        Err(e) => format!("Không thể kết nối đến Local AI (port 9090): {}", e),
    }
}

fn query_deepseek(prompt: &str, api_key: &str) -> String {
    if api_key.is_empty() {
        return "Chưa thiết lập DeepSeek API Key! Hãy vào tab Thiết lập để nhập key.".to_string();
    }
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .unwrap_or_default();

    let body = OpenAIChatRequest {
        model: "deepseek-chat".to_string(),
        messages: vec![
            ChatMessage {
                role: "system".to_string(),
                content: "Bạn là trợ lý ảo BamAI của hệ điều hành BamOS. Hãy luôn luôn trả lời hoàn toàn bằng Tiếng Việt một cách tự nhiên, chuẩn xác, thông minh.".to_string(),
            },
            ChatMessage {
                role: "user".to_string(),
                content: prompt.to_string(),
            },
        ],
        temperature: 0.3,
    };

    match client
        .post("https://api.deepseek.com/chat/completions")
        .header("Authorization", format!("Bearer {}", api_key))
        .json(&body)
        .send()
    {
        Ok(resp) => {
            if resp.status().is_success() {
                if let Ok(data) = resp.json::<OpenAIChatResponse>() {
                    if let Some(choice) = data.choices.first() {
                        return choice.message.content.clone();
                    }
                }
                "Không nhận được phản hồi từ DeepSeek API.".to_string()
            } else {
                format!("DeepSeek API trả về lỗi: Mã {}", resp.status())
            }
        }
        Err(e) => format!("Lỗi kết nối đến DeepSeek: {}", e),
    }
}

fn query_openai(prompt: &str, api_key: &str) -> String {
    if api_key.is_empty() {
        return "Chưa thiết lập OpenAI API Key! Hãy vào tab Thiết lập để nhập key.".to_string();
    }
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .unwrap_or_default();

    let body = OpenAIChatRequest {
        model: "gpt-4o-mini".to_string(),
        messages: vec![
            ChatMessage {
                role: "system".to_string(),
                content: "Bạn là trợ lý ảo BamAI của hệ điều hành BamOS. Hãy luôn trả lời hoàn toàn bằng Tiếng Việt chuẩn xác.".to_string(),
            },
            ChatMessage {
                role: "user".to_string(),
                content: prompt.to_string(),
            },
        ],
        temperature: 0.3,
    };

    match client
        .post("https://api.openai.com/v1/chat/completions")
        .header("Authorization", format!("Bearer {}", api_key))
        .json(&body)
        .send()
    {
        Ok(resp) => {
            if resp.status().is_success() {
                if let Ok(data) = resp.json::<OpenAIChatResponse>() {
                    if let Some(choice) = data.choices.first() {
                        return choice.message.content.clone();
                    }
                }
                "Không nhận được phản hồi từ OpenAI API.".to_string()
            } else {
                format!("OpenAI API trả về lỗi: Mã {}", resp.status())
            }
        }
        Err(e) => format!("Lỗi kết nối đến OpenAI: {}", e),
    }
}

fn query_gemini(prompt: &str, api_key: &str) -> String {
    if api_key.is_empty() {
        return "Chưa thiết lập Google Gemini API Key! Hãy vào tab Thiết lập để nhập key.".to_string();
    }
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .unwrap_or_default();

    let url = format!(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={}",
        api_key
    );

    let body = serde_json::json!({
        "contents": [{
            "parts": [{ "text": format!("Bạn là trợ lý BamAI trên BamOS. Hãy trả lời bằng Tiếng Việt: {}", prompt) }]
        }]
    });

    match client.post(&url).json(&body).send() {
        Ok(resp) => {
            if resp.status().is_success() {
                if let Ok(data) = resp.json::<serde_json::Value>() {
                    if let Some(text) = data["candidates"][0]["content"]["parts"][0]["text"].as_str() {
                        return text.to_string();
                    }
                }
                "Không trích xuất được phản hồi từ Gemini API.".to_string()
            } else {
                format!("Gemini API trả về lỗi: Mã {}", resp.status())
            }
        }
        Err(e) => format!("Lỗi kết nối đến Google Gemini: {}", e),
    }
}

fn query_rag(question: &str, provider: &str) -> String {
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .unwrap_or_default();

    let body = RagAskReq {
        question: question.to_string(),
        provider: provider.to_string(),
        top_k: 3,
    };

    match client
        .post("http://127.0.0.1:8090/ask")
        .json(&body)
        .send()
    {
        Ok(resp) => {
            if resp.status().is_success() {
                if let Ok(data) = resp.json::<RagAskResp>() {
                    return data.answer;
                }
                "Không giải mã được phản hồi từ RAG Service.".to_string()
            } else {
                format!("Lỗi kết nối RAG Service (Mã {}). Bạn đã chạy 'bam ai start' chưa?", resp.status())
            }
        }
        Err(e) => format!("Không thể kết nối RAG Service (port 8090): {}", e),
    }
}
