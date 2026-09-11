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
// Chiều cao tối đa của cửa sổ khít. Nội dung dài hơn sẽ CUỘN trong khung chat.
#define MAX_FIT_HEIGHT 864

static char g_state_path[4096] = {0};
static gboolean g_keep_above = TRUE;
static gboolean g_has_saved_position = FALSE;
// Khung "khít" được neo theo góc dưới-phải (toạ độ màn hình).
static gint g_saved_right = 0;
static gint g_saved_bottom = 0;
static guint g_save_timeout = 0;

// Chế độ mở rộng (bảng thiết lập / nghỉ dài): ghi nhớ khung khít để khôi phục.
static gboolean g_in_full = FALSE;
static gint g_fit_x = 0, g_fit_y = 0, g_fit_w = 0, g_fit_h = 0;

// Kích thước nội dung do giao diện yêu cầu.
static gint g_pending_w = 0, g_pending_h = 0;

// Cờ "đang tự điều khiển hình học": mọi configure-event sinh ra trong lúc này
// là hệ quả của lệnh resize/move của CHÍNH TA (X11 áp dụng bất đồng bộ), nên
// KHÔNG được dùng để cập nhật mốc neo — nếu không sẽ đọc phải hình học nửa vời
// (đã resize nhưng chưa move) và làm cửa sổ nhảy về vị trí cũ.
static gboolean g_geom_busy = FALSE;
static guint g_geom_busy_timeout = 0;

static gboolean clear_geom_busy(gpointer user_data) {
    g_geom_busy_timeout = 0;
    g_geom_busy = FALSE;
    return G_SOURCE_REMOVE;
}

static void mark_geom_busy(void) {
    g_geom_busy = TRUE;
    if (g_geom_busy_timeout != 0) g_source_remove(g_geom_busy_timeout);
    g_geom_busy_timeout = g_timeout_add(250, clear_geom_busy, NULL);
}

// Ghi nhận mốc neo (góc dưới-phải cửa sổ khít) từ hình học THỰC TẾ.
static void capture_anchor(int x, int y, int w, int h) {
    if (x < 0 || y < 0 || w <= 0 || h <= 0) return;
    g_saved_right = x + w;
    g_saved_bottom = y + h;
    g_has_saved_position = TRUE;
}

// Mốc neo hiện hành: dùng giá trị đã biết; nếu chưa có thì suy ra từ hình học.
static void current_anchor(int *right, int *bottom) {
    if (!g_has_saved_position) {
        gint x = 0, y = 0, w = 0, h = 0;
        if (g_app.window != NULL) {
            gtk_window_get_position(GTK_WINDOW(g_app.window), &x, &y);
            gtk_window_get_size(GTK_WINDOW(g_app.window), &w, &h);
        }
        capture_anchor(x, y, w, h);
    }
    *right = g_saved_right;
    *bottom = g_saved_bottom;
}

// Vùng làm việc của màn hình chính (đã trừ panel).
static void get_workarea(GdkRectangle *area) {
    area->x = 0; area->y = 0; area->width = 1024; area->height = 768;
    GdkDisplay *display = gdk_display_get_default();
    if (display == NULL) return;
    GdkMonitor *monitor = gdk_display_get_primary_monitor(display);
    if (monitor == NULL) {
        int n = gdk_display_get_n_monitors(display);
        if (n > 0) monitor = gdk_display_get_monitor(display, 0);
    }
    if (monitor != NULL) gdk_monitor_get_workarea(monitor, area);
}

// Đường dẫn file lưu trạng thái cửa sổ (do Go truyền sang).
static void set_window_state_path(const char *path) {
    if (path != NULL) {
        g_strlcpy(g_state_path, path, sizeof(g_state_path));
    }
}

// Lấy vùng làm việc (logical px) + scale factor của màn hình chính.
static void current_workarea_and_scale(int *w, int *h, int *scale) {
    GdkRectangle area;
    get_workarea(&area);
    *w = area.width;
    *h = area.height;
    *scale = 1;
    GdkDisplay *dpy = gdk_display_get_default();
    GdkMonitor *mon = dpy != NULL ? gdk_display_get_primary_monitor(dpy) : NULL;
    if (mon != NULL) *scale = gdk_monitor_get_scale_factor(mon);
}

// Khôi phục khung khít từ lần chạy trước (neo theo góc dưới-phải = vị trí pet).
//
// Hỗ trợ màn hình ĐỔI độ phân giải / tỉ lệ: mốc neo được lưu kèm kích thước vùng
// làm việc + scale lúc ghi. Nếu hiện tại khác, bảo toàn KHOẢNG CÁCH TỚI GÓC
// DƯỚI-PHẢI (nơi pet neo) rồi quy đổi — nhờ vậy pet vẫn nằm đúng chỗ.
static void set_initial_geometry(int right, int bottom, int saved_ww, int saved_wh, int saved_scale, gboolean keep_above) {
    GdkRectangle area;
    get_workarea(&area);
    int cur_ww = 0, cur_wh = 0, cur_scale = 1;
    current_workarea_and_scale(&cur_ww, &cur_wh, &cur_scale);

    if (saved_ww > 0 && saved_wh > 0 &&
        (saved_ww != cur_ww || saved_wh != cur_wh || saved_scale != cur_scale)) {
        double fx = (double)(saved_ww - right) / (double)saved_ww;   // khoảng cách tới mép phải
        double fy = (double)(saved_wh - bottom) / (double)saved_wh; // khoảng cách tới mép dưới
        if (fx < 0) fx = 0;
        if (fy < 0) fy = 0;
        right = area.x + area.width - (int)(fx * area.width);
        bottom = area.y + area.height - (int)(fy * area.height);
        g_print("[BamAI GUI] Đổi màn hình %dx%d/scale=%d -> %dx%d/scale=%d; mốc neo quy đổi: right=%d bottom=%d\n",
                saved_ww, saved_wh, saved_scale, cur_ww, cur_wh, cur_scale, right, bottom);
    }

    // Kẹp vào vùng làm việc để không "mất" cửa sổ sau khi đổi cấu hình.
    if (right > area.x + area.width) right = area.x + area.width;
    if (bottom > area.y + area.height) bottom = area.y + area.height;
    if (right < area.x + 60) right = area.x + 60;
    if (bottom < area.y + 60) bottom = area.y + 60;

    g_saved_right = right;
    g_saved_bottom = bottom;
    g_has_saved_position = TRUE;
    g_keep_above = keep_above;
}

// Chỉ đặt trạng thái ghim mặc định (khi chưa có vị trí đã lưu).
static void set_default_keep_above(gboolean keep_above) {
    g_keep_above = keep_above;
}

// Ghi mốc neo hiện tại xuống file (chỉ khi đang ở chế độ khít).
static gboolean do_save_window_state(gpointer user_data) {
    g_save_timeout = 0;
    if (g_app.window == NULL || g_state_path[0] == '\0' || g_in_full) return G_SOURCE_REMOVE;

    if (!g_has_saved_position) {
        gint x = 0, y = 0, w = 0, h = 0;
        gtk_window_get_position(GTK_WINDOW(g_app.window), &x, &y);
        gtk_window_get_size(GTK_WINDOW(g_app.window), &w, &h);
        capture_anchor(x, y, w, h);
        if (!g_has_saved_position) return G_SOURCE_REMOVE;
    }

    int ww = 0, wh = 0, sc = 1;
    current_workarea_and_scale(&ww, &wh, &sc);

    FILE *fp = fopen(g_state_path, "w");
    if (fp != NULL) {
        // Lưu góc dưới-phải (mốc neo pet) + vùng làm việc & scale lúc ghi để lần
        // sau đổi độ phân giải/tỉ lệ vẫn quy đổi đúng. Trạng thái ghim thuộc
        // assistant_config.json để tránh hai nguồn sự thật.
        fprintf(fp, "{\"right\":%d,\"bottom\":%d,\"work_w\":%d,\"work_h\":%d,\"scale\":%d}\n",
                g_saved_right, g_saved_bottom, ww, wh, sc);
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
    if (event->x < 0 || event->y < 0) return FALSE;
    // Bỏ qua thay đổi do chính ta gây ra (resize/move khít hoặc mở rộng).
    if (g_in_full || g_geom_busy) return FALSE;
    // Cửa sổ đang ẩn / thu nhỏ / chưa được map: toạ độ do WM báo là KHÔNG đáng
    // tin (thường về 0,0 hoặc vị trí tạm thời). Nếu ghi vào mốc neo thì lần hiện
    // lại chú cún và khung chat sẽ nhảy sang chỗ khác. Chỉ ghi nhận hình học khi
    // cửa sổ đang hiển thị bình thường.
    if (!gtk_widget_get_mapped(widget)) return FALSE;
    GdkWindow *gdk_win = gtk_widget_get_window(widget);
    if (gdk_win == NULL) return FALSE;
    GdkWindowState gstate = gdk_window_get_state(gdk_win);
    if (gstate & (GDK_WINDOW_STATE_ICONIFIED | GDK_WINDOW_STATE_WITHDRAWN)) return FALSE;
    // Bỏ qua khung đúng bằng vùng làm việc (tàn dư của chế độ mở rộng).
    GdkRectangle area;
    get_workarea(&area);
    if (event->width >= area.width - 2 && event->height >= area.height - 2) return FALSE;

    // Chỉ tới đây mới là thao tác NGƯỜI DÙNG kéo cửa sổ → cập nhật mốc neo.
    capture_anchor(event->x, event->y, event->width, event->height);
    schedule_save_window_state();
    return FALSE;
}

// Áp dụng kích thước nội dung, neo CỐ ĐỊNH góc dưới-phải để nội dung không nhảy.
static gboolean do_window_fit(gpointer user_data) {
    if (g_app.window == NULL) return G_SOURCE_REMOVE;

    gint w = g_pending_w, h = g_pending_h;
    if (w < 80) w = 80;
    if (h < 80) h = 80;

    // Chốt an toàn: không để cửa sổ vượt quá vùng làm việc của màn hình,
    // và không vượt quá chiều cao tối đa cho phép (phần dư sẽ cuộn trong khung chat).
    GdkRectangle area;
    get_workarea(&area);
    if (h > MAX_FIT_HEIGHT) h = MAX_FIT_HEIGHT;
    if (h > area.height - 8) h = area.height - 8;
    if (w > area.width - 8) w = area.width - 8;

    // Mốc neo là nguồn sự thật duy nhất — KHÔNG suy ra từ hình học hiện tại vì
    // resize/move của X11 bất đồng bộ, đọc giữa chừng sẽ ra toạ độ sai.
    gint right = 0, bottom = 0;
    current_anchor(&right, &bottom);

    g_fit_w = w;
    g_fit_h = h;
    g_fit_x = right - w;
    g_fit_y = bottom - h;

    if (g_in_full) {
        // Đang mở rộng: chỉ cập nhật khung khít đã nhớ, không đụng cửa sổ thật.
        return G_SOURCE_REMOVE;
    }

    mark_geom_busy();
    gtk_window_resize(GTK_WINDOW(g_app.window), w, h);
    gtk_window_move(GTK_WINDOW(g_app.window), g_fit_x, g_fit_y);
    return G_SOURCE_REMOVE;
}

static void trigger_window_fit(int w, int h) {
    g_pending_w = w;
    g_pending_h = h;
    g_idle_add(do_window_fit, NULL);
}

// Mở rộng ra toàn vùng làm việc khi có bảng thiết lập / màn hình nghỉ dài,
// hoặc thu về đúng khung khít đã nhớ.
static gboolean do_window_set_full(gpointer user_data) {
    gboolean enable = GPOINTER_TO_INT(user_data);
    if (g_app.window == NULL) return G_SOURCE_REMOVE;

    if (enable && !g_in_full) {
        // Ghi nhớ kích thước khung khít đang dùng (do lần fit gần nhất quyết định).
        if (g_fit_w <= 0 || g_fit_h <= 0) {
            gint w = 0, h = 0;
            gtk_window_get_size(GTK_WINDOW(g_app.window), &w, &h);
            g_fit_w = w;
            g_fit_h = h;
        }
        gint right = 0, bottom = 0;
        current_anchor(&right, &bottom);
        g_fit_x = right - g_fit_w;
        g_fit_y = bottom - g_fit_h;

        GdkRectangle area;
        get_workarea(&area);
        mark_geom_busy();
        gtk_window_resize(GTK_WINDOW(g_app.window), area.width, area.height);
        gtk_window_move(GTK_WINDOW(g_app.window), area.x, area.y);
        g_in_full = TRUE;
    } else if (!enable && g_in_full) {
        g_in_full = FALSE;
        if (g_fit_w > 0 && g_fit_h > 0) {
            gint right = 0, bottom = 0;
            current_anchor(&right, &bottom);
            g_fit_x = right - g_fit_w;
            g_fit_y = bottom - g_fit_h;
            mark_geom_busy();
            gtk_window_resize(GTK_WINDOW(g_app.window), g_fit_w, g_fit_h);
            gtk_window_move(GTK_WINDOW(g_app.window), g_fit_x, g_fit_y);
        }
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_set_full(gboolean enable) {
    g_idle_add(do_window_set_full, GINT_TO_POINTER(enable));
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

static gboolean do_hide(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_widget_hide(g_app.window);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_hide() {
    g_idle_add(do_hide, NULL);
}

// Mở URL bằng ứng dụng mặc định của hệ thống (thường là trình duyệt). Phải chạy
// trên luồng chính GTK vì gtk_show_uri_on_window cần cửa sổ.
static gboolean do_open_url(gpointer user_data) {
    char *url = (char*)user_data;
    if (url != NULL) {
        GError *err = NULL;
        if (g_app.window != NULL) {
            gtk_show_uri_on_window(GTK_WINDOW(g_app.window), url, GDK_CURRENT_TIME, &err);
        } else {
            g_app_info_launch_default_for_uri(url, NULL, &err);
        }
        if (err != NULL) {
            g_printerr("[BamAI GUI] Không mở được liên kết %s: %s\n", url, err->message);
            g_error_free(err);
        }
    }
    g_free(url);
    return G_SOURCE_REMOVE;
}

static void trigger_open_url(const char *url) {
    if (url != NULL) g_idle_add(do_open_url, g_strdup(url));
}

static gboolean do_quit(gpointer user_data) {
    if (g_app.window != NULL) {
        // Huỷ cửa sổ → gtk_main_quit → tiến trình kết thúc.
        gtk_widget_destroy(g_app.window);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_quit() {
    g_idle_add(do_quit, NULL);
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

// Đưa cửa sổ về đúng mốc neo sau khi được hiện lại. WM có thể xếp cửa sổ ở vị
// trí tạm trong lúc map; chờ một nhịp để X11 áp dụng xong hình học rồi neo lại
// góc dưới-phải — nhờ vậy chú cún đứng yên qua các lần ẩn/hiện/thu nhỏ.
static gboolean reapply_anchor_position(gpointer user_data);

static gboolean do_show(gpointer user_data) {
    if (g_app.window != NULL) {
        // Mọi configure-event trong lúc hiện lại là do WM sắp xếp, không phải
        // người dùng kéo → không được ghi vào mốc neo.
        mark_geom_busy();
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
        // Neo lại góc dưới-phải sau khi WM đã xếp xong cửa sổ.
        g_timeout_add(150, reapply_anchor_position, NULL);
    }
    return G_SOURCE_REMOVE;
}

static void trigger_window_show() {
    g_idle_add(do_show, NULL);
}

// Đưa cửa sổ lên CAO NHẤT khi có nhắc nhở nghỉ ngơi: hiện + ghim tạm trên cùng
// (kể cả khi người dùng đã tắt ghim), rồi trả lại trạng thái ghim sau 12 giây.
static gboolean restore_keep_above_after_notify(gpointer user_data) {
    if (g_app.window != NULL) {
        gtk_window_set_keep_above(GTK_WINDOW(g_app.window), g_keep_above);
    }
    return G_SOURCE_REMOVE;
}

static gboolean do_raise_notification(gpointer user_data) {
    if (g_app.window == NULL) return G_SOURCE_REMOVE;

    mark_geom_busy();
    gtk_widget_show_all(g_app.window);
    gtk_window_deiconify(GTK_WINDOW(g_app.window));
    gtk_window_set_keep_above(GTK_WINDOW(g_app.window), TRUE);
    gtk_window_present_with_time(GTK_WINDOW(g_app.window), GDK_CURRENT_TIME);

    GdkWindow *gdk_win = gtk_widget_get_window(g_app.window);
    if (gdk_win != NULL) {
        gdk_window_raise(gdk_win);
    }

    gtk_window_set_urgency_hint(GTK_WINDOW(g_app.window), TRUE);
    g_timeout_add(2500, clear_urgency_hint, NULL);
    // Nhắc nhở hiện lâu hơn để người dùng kịp đọc, sau đó trả lại trạng thái ghim.
    g_timeout_add(12000, restore_keep_above_after_notify, NULL);

    g_timeout_add(150, reapply_anchor_position, NULL);
    return G_SOURCE_REMOVE;
}

static void trigger_window_raise_notification() {
    g_idle_add(do_raise_notification, NULL);
}

static gboolean on_window_draw(GtkWidget *widget, cairo_t *cr, gpointer data) {
    // Xóa triệt để nền đệm thành trong suốt tuyệt đối bằng toán tử Cairo CLEAR
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
    return FALSE;
}

// Đặt cửa sổ sao cho góc dưới-phải nằm tại (right, bottom) toạ độ màn hình.
static void move_window_by_bottom_right(GtkWindow *window, int right, int bottom) {
    if (window == NULL) return;
    gint w = 0, h = 0;
    gtk_window_get_size(window, &w, &h);
    if (w <= 0) w = 390;
    if (h <= 0) h = 560;
    gtk_window_move(window, right - w, bottom - h);
}

// Góc dưới-phải mặc định: sát góc dưới-phải vùng làm việc.
static void default_bottom_right(int *right, int *bottom) {
    GdkRectangle area;
    get_workarea(&area);
    *right = area.x + area.width - 12;
    *bottom = area.y + area.height - 12;
}

// Khôi phục khung lần chạy trước; nếu chưa có thì về góc dưới-phải màn hình.
static void apply_initial_position(GtkWindow *window) {
    if (window == NULL) return;
    int right = 0, bottom = 0;
    if (g_has_saved_position) {
        right = g_saved_right;
        bottom = g_saved_bottom;
    } else {
        default_bottom_right(&right, &bottom);
    }
    move_window_by_bottom_right(window, right, bottom);
}

// (Đã khai báo trước ở do_show) Neo lại cửa sổ theo mốc đã lưu, không suy diễn
// từ hình học hiện tại để tránh đọc phải toạ độ tạm do WM xếp lúc vừa hiện.
static gboolean reapply_anchor_position(gpointer user_data) {
    if (g_app.window == NULL || g_in_full) return G_SOURCE_REMOVE;
    int right = 0, bottom = 0;
    if (g_has_saved_position) {
        right = g_saved_right;
        bottom = g_saved_bottom;
    } else {
        default_bottom_right(&right, &bottom);
    }
    mark_geom_busy();
    move_window_by_bottom_right(GTK_WINDOW(g_app.window), right, bottom);
    return G_SOURCE_REMOVE;
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

// Buộc WebKit vẽ lại frame đầu khi trang nạp xong. Trên XWayland, WebView có
// thể không composite cho tới khi có tương tác → cửa sổ trống/đen cho tới lúc
// người dùng click. Chủ động queue_draw + present để nội dung hiện ngay.
static void on_webview_load_changed(WebKitWebView *webview, WebKitLoadEvent event, gpointer user_data) {
    if (event != WEBKIT_LOAD_FINISHED) return;
    gtk_widget_queue_draw(GTK_WIDGET(webview));
    if (g_app.window != NULL) {
        gtk_widget_queue_draw(g_app.window);
        if (gtk_widget_get_visible(g_app.window)) {
            gtk_window_present(GTK_WINDOW(g_app.window));
        }
    }
}

// Chờ compositor sẵn sàng rồi mới hiện cửa sổ với visual RGBA.
//
// Đây là mấu chốt của lỗi "cửa sổ ĐEN lúc cold-boot": app tự khởi động chỉ sau
// vài giây, có thể TRƯỚC khi Mutter bật compositing. Lúc đó
// gdk_screen_is_composited() = FALSE → không gắn được visual RGBA → cửa sổ ĐỤC,
// mà CSS lại đặt nền trong suốt ⇒ vùng nền hiện thành ĐEN. Visual không đổi được
// sau khi cửa sổ đã realize, nên phải chờ TRƯỚC khi show.
#define SHOW_WAIT_MS 250
#define SHOW_WAIT_MAX_TICKS 480 // 480 x 250ms = 120s

static int g_show_wait_ticks = 0;

static gboolean try_show_window(gpointer user_data) {
    if (g_app.window == NULL) return G_SOURCE_REMOVE;

    GdkScreen *screen = gtk_widget_get_screen(g_app.window);
    gboolean composited = (screen != NULL) && gdk_screen_is_composited(screen);

    if (!composited && g_show_wait_ticks < SHOW_WAIT_MAX_TICKS) {
        g_show_wait_ticks++;
        if (g_show_wait_ticks == 1 || g_show_wait_ticks % 20 == 0) {
            g_print("[BamAI GUI] Chờ compositor (nền trong suốt)… %dms\n",
                    g_show_wait_ticks * SHOW_WAIT_MS);
        }
        return G_SOURCE_CONTINUE;
    }

    if (composited) {
        GdkVisual *visual = gdk_screen_get_rgba_visual(screen);
        if (visual != NULL) gtk_widget_set_visual(g_app.window, visual);
    }

    gtk_widget_show_all(g_app.window);
    apply_initial_position(GTK_WINDOW(g_app.window));
    gtk_window_present(GTK_WINDOW(g_app.window));
    if (g_app.webview != NULL) gtk_widget_queue_draw(g_app.webview);

    g_print("[BamAI GUI] Hiện cửa sổ: composited=%d sau %dms\n",
            composited, g_show_wait_ticks * SHOW_WAIT_MS);
    return G_SOURCE_REMOVE;
}

static void setup_window_and_webview(const char *app_url) {
    gtk_init(NULL, NULL);

    // Đặt WM_CLASS khớp CHÍNH XÁC với StartupWMClass trong desktop file → GNOME
    // gộp cửa sổ đang chạy với biểu tượng đã ghim trên dock.
    g_set_prgname("bamos-assistant");
    gdk_set_program_class("bamos-assistant");

    // Nhật ký chẩn đoán: không gian toạ độ (logical px) + scale factor.
    {
        GdkRectangle area;
        get_workarea(&area);
        GdkDisplay *dpy = gdk_display_get_default();
        GdkMonitor *mon = dpy != NULL ? gdk_display_get_primary_monitor(dpy) : NULL;
        int scale = mon != NULL ? gdk_monitor_get_scale_factor(mon) : 1;
        g_print("[BamAI GUI] Workarea=%dx%d+%d+%d scale=%d\n",
                area.width, area.height, area.x, area.y, scale);
    }

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    g_app.window = window;

    gtk_window_set_title(GTK_WINDOW(window), "BamOS Mascot Assistant");
    gtk_window_set_default_size(GTK_WINDOW(window), 390, 560);
    // Cửa sổ PHẢI resizable để tầng C có thể co giãn khít nội dung (JS yêu cầu).
    gtk_window_set_resizable(GTK_WINDOW(window), TRUE);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
    gtk_window_set_keep_above(GTK_WINDOW(window), g_keep_above);
    // Cửa sổ xuất hiện như một ứng dụng bình thường trong dock/alt-tab để việc
    // GHIM lên dock hoạt động đúng (khớp StartupWMClass trong desktop file).
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window), FALSE);
    gtk_window_set_type_hint(GTK_WINDOW(window), GDK_WINDOW_TYPE_HINT_NORMAL);
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
        // Quy tắc bao trùm: mọi widget GTK của ứng dụng (kể cả WebKitWebView
        // TRƯỚC khi nội dung được vẽ) đều trong suốt. Nếu không, widget WebView
        // vẽ nền theme (tối/đen) trong lúc chờ frame đầu → cửa sổ "đen".
        "* {"
        "  background-color: rgba(0, 0, 0, 0);"
        "  background-image: none;"
        "}"
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
        "    ensureServices: function() { post({action: 'ensure_services'}); },"
        "    evaluateSleepOrStop: function() { post({action: 'evaluate_sleep_or_stop'}); },"
        "    setContextDir: function(dir) { post({action: 'set_directory', directory: dir}); },"
        "    clearContextDir: function() { post({action: 'clear_directory'}); },"
        "    getIdleTime: function() { post({action: 'get_idle_time'}); },"
        "    activateAndRaise: function() { post({action: 'activate_and_raise'}); },"
        "    raiseNotification: function() { post({action: 'raise_notification'}); },"
        "    setFullscreen: function(fs) { post({action: 'set_fullscreen', fullscreen: !!fs}); },"
        "    setContentSize: function(w, h) { post({action: 'window_fit', width: w, height: h}); },"
        "    setWindowFull: function(full) { post({action: 'window_full', full: !!full}); },"
        "    log: function(message) { post({action: 'log', debug: String(message)}); },"
        "    openUrl: function(url) { post({action: 'open_url', payload: {url: String(url)}}); },"
        "    stopGeneration: function() { post({action: 'stop'}); },"
        "    ask: function(q, rag, history) { post({action: 'ask', question: q, use_rag: rag, history: history || []}); },"
        // ---- Bảng thiết lập ----
        "    getSettings: function() { post({action: 'get_settings'}); },"
        "    saveSettings: function(settings) { post({action: 'save_settings', payload: settings}); },"
        "    listModels: function() { post({action: 'list_models'}); },"
        "    downloadModel: function(url, name) { post({action: 'download_model', payload: {url: url, name: name}}); },"
        "    setActiveModel: function(path) { post({action: 'set_active_model', payload: {path: path}}); },"
        "    testLLM: function() { post({action: 'test_llm'}); },"
        "    restartAI: function() { post({action: 'restart_ai'}); },"
        // ---- Tri thức RAG (FTS5 + sqlite-vec) ----
        "    ragAddDocuments: function(docs) { post({action: 'rag_add_documents', payload: {documents: docs}}); },"
        "    ragStats: function() { post({action: 'rag_stats'}); },"
        "    ragClear: function() { post({action: 'rag_clear'}); },"
        "    ragListDocuments: function() { post({action: 'rag_list_documents'}); },"
        "    ragDeleteDoc: function(src) { post({action: 'rag_delete_doc', payload: {source: src}}); },"
        // ---- Giám sát Hệ thống & NixOS ----
        "    systemInspect: function() { post({action: 'system_inspect'}); },"
        // ---- WakaTracker ----
        "    wakaStats: function() { post({action: 'waka_stats'}); },"
        "    addReminder: function(t, d) { post({action: 'add_reminder', payload: {title: t, due_time: d}}); },"
        "    toggleReminder: function(id) { post({action: 'toggle_reminder', payload: {id: id}}); },"
        // ---- Hồ sơ người dùng & Onboarding Quiz ----
        "    getProfile: function() { post({action: 'get_profile'}); },"
        "    updateProfile: function(p) { post({action: 'update_profile', payload: p}); },"
        "    getQuiz: function() { post({action: 'get_quiz'}); },"
        "    submitQuiz: function(ans) { post({action: 'submit_quiz', payload: {answers: ans}}); }"
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

    // TẮT tăng tốc phần cứng cho WebView. Trên XWayland + GPU hybrid (Intel +
    // NVIDIA), đường compositing tăng tốc tạo một cửa sổ con X11 ĐỤC phủ kín
    // vùng web → cửa sổ thành một khối ĐEN, phá nền trong suốt. Không tăng tốc
    // thì WebKit vẽ trực tiếp vào widget và alpha được tôn trọng.
    WebKitSettings *wsettings = webkit_settings_new();
    webkit_settings_set_hardware_acceleration_policy(
        wsettings, WEBKIT_HARDWARE_ACCELERATION_POLICY_NEVER);
    webkit_web_view_set_settings(WEBKIT_WEB_VIEW(webview), wsettings);

    // Vẽ lại frame đầu ngay khi trang nạp xong (tránh cửa sổ đen trên XWayland).
    g_signal_connect(webview, "load-changed", G_CALLBACK(on_webview_load_changed), NULL);

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
    // KHÔNG hiện ngay: chờ compositor sẵn sàng để gắn được visual RGBA (nền trong
    // suốt thật). Hiện khi chưa composited sẽ cho cửa sổ ĐỤC → nền "trong suốt"
    // của CSS hiển thị thành ĐEN.
    g_timeout_add(0, try_show_window, NULL);
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
	"net/url"
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
	Width       int             `json:"width"`
	Height      int             `json:"height"`
	Full        bool            `json:"full"`
	Debug       string          `json:"debug"`
	History     []ChatMessage   `json:"history"`
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

	if debugEnabled() {
		fmt.Printf("[BamAI GUI] action=%s\n", msg.Action)
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
	case "raise_notification":
		// Nhắc nhở nghỉ ngơi: đưa cửa sổ lên cao nhất (ghim tạm trên cùng).
		C.trigger_window_raise_notification()
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
	case "window_fit":
		if debugEnabled() {
			fmt.Printf("[BamAI GUI] Fit cửa sổ -> %dx%d\n", msg.Width, msg.Height)
		}
		C.trigger_window_fit(C.int(msg.Width), C.int(msg.Height))
	case "window_full":
		if debugEnabled() {
			fmt.Printf("[BamAI GUI] Mở rộng cửa sổ -> %v\n", msg.Full)
		}
		C.trigger_window_set_full(cBool(msg.Full))
	case "log":
		// Nhật ký chẩn đoán từ tầng giao diện (WebView không in ra stdout).
		if debugEnabled() {
			fmt.Printf("[BamAI UI] %s\n", msg.Debug)
		}
	case "open_url":
		handleOpenURL(msg.Payload)
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
	case "wake_ai", "ensure_services":
		if globalAI != nil {
			go globalAI.EnsureServices(
				func(progressMsg string) {
					pushJSON("onAIWaking", progressMsg)
				},
				func(started bool) {
					evalJS(fmt.Sprintf("window.onAIReady && window.onAIReady(%t);", started))
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
					msg.History,
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
	case "rag_list_documents":
		go handleRagListDocuments()
	case "rag_delete_doc":
		go handleRagDeleteDoc(msg.Payload)

	// ---- Giám sát Hệ thống & NixOS ----
	case "system_inspect":
		go handleSystemInspect()

	// ---- WakaTracker ----
	case "waka_stats":
		go handleWakaStats()
	case "add_reminder":
		go handleAddReminder(msg.Payload)
	case "toggle_reminder":
		go handleToggleReminder(msg.Payload)

	// ---- Hồ sơ người dùng & Onboarding Quiz ----
	case "get_profile":
		go handleGetProfile()
	case "update_profile":
		go handleUpdateProfile(msg.Payload)
	case "get_quiz":
		go handleGetQuiz()
	case "submit_quiz":
		go handleSubmitQuiz(msg.Payload)
	}
}

// handleOpenURL mở liên kết bằng trình duyệt/ứng dụng mặc định của hệ thống.
// Chỉ chấp nhận http/https để tránh kích hoạt scheme nguy hiểm (file:, smb:…).
func handleOpenURL(payload json.RawMessage) {
	var req struct {
		URL string `json:"url"`
	}
	if err := json.Unmarshal(payload, &req); err != nil {
		return
	}

	raw := strings.TrimSpace(req.URL)
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Host == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		fmt.Printf("[BamAI GUI] Bỏ qua liên kết không hợp lệ: %q\n", raw)
		return
	}

	target := parsed.String()
	if debugEnabled() {
		fmt.Printf("[BamAI GUI] Mở liên kết: %s\n", target)
	}
	cURL := C.CString(target)
	C.trigger_open_url(cURL)
	C.free(unsafe.Pointer(cURL))
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

func StartUI(ai *AIService, startupPanel string) {
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

	// API mở bảng thiết lập trong giao diện (menu GNOME Shell gọi vào).
	// KHÔNG khởi động dịch vụ AI: bảng thiết lập chỉ đọc/ghi cấu hình cục bộ;
	// dịch vụ AI chỉ được bật khi người dùng click chú cún / ô nhập liệu.
	mux.HandleFunc("/api/open-settings", func(w http.ResponseWriter, r *http.Request) {
		panel := r.URL.Query().Get("panel")
		C.trigger_window_show()
		evalJS(fmt.Sprintf("window.openSettingsPanel && window.openSettingsPanel('%s');", escapeJSString(panel)))
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","panel":"%s"}`, panel)
	})

	// API hiển thị cún — chỉ hiện cửa sổ, KHÔNG tự bật dịch vụ AI (tiết kiệm tài
	// nguyên; AI bật khi người dùng click chú cún hoặc ô nhập liệu).
	mux.HandleFunc("/api/show", func(w http.ResponseWriter, r *http.Request) {
		C.trigger_window_show()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	// API ẩn cửa sổ (giữ ứng dụng chạy nền)
	mux.HandleFunc("/api/hide", func(w http.ResponseWriter, r *http.Request) {
		C.trigger_window_hide()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	// API tắt ứng dụng: dừng AI/RAG rồi đóng cửa sổ (tiến trình thoát)
	mux.HandleFunc("/api/quit", func(w http.ResponseWriter, r *http.Request) {
		if globalAI != nil {
			go globalAI.StopAllServices()
		}
		C.trigger_window_quit()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	// Khởi tạo HTTP server nội bộ trên cổng cố định (hoặc random nếu bận)
	address := "127.0.0.1:" + assistantPort()
	listener, err := net.Listen("tcp", address)
	var serverURL string
	if err == nil {
		server := &http.Server{Handler: mux}
		go func() {
			_ = server.Serve(listener)
		}()
		serverURL = "http://" + address
	} else {
		// Nếu 9195 bận thì fallback httptest
		fallbackServer := httptest.NewServer(mux)
		defer fallbackServer.Close()
		serverURL = fallbackServer.URL
	}

	// URL giao diện: kèm `#panel=<tên>` khi được mở từ menu GNOME Shell để giao
	// diện tự mở đúng bảng thiết lập sau khi nạp xong (BamAI khởi động lần đầu).
	uiURL := serverURL
	if startupPanel != "" {
		uiURL = serverURL + "#panel=" + url.QueryEscape(startupPanel)
	}

	cURL := C.CString(uiURL)
	defer C.free(unsafe.Pointer(cURL))

	C.setup_window_and_webview(cURL)
	C.run_main_loop()
}

// windowState là mốc neo lưu giữa các lần chạy: góc dưới-phải (vị trí pet) +
// vùng làm việc & scale lúc ghi (để quy đổi khi đổi độ phân giải/tỉ lệ màn hình).
// Trạng thái ghim nằm trong Config.
type windowState struct {
	Right  int `json:"right"`
	Bottom int `json:"bottom"`
	WorkW  int `json:"work_w"`
	WorkH  int `json:"work_h"`
	Scale  int `json:"scale"`
}

// applySavedWindowState đọc khung đã lưu và chuyển sang tầng C trước khi tạo
// cửa sổ. Nếu chưa có (hoặc không hợp lệ) thì dùng mặc định góc dưới-phải.
func applySavedWindowState(ai *AIService) {
	// Trạng thái ghim lấy từ thiết lập người dùng (nguồn duy nhất); chỉ có
	// khung cửa sổ mới đọc từ window_state.json.
	keepAbove := true
	if ai != nil {
		keepAbove = ai.cfg.AlwaysOnTop
	}

	statePath := getWindowStatePath()
	cPath := C.CString(statePath)
	C.set_window_state_path(cPath)
	C.free(unsafe.Pointer(cPath))

	// Đọc mốc neo đã lưu: ưu tiên vị trí MỚI (/var/lib/bamos/state), rồi tới vị
	// trí CŨ (~/.config/bamos) để di trú một lần cho các bản trước.
	paths := []string{statePath}
	if legacy := getLegacyWindowStatePath(); legacy != statePath {
		paths = append(paths, legacy)
	}
	for _, p := range paths {
		data, err := os.ReadFile(p)
		if err != nil {
			continue
		}
		var st windowState
		if json.Unmarshal(data, &st) != nil || st.Right <= 0 || st.Bottom <= 0 {
			continue
		}
		// File CŨ (không có work_w/work_h/scale) lưu toạ độ ở hệ màn hình cũ →
		// không thể quy đổi tin cậy (từng khiến pet lạc ra giữa màn hình khi đổi
		// tỉ lệ). Bỏ qua để dùng mặc định góc dưới-phải.
		if st.WorkW <= 0 || st.WorkH <= 0 || st.Scale <= 0 {
			fmt.Printf("[BamAI GUI] Mốc neo cũ (%s) thiếu thông tin màn hình → dùng mặc định góc dưới-phải\n", p)
			continue
		}
		C.set_initial_geometry(
			C.int(st.Right), C.int(st.Bottom),
			C.int(st.WorkW), C.int(st.WorkH), C.int(st.Scale),
			cBool(keepAbove),
		)
		return
	}

	// Chưa có khung đã lưu: dùng mặc định nhưng vẫn ghi lại sau này.
	C.set_default_keep_above(cBool(keepAbove))
}

// cBool chuyển bool của Go sang gboolean cho cgo.
func cBool(v bool) C.gboolean {
	if v {
		return 1
	}
	return 0
}
