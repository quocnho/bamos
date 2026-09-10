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
        GdkDevice *device = gdk_seat_get_pointer(seat);
        gint x, y;
        gdk_device_get_position(device, NULL, &x, &y);
        gtk_window_begin_move_drag(GTK_WINDOW(g_app.window), 1, x, y, GDK_CURRENT_TIME);
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

static void setup_window_and_webview(const char *html_content, const char *base_uri) {
    gtk_init(NULL, NULL);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    g_app.window = window;

    gtk_window_set_title(GTK_WINDOW(window), "BamOS Mascot Assistant");
    gtk_window_set_default_size(GTK_WINDOW(window), 380, 480);
    gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
    gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window), TRUE);

    // Bật Visual RGBA trong suốt
    GdkScreen *screen = gtk_window_get_screen(GTK_WINDOW(window));
    GdkVisual *visual = gdk_screen_get_rgba_visual(screen);
    if (visual != NULL && gdk_screen_is_composited(screen)) {
        gtk_widget_set_visual(window, visual);
    }

    // CSS làm trong suốt hoàn toàn khung GtkWindow
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_data(css,
        "window, .background { background-color: rgba(0, 0, 0, 0); background-image: none; box-shadow: none; border: none; }",
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

    // Tắt thanh cuộn mặc định của webview
    GtkWidget *scrolled = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolled), GTK_POLICY_NEVER, GTK_POLICY_NEVER);
    gtk_container_add(GTK_CONTAINER(scrolled), webview);
    gtk_container_add(GTK_CONTAINER(window), scrolled);

    // Định vị cún ở góc dưới bên phải màn hình
    GdkRectangle workarea;
    gdk_monitor_get_workarea(gdk_display_get_primary_monitor(gdk_display_get_default()), &workarea);
    int posX = workarea.x + workarea.width - 400;
    int posY = workarea.y + workarea.height - 500;
    if (posX < 0) posX = 50;
    if (posY < 0) posY = 50;
    gtk_window_move(GTK_WINDOW(window), posX, posY);

    // Nạp HTML giao diện chú cún
    webkit_web_view_load_html(WEBKIT_WEB_VIEW(webview), html_content, base_uri);

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

	// Khởi tạo HTTP file server nội bộ để WebKit nạp css, svg, js đồng bộ
	server := httptest.NewServer(http.FileServer(http.FS(frontendFS)))
	defer server.Close()

	htmlBytes, err := frontendFS.ReadFile("frontend/index.html")
	if err != nil {
		fmt.Printf("[BamAI GUI] Lỗi đọc index.html: %v\n", err)
		return
	}

	cHTML := C.CString(string(htmlBytes))
	defer C.free(unsafe.Pointer(cHTML))

	baseURI := server.URL + "/frontend/"
	cBaseURI := C.CString(baseURI)
	defer C.free(unsafe.Pointer(cBaseURI))

	C.setup_window_and_webview(cHTML, cBaseURI)
	C.run_main_loop()
}
