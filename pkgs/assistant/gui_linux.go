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

static void setup_window_and_webview(const char *app_url) {
    gtk_init(NULL, NULL);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    g_app.window = window;

    gtk_window_set_title(GTK_WINDOW(window), "BamOS Mascot Assistant");
    gtk_window_set_default_size(GTK_WINDOW(window), 420, 520);
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

    // CSS làm trong suốt hoàn toàn khung GtkWindow, loại bỏ mọi bóng mờ Mutter & viền GTK
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_data(css,
        "window, decoration, .background, scrolledwindow, viewport {"
        "  background-color: rgba(0, 0, 0, 0);"
        "  background-image: none;"
        "  box-shadow: none;"
        "  border: none;"
        "  outline: none;"
        "  margin: 0;"
        "  padding: 0;"
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
        "  wakeAI: function() { window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify({action: 'wake_ai'})); },"
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

    // Định vị cún ở góc dưới bên phải màn hình (tương thích Wayland & X11)
    GdkDisplay *display = gdk_display_get_default();
    if (display != NULL) {
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
            int posX = workarea.x + workarea.width - 440;
            int posY = workarea.y + workarea.height - 540;
            if (posX < 0) posX = 50;
            if (posY < 0) posY = 50;
            gtk_window_move(GTK_WINDOW(window), posX, posY);
        }
    }

    // Nạp URL giao diện chú cún từ local web server
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), app_url);

    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    gtk_widget_show_all(window);
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
	"net/http"
	"net/http/httptest"
	"strings"
	"unsafe"
)

//go:embed frontend/*
var frontendFS embed.FS

type NativeMessage struct {
	Action   string `json:"action"`
	Question string `json:"question"`
	UseRAG   bool   `json:"use_rag"`
}

var globalAI *AIService

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
		C.trigger_window_close()
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
	case "ask":
		if globalAI != nil {
			go func() {
				isFirst := true
				globalAI.AskStream(
					context.Background(),
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

func StartUI(ai *AIService) {
	globalAI = ai

	subFS, err := fs.Sub(frontendFS, "frontend")
	if err != nil {
		fmt.Printf("[BamAI GUI] Lỗi đọc thư mục frontend: %v\n", err)
		return
	}

	// Khởi tạo HTTP server nội bộ nạp trọn bộ frontend với MIME type đầy đủ
	server := httptest.NewServer(http.FileServer(http.FS(subFS)))
	defer server.Close()

	cURL := C.CString(server.URL)
	defer C.free(unsafe.Pointer(cURL))

	C.setup_window_and_webview(cURL)
	C.run_main_loop()
}
