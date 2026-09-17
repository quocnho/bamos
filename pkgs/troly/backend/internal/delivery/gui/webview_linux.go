package gui

/*
#cgo pkg-config: gtk4 webkitgtk-6.0

#include <gtk/gtk.h>
#include <webkit/webkit.h>
#include <jsc/jsc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void handleScriptMessage(char* message);

static void on_script_message(WebKitUserContentManager *manager, JSCValue *val, gpointer user_data) {
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

// Chiều cao tối đa của cửa sổ khít (phần dư cuộn trong khung chat)
#define MAX_FIT_HEIGHT 864

static char g_state_path[4096] = {0};
static char g_dock_mode[4] = "BR"; // "BR", "BL", "TR", "TL"
static double g_window_scale = 1.0;
static gboolean g_keep_above = TRUE;
static gboolean g_has_saved_position = FALSE;
static gint g_saved_right = 0;
static gint g_saved_bottom = 0;
static guint g_save_timeout = 0;

static gboolean g_in_full = FALSE;
static gint g_fit_x = 0, g_fit_y = 0, g_fit_w = 0, g_fit_h = 0;
static gint g_pending_w = 0, g_pending_h = 0;

static void get_workarea(GdkRectangle *area) {
    area->x = 0; area->y = 0; area->width = 1920; area->height = 1080;
    GdkDisplay *display = gdk_display_get_default();
    if (display == NULL) return;
    GListModel *monitors = gdk_display_get_monitors(display);
    if (monitors == NULL) return;
    guint n = g_list_model_get_n_items(monitors);
    if (n > 0) {
        GdkMonitor *mon = (GdkMonitor*)g_list_model_get_item(monitors, 0);
        if (mon != NULL) {
            gdk_monitor_get_geometry(mon, area);
            g_object_unref(mon);
        }
    }
}

static void current_workarea_and_scale(int *w, int *h, int *scale) {
    GdkRectangle area;
    get_workarea(&area);
    *w = area.width;
    *h = area.height;
    *scale = 1;
    GdkDisplay *display = gdk_display_get_default();
    if (display != NULL) {
        GListModel *monitors = gdk_display_get_monitors(display);
        if (monitors != NULL && g_list_model_get_n_items(monitors) > 0) {
            GdkMonitor *mon = (GdkMonitor*)g_list_model_get_item(monitors, 0);
            if (mon != NULL) {
                *scale = gdk_monitor_get_scale(mon);
                g_object_unref(mon);
            }
        }
    }
}

static void set_window_state_path(const char *path) {
    if (path != NULL) {
        g_strlcpy(g_state_path, path, sizeof(g_state_path));
    }
}

static void set_dock_position(const char *pos) {
    if (pos != NULL && (strcmp(pos, "BR") == 0 || strcmp(pos, "BL") == 0 ||
                        strcmp(pos, "TR") == 0 || strcmp(pos, "TL") == 0)) {
        g_strlcpy(g_dock_mode, pos, sizeof(g_dock_mode));
    }
}

static void set_window_scale_factor(double factor) {
    if (factor >= 0.5 && factor <= 2.5) {
        g_window_scale = factor;
    }
}

static void calculate_dock_position(int w, int h, int *out_x, int *out_y) {
    GdkRectangle area;
    get_workarea(&area);
    const int margin = 16;

    if (strcmp(g_dock_mode, "TL") == 0) {
        *out_x = area.x + margin;
        *out_y = area.y + margin;
    } else if (strcmp(g_dock_mode, "TR") == 0) {
        *out_x = area.x + area.width - w - margin;
        *out_y = area.y + margin;
    } else if (strcmp(g_dock_mode, "BL") == 0) {
        *out_x = area.x + margin;
        *out_y = area.y + area.height - h - margin;
    } else { // "BR" default
        *out_x = area.x + area.width - w - margin;
        *out_y = area.y + area.height - h - margin;
    }
}

static void apply_initial_position(GtkWindow *win) {
    if (win == NULL) return;
    int x = 0, y = 0;
    int w = g_pending_w > 0 ? g_pending_w : 480;
    int h = g_pending_h > 0 ? g_pending_h : 600;
    calculate_dock_position(w, h, &x, &y);
    gtk_window_set_default_size(win, w, h);
}

static gboolean do_window_fit(gpointer user_data) {
    if (g_app.window == NULL) return G_SOURCE_REMOVE;

    gint w = (gint)(g_pending_w * g_window_scale);
    gint h = (gint)(g_pending_h * g_window_scale);
    if (w < 80) w = 80;
    if (h < 80) h = 80;

    GdkRectangle area;
    get_workarea(&area);
    if (h > MAX_FIT_HEIGHT) h = MAX_FIT_HEIGHT;
    if (h > area.height - 8) h = area.height - 8;
    if (w > area.width - 8) w = area.width - 8;

    gint x = 0, y = 0;
    calculate_dock_position(w, h, &x, &y);

    g_fit_w = w;
    g_fit_h = h;
    g_fit_x = x;
    g_fit_y = y;

    if (!g_in_full) {
        gtk_window_set_default_size(GTK_WINDOW(g_app.window), w, h);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_fit(int w, int h) {
    g_pending_w = w;
    g_pending_h = h;
    g_idle_add(do_window_fit, NULL);
}

static gboolean do_window_set_full(gpointer user_data) {
    gboolean full = GPOINTER_TO_INT(user_data);
    if (g_app.window == NULL) return G_SOURCE_REMOVE;

    if (full && !g_in_full) {
        g_in_full = TRUE;
        GdkRectangle area;
        get_workarea(&area);
        gtk_window_set_default_size(GTK_WINDOW(g_app.window), area.width, area.height);
    } else if (!full && g_in_full) {
        g_in_full = FALSE;
        g_idle_add(do_window_fit, NULL);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_set_full(gboolean full) {
    g_idle_add(do_window_set_full, GINT_TO_POINTER(full));
}

static gboolean do_eval_js(gpointer user_data) {
    char *script = (char *)user_data;
    if (g_app.webview != NULL && script != NULL) {
        webkit_web_view_evaluate_javascript(
            WEBKIT_WEB_VIEW(g_app.webview),
            script,
            -1,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL
        );
    }
    g_free(script);
    return G_SOURCE_REMOVE;
}

static void eval_js_main_thread(const char *script) {
    if (script == NULL) return;
    g_idle_add(do_eval_js, g_strdup(script));
}

static gboolean do_show_window(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_widget_set_visible(g_app.window, TRUE);
        gtk_window_present(GTK_WINDOW(g_app.window));
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_show(void) {
    g_idle_add(do_show_window, NULL);
}

static gboolean do_hide_window(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_widget_set_visible(g_app.window, FALSE);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_hide(void) {
    g_idle_add(do_hide_window, NULL);
}

static gboolean do_close_window(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_window_destroy(GTK_WINDOW(g_app.window));
        g_app.window = NULL;
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_close(void) {
    g_idle_add(do_close_window, NULL);
}

static void trigger_window_quit(void) {
    trigger_window_close();
}

static void trigger_window_drag(void) {
    // Dock cố định, không kéo thả cửa sổ tự do
}

static void trigger_window_set_keep_above(gboolean keep_above) {
    g_keep_above = keep_above;
}

static void trigger_window_raise_notification(void) {
    trigger_window_show();
}

static void trigger_window_fullscreen(gboolean enable) {
    if (g_app.window != NULL) {
        if (enable) {
            gtk_window_fullscreen(GTK_WINDOW(g_app.window));
        } else {
            gtk_window_unfullscreen(GTK_WINDOW(g_app.window));
        }
    }
}

static void trigger_open_url(const char *url) {
    if (url != NULL && url[0] != '\0') {
        char *cmd = g_strdup_printf("xdg-open '%s' >/dev/null 2>&1 &", url);
        int r = system(cmd);
        (void)r;
        g_free(cmd);
    }
}

static void setup_window_and_webview(const char *app_url) {
    gtk_init();

    g_set_prgname("troly");

    GtkWidget *window = gtk_window_new();
    g_app.window = window;

    gtk_window_set_title(GTK_WINDOW(window), "TroLy (Trợ lý) - BamOS");
    gtk_window_set_default_size(GTK_WINDOW(window), 480, 600);
    gtk_window_set_resizable(GTK_WINDOW(window), TRUE);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);

    // CSS styling trong suốt với GtkCssProvider
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_string(css,
        "window, .background, scrolledwindow, viewport {"
        "  background-color: transparent;"
        "  background-image: none;"
        "  box-shadow: none;"
        "  border: none;"
        "  margin: 0;"
        "  padding: 0;"
        "}"
    );
    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(),
        GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
    );

    GtkWidget *webview = webkit_web_view_new();
    g_app.webview = webview;

    WebKitUserContentManager *manager = webkit_web_view_get_user_content_manager(WEBKIT_WEB_VIEW(webview));
    g_signal_connect(manager, "script-message-received::assistantNative", G_CALLBACK(on_script_message), NULL);
    webkit_user_content_manager_register_script_message_handler(manager, "assistantNative", NULL);

    // Wails v3 IPC runtime shim
    const char *wails_shim =
        "window.assistantNative = (function() {"
        "  function post(obj) {"
        "    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.assistantNative) {"
        "      window.webkit.messageHandlers.assistantNative.postMessage(JSON.stringify(obj));"
        "    }"
        "  }"
        "  return {"
        "    dragWindow: function() { post({action: 'drag'}); },"
        "    closeApp: function() { post({action: 'close'}); },"
        "    setAlwaysOnTop: function(e) { post({action: 'set_always_on_top', always_on_top: !!e}); },"
        "    wakeAI: function() { post({action: 'wake_ai'}); },"
        "    ensureServices: function() { post({action: 'ensure_services'}); },"
        "    evaluateSleepOrStop: function() { post({action: 'evaluate_sleep_or_stop'}); },"
        "    setContextDir: function(d) { post({action: 'set_directory', directory: d}); },"
        "    clearContextDir: function() { post({action: 'clear_directory'}); },"
        "    getIdleTime: function() { post({action: 'get_idle_time'}); },"
        "    activateAndRaise: function() { post({action: 'activate_and_raise'}); },"
        "    raiseNotification: function() { post({action: 'raise_notification'}); },"
        "    setFullscreen: function(f) { post({action: 'set_fullscreen', fullscreen: !!f}); },"
        "    setContentSize: function(w, h) { post({action: 'window_fit', width: w, height: h}); },"
        "    setWindowFull: function(f) { post({action: 'window_full', full: !!f}); },"
        "    log: function(m) { post({action: 'log', debug: String(m)}); },"
        "    openUrl: function(u) { post({action: 'open_url', payload: {url: String(u)}}); },"
        "    stopGeneration: function() { post({action: 'stop'}); },"
        "    ask: function(q, r, h) { post({action: 'ask', question: q, use_rag: r, history: h || []}); },"
        "    getSettings: function() { post({action: 'get_settings'}); },"
        "    saveSettings: function(s) { post({action: 'save_settings', payload: s}); },"
        "    listModels: function() { post({action: 'list_models'}); },"
        "    downloadModel: function(u, n) { post({action: 'download_model', payload: {url: u, name: n}}); },"
        "    setActiveModel: function(p) { post({action: 'set_active_model', payload: {path: p}}); },"
        "    testLLM: function() { post({action: 'test_llm'}); },"
        "    restartAI: function() { post({action: 'restart_ai'}); },"
        "    ragAddDocuments: function(d) { post({action: 'rag_add_documents', payload: {documents: d}}); },"
        "    ragStats: function() { post({action: 'rag_stats'}); },"
        "    ragClear: function() { post({action: 'rag_clear'}); },"
        "    ragListDocuments: function() { post({action: 'rag_list_documents'}); },"
        "    ragDeleteDoc: function(s) { post({action: 'rag_delete_doc', payload: {source: s}}); },"
        "    systemInspect: function() { post({action: 'system_inspect'}); },"
        "    wakaStats: function() { post({action: 'waka_stats'}); },"
        "    addReminder: function(t, d) { post({action: 'add_reminder', payload: {title: t, due_time: d}}); },"
        "    toggleReminder: function(id) { post({action: 'toggle_reminder', payload: {id: id}}); },"
        "    getProfile: function() { post({action: 'get_profile'}); },"
        "    updateProfile: function(p) { post({action: 'update_profile', payload: p}); },"
        "    getQuiz: function() { post({action: 'get_quiz'}); },"
        "    submitQuiz: function(a) { post({action: 'submit_quiz', payload: {answers: a}}); }"
        "  };"
        "})();"
        "window.wails = (function() {"
        "  const eventListeners = new Map();"
        "  return {"
        "    Call: function(method, ...args) {"
        "      return new Promise((resolve, reject) => {"
        "        try {"
        "          if (window.assistantNative && typeof window.assistantNative[method] === 'function') {"
        "            resolve(window.assistantNative[method](...args));"
        "          } else {"
        "            resolve(null);"
        "          }"
        "        } catch (e) { reject(e); }"
        "      });"
        "    },"
        "    Events: {"
        "      On: function(name, callback) {"
        "        if (!eventListeners.has(name)) eventListeners.set(name, new Set());"
        "        eventListeners.get(name).add(callback);"
        "        return () => eventListeners.get(name).delete(callback);"
        "      },"
        "      Emit: function(name, data) {"
        "        const set = eventListeners.get(name);"
        "        if (set) set.forEach(fn => { try { fn(data); } catch (e) { console.error(e); } });"
        "      }"
        "    }"
        "  };"
        "})();";

    WebKitUserScript *userScript = webkit_user_script_new(
        wails_shim,
        WEBKIT_USER_CONTENT_INJECT_TOP_FRAME,
        WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START,
        NULL, NULL
    );
    webkit_user_content_manager_add_script(manager, userScript);

    GdkRGBA transparent = {0.0, 0.0, 0.0, 0.0};
    webkit_web_view_set_background_color(WEBKIT_WEB_VIEW(webview), &transparent);

    GtkWidget *scrolled = gtk_scrolled_window_new();
    gtk_scrolled_window_set_has_frame(GTK_SCROLLED_WINDOW(scrolled), FALSE);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolled), GTK_POLICY_NEVER, GTK_POLICY_NEVER);
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scrolled), webview);

    gtk_window_set_child(GTK_WINDOW(window), scrolled);

    apply_initial_position(GTK_WINDOW(window));

    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), app_url);

    gtk_window_present(GTK_WINDOW(window));
}

static void run_main_loop() {
    while (g_list_model_get_n_items(gtk_window_get_toplevels()) > 0) {
        g_main_context_iteration(NULL, TRUE);
    }
}
*/
import "C"
import (
	"strings"
	"unsafe"
)

func EvalJS(script string) {
	cScript := C.CString(script)
	C.eval_js_main_thread(cScript)
	C.free(unsafe.Pointer(cScript))
}

func EscapeJSString(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "'", "\\'")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\r", "")
	return s
}

func CBool(v bool) C.gboolean {
	if v {
		return 1
	}
	return 0
}

func TriggerWindowShow() {
	C.trigger_window_show()
}

func TriggerWindowHide() {
	C.trigger_window_hide()
}

func TriggerWindowQuit() {
	C.trigger_window_quit()
}

func TriggerWindowClose() {
	C.trigger_window_close()
}

func TriggerWindowDrag() {
	C.trigger_window_drag()
}

func TriggerWindowSetKeepAbove(enable bool) {
	C.trigger_window_set_keep_above(CBool(enable))
}

func TriggerWindowRaiseNotification() {
	C.trigger_window_raise_notification()
}

func TriggerWindowFullscreen(enable bool) {
	C.trigger_window_fullscreen(CBool(enable))
}

func TriggerWindowFit(w, h int) {
	C.trigger_window_fit(C.int(w), C.int(h))
}

func TriggerWindowSetFull(full bool) {
	C.trigger_window_set_full(CBool(full))
}

func TriggerOpenURL(url string) {
	cURL := C.CString(url)
	C.trigger_open_url(cURL)
	C.free(unsafe.Pointer(cURL))
}

func SetupWindowAndWebview(appURL string) {
	cURL := C.CString(appURL)
	defer C.free(unsafe.Pointer(cURL))
	C.setup_window_and_webview(cURL)
}

func RunMainLoop() {
	C.run_main_loop()
}

func SetWindowStatePath(path string) {
	cPath := C.CString(path)
	defer C.free(unsafe.Pointer(cPath))
	C.set_window_state_path(cPath)
}

func SetDockPosition(pos string) {
	cPos := C.CString(pos)
	defer C.free(unsafe.Pointer(cPos))
	C.set_dock_position(cPos)
}

func SetWindowScaleFactor(scale float64) {
	C.set_window_scale_factor(C.double(scale))
}

func SetInitialGeometry(right, bottom, ww, wh, scale int, keepAbove bool) {
	// Giữ interface đồng bộ với App
}

func SetDefaultKeepAbove(keepAbove bool) {
	C.trigger_window_set_keep_above(CBool(keepAbove))
}
