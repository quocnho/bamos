pragma Singleton
import QtQuick

/**
 * @brief ThemeManager: Quản lý bộ màu sắc & phong cách giao diện BamOS
 * Kế thừa các theme màu từ assistant:
 *  - "teal": Xanh Ngọc BamOS (Mặc định)
 *  - "amber": Cam Hổ Phách Ấm Áp
 *  - "cyan": Cyberpunk Cyan / Neon
 *  - "purple": Tím Hoàng Gia
 *  - "mocha": Catppuccin Mocha / Dark Contrast
 */
QtObject {
    id: themeMgr

    // Phong cách hiện tại: teal | amber | cyan | purple | mocha
    property string currentTheme: "teal"

    // Backgrounds
    readonly property color windowBg: {
        switch (currentTheme) {
            case "amber": return "#F01E1A17";
            case "cyan": return "#EB0F172A";
            case "purple": return "#EB1E142B";
            case "mocha": return "#EB181825";
            case "teal":
            default: return "#EB132020";
        }
    }

    readonly property color cardBg: {
        switch (currentTheme) {
            case "amber": return "#2A231F";
            case "cyan": return "#1E293B";
            case "purple": return "#281B38";
            case "mocha": return "#1E1E2E";
            case "teal":
            default: return "#1A2B2B";
        }
    }

    readonly property color headerBg: {
        switch (currentTheme) {
            case "amber": return "#3A302A";
            case "cyan": return "#243248";
            case "purple": return "#322247";
            case "mocha": return "#25263A";
            case "teal":
            default: return "#213636";
        }
    }

    readonly property color inputBg: {
        switch (currentTheme) {
            case "amber": return "#251F1B";
            case "cyan": return "#172033";
            case "purple": return "#20152F";
            case "mocha": return "#181825";
            case "teal":
            default: return "#162424";
        }
    }

    // Borders & Accents
    readonly property color borderDim: {
        switch (currentTheme) {
            case "amber": return "#4D3D35";
            case "cyan": return "#334155";
            case "purple": return "#432C5E";
            case "mocha": return "#313244";
            case "teal":
            default: return "#2D4747";
        }
    }

    readonly property color borderActive: {
        switch (currentTheme) {
            case "amber": return "#F4A261";
            case "cyan": return "#00F2FE";
            case "purple": return "#C084FC";
            case "mocha": return "#CBA6F7";
            case "teal":
            default: return "#2A9D8F";
        }
    }

    // Primary Brand Accent Colors
    readonly property color primaryAccent: {
        switch (currentTheme) {
            case "amber": return "#F4A261";
            case "cyan": return "#00E5FF";
            case "purple": return "#A855F7";
            case "mocha": return "#89B4FA";
            case "teal":
            default: return "#2A9D8F";
        }
    }

    readonly property color secondaryAccent: {
        switch (currentTheme) {
            case "amber": return "#E76F51";
            case "cyan": return "#3B82F6";
            case "purple": return "#EC4899";
            case "mocha": return "#F38BA8";
            case "teal":
            default: return "#E76F51";
        }
    }

    // Text Colors
    readonly property color textPrimary: "#F8FAFC"
    readonly property color textSecondary: "#94A3B8"
    readonly property color textSubtle: "#64748B"

    // Role Colors in Chat
    readonly property color roleUser: {
        switch (currentTheme) {
            case "amber": return "#F97316";
            case "cyan": return "#38BDF8";
            case "purple": return "#E879F9";
            case "mocha": return "#89B4FA";
            case "teal":
            default: return "#E76F51";
        }
    }

    readonly property color roleAi: {
        switch (currentTheme) {
            case "amber": return "#FBBF24";
            case "cyan": return "#00F2FE";
            case "purple": return "#C084FC";
            case "mocha": return "#A6E3A1";
            case "teal":
            default: return "#2A9D8F";
        }
    }

    // Helper hàm đổi theme
    function setTheme(name) {
        if (name === "teal" || name === "amber" || name === "cyan" || name === "purple" || name === "mocha") {
            currentTheme = name;
        }
    }
}
