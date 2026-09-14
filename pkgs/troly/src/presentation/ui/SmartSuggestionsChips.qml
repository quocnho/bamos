import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: smartChipsBar
    height: 32

    signal chipSelected(string query)

    RowLayout {
        anchors.fill: parent
        spacing: 6

        Repeater {
            model: [
                "Kiểm tra hệ thống 🛡️",
                "Tình trạng EyeLeo ⏰",
                "Tra cứu tài liệu NixOS 📘",
                "Git status & log 🌿"
            ]

            Rectangle {
                height: 26
                radius: 13
                color: chipMouse.containsMouse ? "#45475A" : "#313244"
                border.color: "#585B70"
                border.width: 1
                implicitWidth: chipText.implicitWidth + 16

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: modelData
                    color: "#CDD6F4"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: smartChipsBar.chipSelected(modelData)
                }
            }
        }
    }
}
