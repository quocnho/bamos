package main

/*
#cgo pkg-config: gtk+-3.0 webkit2gtk-4.1

#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
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
    if (g_app.window != NULL) {
        gtk_window_set_keep_above(GTK_WINDOW(g_app.window), enable);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_set_keep_above(gboolean enable) {
    g_idle_add(do_set_keep_above, GINT_TO_POINTER(enable));
}

static gboolean do_show(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_widget_show_all(g_app.window);
        gtk_window_set_keep_above(GTK_WINDOW(g_app.window), TRUE);
        gtk_window_deiconify(GTK_WINDOW(g_app.window));
        gtk_window_present(GTK_WINDOW(g_app.window));
        GdkWindow *gdk_win = gtk_widget_get_window(g_app.window);
        if (gdk_win != NULL) {
            gdk_window_raise(gdk_win);
            gdk_window_focus(gdk_win, GDK_CURRENT_TIME);
        }
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

static gboolean on_window_map(GtkWidget *widget, GdkEvent *event, gpointer user_data) {
    reposition_to_bottom_right(GTK_WINDOW(widget));
    return FALSE;
}

static gboolean do_fullscreen(gpointer user_data) {
    gboolean enable = GPOINTER_TO_INT(user_data);
    if (g_app.window != NULL) {
        if (enable) {
            gtk_window_fullscreen(GTK_WINDOW(g_app.window));
        } else {
            gtk_window_unfullscreen(GTK_WINDOW(g_app.window));
            reposition_to_bottom_right(GTK_WINDOW(g_app.window));
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
    gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);
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

    // CSS làm trong suốt hoàn toàn khung GtkWindow, loại bỏ mọi bóng mờ Mutter, viền GTK và vệt cuộn
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_data(css,
        "window, decoration, .background, scrolledwindow, viewport, undershoot, overshoot {"
        "  background-color: rgba(0, 0, 0, 0) !important;"
        "  background-image: none !important;"
        "  box-shadow: none !important;"
        "  border: none !important;"
        "  border-width: 0 !important;"
        "  outline: none !important;"
        "  margin: 0 !important;"
        "  padding: 0 !important;"
        "}"
        "undershoot.top, undershoot.bottom, undershoot.left, undershoot.right,"
        "overshoot.top, overshoot.bottom, overshoot.left, overshoot.right {"
        "  background: none !important;"
        "  border: none !important;"
        "  box-shadow: none !important;"
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
        "window.assistantNative = {"
        "  dragWindow: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'drag'})); },"
        "  closeApp: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'close'})); },"
        "  setAlwaysOnTop: function(enable) { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'set_always_on_top', always_on_top: !!enable})); },"
        "  wakeAI: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'wake_ai'})); },"
        "  evaluateSleepOrStop: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'evaluate_sleep_or_stop'})); },"
        "  setContextDir: function(dir) { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'set_directory', directory: dir})); },"
        "  clearContextDir: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'clear_directory'})); },"
        "  getIdleTime: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'get_idle_time'})); },"
        "  activateAndRaise: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'activate_and_raise'})); },"
        "  setFullscreen: function(fs) { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'set_fullscreen', fullscreen: !!fs})); },"
        "  stopGeneration: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'stop'})); },"
        "  ask: function(q, rag) { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'ask', question: q, use_rag: rag})); }"
        "};";

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

    // Định vị ban đầu ở góc dưới bên phải
    reposition_to_bottom_right(GTK_WINDOW(window));

    // Nạp URL giao diện chú cún từ local web server
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), app_url);

    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    gtk_widget_show_all(window);
    reposition_to_bottom_right(GTK_WINDOW(window));
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
	"os/exec"
	"strings"
	"unsafe"
)

//go:embed frontend/*
var frontendFS embed.FS

type NativeMessage struct {
	Action      string `json:"action"`
	Question    string `json:"question"`
	Directory   string `json:"directory"`
	UseRAG      bool   `json:"use_rag"`
	Fullscreen  bool   `json:"fullscreen"`
	AlwaysOnTop bool   `json:"always_on_top"`
}

var globalAI *AIService
var currentCancel context.CancelFunc

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
					escaped := escapeJSString(progressMsg)
					script := fmt.Sprintf("window.onAIWaking && window.onAIWaking('%s');", escaped)
					cScript := C.CString(script)
					C.eval_js_main_thread(cScript)
					C.free(unsafe.Pointer(cScript))
				},
				func() {
					script := "window.onAIReady && window.onAIReady();"
					cScript := C.CString(script)
					C.eval_js_main_thread(cScript)
					C.free(unsafe.Pointer(cScript))
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
						escaped := escapeJSString(chunk)
						script := fmt.Sprintf("window.onAIChunk('%s', %t);", escaped, isFirst)
						isFirst = false
						cScript := C.CString(script)
						C.eval_js_main_thread(cScript)
						C.free(unsafe.Pointer(cScript))
					},
					func() {
						script := "window.onAIDone();"
						cScript := C.CString(script)
						C.eval_js_main_thread(cScript)
						C.free(unsafe.Pointer(cScript))
					},
					func(errMsg string) {
						escaped := escapeJSString(errMsg)
						script := fmt.Sprintf("window.onAIError('%s');", escaped)
						cScript := C.CString(script)
						C.eval_js_main_thread(cScript)
						C.free(unsafe.Pointer(cScript))
					},
				)
			}()
		}
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
			escaped := escapeJSString(dir)
			script := fmt.Sprintf("window.setDirectoryContext && window.setDirectoryContext('%s');", escaped)
			cScript := C.CString(script)
			C.eval_js_main_thread(cScript)
			C.free(unsafe.Pointer(cScript))
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
