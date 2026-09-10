package main

/*
#cgo pkg-config: gtk+-3.0 webkit2gtk-4.1

#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#include <stdio.h>
#include <stdlib.h>

extern void handleScriptMessage(char* message);

static void on_script_message(WebKitUserContentManager *manager, WebKitJavascriptResult *result, gpointer user_data) {
    JSCValue *val = webkit_javascript_result_get_js_value(result);
    if (jsc_value_is_string(val)) {
        char *str = jsc_value_to_string(val);
        handleScriptMessage(str);
        g_free(str);
    }
}

typedef struct {
    GtkWidget *window;
    GtkWidget *webview;
} AppWidgets;

static AppWidgets g_app;

// ---------------------------------------------------------------------------
// Trạng thái cửa sổ (vị trí + ghim trên cùng)
// ---------------------------------------------------------------------------
static char g_state_path[4096] = {0};
static gboolean g_keep_above = TRUE;
static gboolean g_has_saved_position = FALSE;
static gint g_saved_x = 0;
static gint g_saved_y = 0;
static guint g_save_timeout = 0;

// Đường dẫn file lưu trạng thái cửa sổ (do Go truyền sang).
static void set_window_state_path(const char *path) {
    if (path != NULL) {
        g_strlcpy(g_state_path, path, sizeof(g_state_path));
    }
}

// Vị trí + trạng thái ghim khôi phục từ lần chạy trước.
static void set_initial_geometry(int x, int y, gboolean keep_above) {
    g_saved_x = x;
    g_saved_y = y;
    g_has_saved_position = TRUE;
    g_keep_above = keep_above;
}

// Chỉ đặt trạng thái ghim mặc định (khi chưa có vị trí đã lưu).
static void set_default_keep_above(gboolean keep_above) {
    g_keep_above = keep_above;
}

// Ghi vị trí hiện tại xuống file (chỉ gọi trên luồng GTK).
static gboolean do_save_window_state(gpointer user_data) {
    g_save_timeout = 0;
    if (g_app.window == NULL || g_state_path[0] == '\0') return G_SOURCE_REMOVE;

    gint x = 0, y = 0;
    gtk_window_get_position(GTK_WINDOW(g_app.window), &x, &y);

    // Ghi nhớ để lần map lại cửa sổ không nhảy về vị trí khởi động.
    g_saved_x = x;
    g_saved_y = y;
    g_has_saved_position = TRUE;

    FILE *fp = fopen(g_state_path, "w");
    if (fp != NULL) {
        // CHỈ lưu toạ độ. Trạng thái ghim thuộc về assistant_config.json để
        // tránh hai nguồn sự thật gây kẹt trạng thái.
        fprintf(fp, "{\"x\":%d,\"y\":%d}\n", x, y);
        fclose(fp);
    }
    return G_SOURCE_REMOVE;
}

// Gộp nhiều sự kiện di chuyển liên tiếp thành một lần ghi duy nhất.
static void schedule_save_window_state(void) {
    if (g_state_path[0] == '\0') return;
    if (g_save_timeout != 0) g_source_remove(g_save_timeout);
    g_save_timeout = g_timeout_add(400, do_save_window_state, NULL);
}

static gboolean on_window_configure(GtkWidget *widget, GdkEventConfigure *event, gpointer data) {
    // Bỏ qua toạ độ tổng hợp (-1) mà một số compositor gửi.
    if (event->x >= 0 && event->y >= 0) schedule_save_window_state();
    return FALSE;
}

static gboolean do_eval_js(gpointer user_data) {
    char *script = (char*)user_data;
    if (g_app.webview != NULL) {
        webkit_web_view_evaluate_javascript(WEBKIT_WEB_VIEW(g_app.webview), script, -1, NULL, NULL, NULL, NULL, NULL);
    }
    g_free(script);
    return G_SOURCE_REMOVE;
}

static void eval_js_main_thread(const char *script) {
    g_idle_add(do_eval_js, g_strdup(script));
}

static gboolean do_drag(gpointer user_data) {
    if (g_app.window != NULL) {
        GdkSeat *seat = gdk_display_get_default_seat(gdk_display_get_default());
        if (seat != NULL) {
            GdkDevice *device = gdk_seat_get_pointer(seat);
            if (device != NULL) {
                gint x, y;
                gdk_device_get_position(device, NULL, &x, &y);
                gtk_window_begin_move_drag(GTK_WINDOW(g_app.window), 1, x, y, GDK_CURRENT_TIME);
            }
        }
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_drag() {
    g_idle_add(do_drag, NULL);
}

static gboolean do_close(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_widget_hide(g_app.window);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_close() {
    g_idle_add(do_close, NULL);
}

static gboolean do_set_keep_above(gpointer user_data) {
    gboolean enable = GPOINTER_TO_INT(user_data);
    g_keep_above = enable;
    if (g_app.window != NULL) {
        gtk_window_set_keep_above(GTK_WINDOW(g_app.window), enable);
        // Trên X11/XWayland, cần present lại để compositor áp dụng ngay
        // trạng thái trên-cùng (nếu không, thay đổi chỉ có hiệu lực khi
        // cửa sổ đổi trạng thái).
        if (enable) {
            gtk_window_present(GTK_WINDOW(g_app.window));
        }
    }
    schedule_save_window_state();
    return G_SOURCE_REMOVE;
}

static void trigger_window_set_keep_above(gboolean enable) {
    g_idle_add(do_set_keep_above, GINT_TO_POINTER(enable));
}

static gboolean clear_urgency_hint(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_window_set_urgency_hint(GTK_WINDOW(g_app.window), FALSE);
    }
    return G_SOURCE_REMOVE;
}

static gboolean do_show(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_widget_show_all(g_app.window);
        gtk_window_set_keep_above(GTK_WINDOW(g_app.window), g_keep_above);
        gtk_window_deiconify(GTK_WINDOW(g_app.window));
        gtk_window_present_with_time(GTK_WINDOW(g_app.window), GDK_CURRENT_TIME);
        GdkWindow *gdk_win = gtk_widget_get_window(g_app.window);
        if (gdk_win != NULL) {
            gdk_window_raise(gdk_win);
            gdk_window_focus(gdk_win, GDK_CURRENT_TIME);
        }
        // Nhấp nháy khung + đánh dấu khẩn cấp để compositor/người dùng
        // nhận ra cửa sổ vừa được đưa lên (đặc biệt khi thông báo EyeLeo
        // bật lên lúc đang làm việc ở cửa sổ khác).
        gtk_window_set_urgency_hint(GTK_WINDOW(g_app.window), TRUE);
        g_timeout_add(2500, clear_urgency_hint, NULL);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_show() {
    g_idle_add(do_show, NULL);
}

static gboolean on_window_draw(GtkWidget *widget, cairo_t *cr, gpointer data) {
    // Xóa triệt để nền đệm thành trong suốt tuyệt đối bằng toán tử Cairo CLEAR
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
    return FALSE;
}

static void reposition_to_bottom_right(GtkWindow *window) {
    if (window == NULL) return;
    GdkDisplay *display = gdk_display_get_default();
    if (display == NULL) return;

    GdkMonitor *monitor = gdk_display_get_primary_monitor(display);
    if (monitor == NULL) {
        int n = gdk_display_get_n_monitors(display);
        if (n > 0) {
            monitor = gdk_display_get_monitor(display, 0);
        }
    }
    if (monitor != NULL) {
        GdkRectangle workarea;
        gdk_monitor_get_workarea(monitor, &workarea);
        int winW = 440;
        int winH = 640;
        // Đặt sát góc dưới bên phải màn hình
        int posX = workarea.x + workarea.width - winW - 12;
        int posY = workarea.y + workarea.height - winH - 12;
        if (posX < 0) posX = 0;
        if (posY < 0) posY = 0;
        gtk_window_move(window, posX, posY);
    }
}

// Khôi phục vị trí lần chạy trước; nếu chưa có thì về góc dưới phải.
static void apply_initial_position(GtkWindow *window) {
    if (window == NULL) return;
    if (g_has_saved_position) {
        gtk_window_move(window, g_saved_x, g_saved_y);
    } else {
        reposition_to_bottom_right(window);
    }
}

static gboolean on_window_map(GtkWidget *widget, GdkEvent *event, gpointer user_data) {
    apply_initial_position(GTK_WINDOW(widget));
    return FALSE;
}

static gboolean do_fullscreen(gpointer user_data) {
    gboolean enable = GPOINTER_TO_INT(user_data);
    if (g_app.window != NULL) {
        if (enable) {
            gtk_window_fullscreen(GTK_WINDOW(g_app.window));
        } else {
            gtk_window_unfullscreen(GTK_WINDOW(g_app.window));
            apply_initial_position(GTK_WINDOW(g_app.window));
        }
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_fullscreen(gboolean enable) {
    g_idle_add(do_fullscreen, GINT_TO_POINTER(enable));
}

static void setup_window_and_webview(const char *app_url) {
    gtk_init(NULL, NULL);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    g_app.window = window;

    gtk_window_set_title(GTK_WINDOW(window), "BamOS Mascot Assistant");
    gtk_window_set_default_size(GTK_WINDOW(window), 440, 640);
    gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
    gtk_window_set_keep_above(GTK_WINDOW(window), g_keep_above);
    gtk_window_set_type_hint(GTK_WINDOW(window), GDK_WINDOW_TYPE_HINT_UTILITY);
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window), TRUE);
    gtk_widget_set_app_paintable(window, TRUE);

    // Bật Visual RGBA trong suốt
    GdkScreen *screen = gtk_window_get_screen(GTK_WINDOW(window));
    GdkVisual *visual = gdk_screen_get_rgba_visual(screen);
    if (visual != NULL && gdk_screen_is_composited(screen)) {
        gtk_widget_set_visual(window, visual);
    }

    // Kết nối sự kiện draw để xóa sạch nền và bóng viền
    g_signal_connect(window, "draw", G_CALLBACK(on_window_draw), NULL);
    g_signal_connect(window, "map-event", G_CALLBACK(on_window_map), NULL);
    g_signal_connect(window, "configure-event", G_CALLBACK(on_window_configure), NULL);

    // CSS làm trong suốt hoàn toàn khung GtkWindow, loại bỏ mọi bóng mờ Mutter, viền GTK và vệt cuộn.
    // Lưu ý: GTK CSS không hỗ trợ `!important` (sẽ gây cảnh báo "Junk at end of value"),
    // nên các rule dưới đây không dùng `!important`.
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_data(css,
        "window, decoration, .background, scrolledwindow, viewport, undershoot, overshoot {"
        "  background-color: rgba(0, 0, 0, 0);"
        "  background-image: none;"
        "  box-shadow: none;"
        "  border: none;"
        "  border-width: 0;"
        "  outline: none;"
        "  margin: 0;"
        "  padding: 0;"
        "}"
        "undershoot.top, undershoot.bottom, undershoot.left, undershoot.right,"
        "overshoot.top, overshoot.bottom, overshoot.left, overshoot.right {"
        "  background: none;"
        "  border: none;"
        "  box-shadow: none;"
        "}",
        -1, NULL);
    gtk_style_context_add_provider_for_screen(
        screen,
        GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
    );

    // Khởi tạo WebKit User Content Manager và bridge message
    WebKitUserContentManager *manager = webkit_user_content_manager_new();
    webkit_user_content_manager_register_script_message_handler(manager, "assistantNative");
    g_signal_connect(manager, "script-message-received::assistantNative", G_CALLBACK(on_script_message), NULL);

    // Tiêm script shim vào để JS frontend gọi window.assistantNative dễ dàng
    const char *shim =
        "window.assistantNative = (function() {"
        "  function post(obj) {"
        "    window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify(obj));"
        "  }"
        "  return {"
        "    dragWindow: function() { post({action: 'drag'}); },"
        "    closeApp: function() { post({action: 'close'}); },"
        "    setAlwaysOnTop: function(enable) { post({action: 'set_always_on_top', always_on_top: !!enable}); },"
        "    wakeAI: function() { post({action: 'wake_ai'}); },"
        "    evaluateSleepOrStop: function() { post({action: 'evaluate_sleep_or_stop'}); },"
        "    setContextDir: function(dir) { post({action: 'set_directory', directory: dir}); },"
        "    clearContextDir: function() { post({action: 'clear_directory'}); },"
        "    getIdleTime: function() { post({action: 'get_idle_time'}); },"
        "    activateAndRaise: function() { post({action: 'activate_and_raise'}); },"
        "    setFullscreen: function(fs) { post({action: 'set_fullscreen', fullscreen: !!fs}); },"
        "    stopGeneration: function() { post({action: 'stop'}); },"
        "    ask: function(q, rag) { post({action: 'ask', question: q, use_rag: rag}); },"
        // ---- Bảng thiết lập ----
        "    getSettings: function() { post({action: 'get_settings'}); },"
        "    saveSettings: function(settings) { post({action: 'save_settings', payload: settings}); },"
        "    listModels: function() { post({action: 'list_models'}); },"
        "    downloadModel: function(url, name) { post({action: 'download_model', payload: {url: url, name: name}}); },"
        "    setActiveModel: function(path) { post({action: 'set_active_model', payload: {path: path}}); },"
        "    testLLM: function() { post({action: 'test_llm'}); },"
        "    restartAI: function() { post({action: 'restart_ai'}); },"
        // ---- Tri thức RAG ----
        "    ragAddDocuments: function(docs) { post({action: 'rag_add_documents', payload: {documents: docs}}); },"
        "    ragStats: function() { post({action: 'rag_stats'}); },"
        "    ragClear: function() { post({action: 'rag_clear'}); }"
        "  };"
        "})();";

    WebKitUserScript *userScript = webkit_user_script_new(
        shim,
        WEBKIT_USER_CONTENT_INJECT_TOP_FRAME,
        WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START,
        NULL, NULL
    );
    webkit_user_content_manager_add_script(manager, userScript);

    // Khởi tạo WebKit WebView với nền trong suốt
    GtkWidget *webview = webkit_web_view_new_with_user_content_manager(manager);
    g_app.webview = webview;

    GdkRGBA transparent = {0.0, 0.0, 0.0, 0.0};
    webkit_web_view_set_background_color(WEBKIT_WEB_VIEW(webview), &transparent);

    // Tắt thanh cuộn và viền mặc định của ScrolledWindow
    GtkWidget *scrolled = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_shadow_type(GTK_SCROLLED_WINDOW(scrolled), GTK_SHADOW_NONE);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolled), GTK_POLICY_NEVER, GTK_POLICY_NEVER);
    gtk_container_add(GTK_CONTAINER(scrolled), webview);
    gtk_container_add(GTK_CONTAINER(window), scrolled);

    // Định vị ban đầu ở góc dưới bên phải (hoặc vị trí đã lưu)
    apply_initial_position(GTK_WINDOW(window));

    // Nạp URL giao diện chú cún từ local web server
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), app_url);

    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    gtk_widget_show_all(window);
    apply_initial_position(GTK_WINDOW(window));
}

static void run_main_loop() {
    gtk_main();
}
*/
import "C"

import (
	"context"
	"embed"
	"encoding/json"
	"fmt"
	"io/fs"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"strings"
	"unsafe"
)

//go:embed frontend
var frontendFS embed.FS

type NativeMessage struct {
	Action      string          `json:"action"`
	Question    string          `json:"question"`
	Directory   string          `json:"directory"`
	UseRAG      bool            `json:"use_rag"`
	Fullscreen  bool            `json:"fullscreen"`
	AlwaysOnTop bool            `json:"always_on_top"`
	Payload     json.RawMessage `json:"payload"`
}

var globalAI *AIService
var currentCancel context.CancelFunc

// evalJS chạy một đoạn JavaScript trên luồng chính của GTK.
func evalJS(script string) {
	cScript := C.CString(script)
	C.eval_js_main_thread(cScript)
	C.free(unsafe.Pointer(cScript))
}

// pushJSON gọi callback JS kèm dữ liệu JSON (đã escape an toàn).
func pushJSON(callback string, payload any) {
	data, err := json.Marshal(payload)
	if err != nil {
		fmt.Printf("[BamAI GUI] Lỗi marshal %s: %v\n", callback, err)
		return
	}
	evalJS(fmt.Sprintf("window.%s && window.%s(%s);", callback, callback, string(data)))
}

//export handleScriptMessage
func handleScriptMessage(cMessage *C.char) {
	msgStr := C.GoString(cMessage)
	var msg NativeMessage
	if err := json.Unmarshal([]byte(msgStr), &msg); err != nil {
		fmt.Printf("[BamAI GUI] Lỗi parse message: %v\n", err)
		return
	}

	switch msg.Action {
	case "drag":
		C.trigger_window_drag()
	case "close":
		// Khi người dùng đóng ứng dụng, tắt sạch mọi dịch vụ AI và RAG
		if globalAI != nil {
			go globalAI.StopAllServices()
		}
		C.trigger_window_close()
	case "set_always_on_top":
		var enable C.gboolean = 0
		if msg.AlwaysOnTop {
			enable = 1
		}
		fmt.Printf("[BamAI GUI] Always-on-top -> %v\n", msg.AlwaysOnTop)
		C.trigger_window_set_keep_above(enable)
	case "activate_and_raise":
		C.trigger_window_show()
	case "stop":
		if currentCancel != nil {
			currentCancel()
			currentCancel = nil
		}
	case "set_fullscreen":
		var enable C.gboolean = 0
		if msg.Fullscreen {
			enable = 1
		}
		C.trigger_window_fullscreen(enable)
	case "get_idle_time":
		go func() {
			idleMs := getMutterIdleTimeMs()
			script := fmt.Sprintf("window.onIdleTimeUpdate && window.onIdleTimeUpdate(%d);", idleMs)
			cScript := C.CString(script)
			C.eval_js_main_thread(cScript)
			C.free(unsafe.Pointer(cScript))
		}()
	case "set_directory":
		if globalAI != nil && globalAI.mem != nil {
			globalAI.mem.SetActiveDirectory(msg.Directory)
		}
	case "clear_directory":
		if globalAI != nil && globalAI.mem != nil {
			globalAI.mem.SetActiveDirectory("")
		}
	case "wake_ai":
		if globalAI != nil {
			go globalAI.StartAIServicesOnDemand(
				func(progressMsg string) {
					pushJSON("onAIWaking", progressMsg)
				},
				func() {
					evalJS("window.onAIReady && window.onAIReady();")
				},
			)
		}
	case "evaluate_sleep_or_stop":
		if globalAI != nil {
			go globalAI.EvaluateAndSleepOrStopAI()
		}
	case "ask":
		if globalAI != nil {
			if currentCancel != nil {
				currentCancel()
			}
			ctx, cancel := context.WithCancel(context.Background())
			currentCancel = cancel

			go func() {
				defer func() {
					currentCancel = nil
				}()
				isFirst := true
				globalAI.AskStream(
					ctx,
					msg.Question,
					msg.UseRAG,
					func(chunk string) {
						evalJS(fmt.Sprintf("window.onAIChunk && window.onAIChunk('%s', %t);", escapeJSString(chunk), isFirst))
						isFirst = false
					},
					func() {
						evalJS("window.onAIDone && window.onAIDone();")
					},
					func(errMsg string) {
						evalJS(fmt.Sprintf("window.onAIError && window.onAIError('%s');", escapeJSString(errMsg)))
					},
				)
			}()
		}

	// ---- Bảng thiết lập (Settings) ----
	case "get_settings":
		go handleGetSettings()
	case "save_settings":
		go handleSaveSettings(msg.Payload)
	case "list_models":
		go handleListModels()
	case "download_model":
		go handleDownloadModel(msg.Payload)
	case "set_active_model":
		go handleSetActiveModel(msg.Payload)
	case "test_llm":
		go handleTestLLM()
	case "restart_ai":
		go handleRestartAI()

	// ---- Tri thức RAG ----
	case "rag_add_documents":
		go handleRagAddDocuments(msg.Payload)
	case "rag_stats":
		go handleRagStats()
	case "rag_clear":
		go handleRagClear()
	}
}

func escapeJSString(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "'", "\\'")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\r", "")
	return s
}

func getMutterIdleTimeMs() int64 {
	cmd := exec.Command("gdbus", "call", "--session", "--dest", "org.gnome.Mutter.IdleMonitor",
		"--object-path", "/org/gnome/Mutter/IdleMonitor/Core",
		"--method", "org.gnome.Mutter.IdleMonitor.GetIdletime")
	out, err := cmd.Output()
	if err != nil {
		return 0
	}
	// Output có định dạng: "(uint64 12345,)"
	s := strings.TrimSpace(string(out))
	s = strings.TrimPrefix(s, "(uint64 ")
	s = strings.TrimSuffix(s, ",)")
	s = strings.TrimSpace(s)
	var val int64
	_, _ = fmt.Sscanf(s, "%d", &val)
	return val
}

func StartUI(ai *AIService) {
	globalAI = ai

	subFS, err := fs.Sub(frontendFS, "frontend")
	if err != nil {
		fmt.Printf("[BamAI GUI] Lỗi đọc thư mục frontend: %v\n", err)
		return
	}

	// Nạp trạng thái cửa sổ (vị trí + ghim trên cùng) từ lần chạy trước.
	applySavedWindowState(ai)

	mux := http.NewServeMux()
	fileServer := http.FileServer(http.FS(subFS))
	mux.Handle("/", fileServer)

	// API nhận bối cảnh thư mục từ Cục Xương (Files Manager / CLI)
	mux.HandleFunc("/api/context-dir", func(w http.ResponseWriter, r *http.Request) {
		dir := r.URL.Query().Get("path")
		if dir != "" {
			if globalAI != nil && globalAI.mem != nil {
				globalAI.mem.SetActiveDirectory(dir)
			}
			evalJS(fmt.Sprintf("window.setDirectoryContext && window.setDirectoryContext('%s');", escapeJSString(dir)))
			C.trigger_window_show()
		}
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","dir":"%s"}`, dir)
	})

	// API hiển thị cún
	mux.HandleFunc("/api/show", func(w http.ResponseWriter, r *http.Request) {
		C.trigger_window_show()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	// Khởi tạo HTTP server nội bộ trên port cố định 9195 (hoặc random nếu bận)
	listener, err := net.Listen("tcp", "127.0.0.1:9195")
	var serverURL string
	if err == nil {
		server := &http.Server{Handler: mux}
		go func() {
			_ = server.Serve(listener)
		}()
		serverURL = "http://127.0.0.1:9195"
	} else {
		// Nếu 9195 bận thì fallback httptest
		fallbackServer := httptest.NewServer(mux)
		defer fallbackServer.Close()
		serverURL = fallbackServer.URL
	}

	cURL := C.CString(serverURL)
	defer C.free(unsafe.Pointer(cURL))

	C.setup_window_and_webview(cURL)
	C.run_main_loop()
}

// windowState là vị trí cửa sổ lưu giữa các lần chạy.
// (Trạng thái ghim nằm trong Config — xem applySavedWindowState.)
type windowState struct {
	X int `json:"x"`
	Y int `json:"y"`
}

// applySavedWindowState đọc vị trí/ghim đã lưu và chuyển sang tầng C trước
// khi tạo cửa sổ. Nếu chưa có (hoặc không hợp lệ) thì dùng mặc định.
func applySavedWindowState(ai *AIService) {
	// Trạng thái ghim lấy từ thiết lập người dùng (nguồn duy nhất); chỉ có
	// toạ độ cửa sổ mới đọc từ window_state.json.
	keepAbove := true
	if ai != nil {
		keepAbove = ai.cfg.AlwaysOnTop
	}

	statePath := getWindowStatePath()
	cPath := C.CString(statePath)
	C.set_window_state_path(cPath)
	C.free(unsafe.Pointer(cPath))

	if data, err := os.ReadFile(statePath); err == nil {
		var st windowState
		if json.Unmarshal(data, &st) == nil && st.X >= 0 && st.Y >= 0 {
			C.set_initial_geometry(C.int(st.X), C.int(st.Y), cBool(keepAbove))
			return
		}
	}

	// Chưa có vị trí đã lưu: giữ vị trí mặc định (góc dưới phải) nhưng vẫn
	// áp dụng trạng thái ghim và sẽ ghi lại vị trí sau này.
	C.set_default_keep_above(cBool(keepAbove))
}

// cBool chuyển bool của Go sang gboolean cho cgo.
func cBool(v bool) C.gboolean {
	if v {
		return 1
	}
	return 0
}
