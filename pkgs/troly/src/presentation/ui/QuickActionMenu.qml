import QtQuick
import QtQuick.Controls

Item {
    id: quickMenu
    width: 220
    height: menuCol.implicitHeight + 16
    visible: false

    signal panelRequested(string panelName)

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#1E1E2E"
        border.color: "#45475A"
        border.width: 1

        Column {
            id: menuCol
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: [
                    { id: "rag", label: "📚 Thiết lập Tri thức (RAG)" },
                    { id: "llm", label: "📓 Thiết lập LLM / SLM" },
                    { id: "eyeleo", label: "⏰ Nghỉ mắt EyeLeo (20-20-20)" },
                    { id: "system", label: "🛡️ Giám sát Hệ thống" },
                    { id: "waka", label: "📊 WakaTracker Thống kê" },
                    { id: "profile", label: "👤 Hồ sơ & Năng lực" },
                    { id: "about", label: "ℹ️ Giới thiệu BamOS AI" }
                ]

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: itemHover.containsMouse ? "#313244" : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: modelData.label
                        color: "#CDD6F4"
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
