import QtQuick
import QtQuick.Controls

Item {
    id: quickMenu
    width: 236
    height: menuCol.implicitHeight + 16
    visible: false

    signal panelRequested(string panelName)

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: ThemeManager.cardBg
        border.color: ThemeManager.borderDim
        border.width: 1

        Column {
            id: menuCol
            anchors.fill: parent
            anchors.margins: 8
            spacing: 3

            Repeater {
                model: [
                    { id: "rag", label: "📚 Thiết lập Tri thức (RAG)" },
                    { id: "llm", label: "🧠 Thiết lập LLM / SLM" },
                    { id: "evolving", label: "🧬 Trung Tâm Tự Tiến Hóa" },
                    { id: "eyeleo", label: "⏰ Nghỉ mắt EyeLeo (20-20-20)" },
                    { id: "system", label: "🛡️ Giám sát Hệ thống" },
                    { id: "waka", label: "📊 WakaTracker Thống kê" },
                    { id: "profile", label: "👤 Hồ sơ & Màu sắc giao diện" },
                    { id: "about", label: "ℹ️ Giới thiệu BamOS AI" }
                ]

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: itemHover.containsMouse ? ThemeManager.headerBg : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: modelData.label
                        color: itemHover.containsMouse ? ThemeManager.primaryAccent : ThemeManager.textPrimary
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            quickMenu.visible = false;
                            quickMenu.panelRequested(modelData.id);
                        }
                    }
                }
            }
        }
    }
}
