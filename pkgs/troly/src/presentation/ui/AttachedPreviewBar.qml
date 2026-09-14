import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: attachBar
    height: 32
    radius: 8
    color: "#24273A"
    border.color: "#89B4FA"
    border.width: 1
    visible: attachedFilePath !== ""

    property string attachedFilePath: ""
    signal removed()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 6

        Text {
            text: "📎"
            font.pixelSize: 14
        }

        Text {
            text: "Đính kèm: " + attachBar.attachedFilePath.split("/").pop()
            color: "#89B4FA"
            font.pixelSize: 11
            elide: Text.ElideMiddle
            Layout.fillWidth: true
        }

        Text {
            text: "×"
            color: "#89B4FA"
            font.pixelSize: 16
            font.bold: true

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    attachBar.attachedFilePath = "";
                    attachBar.removed();
                }
            }
        }
    }
}
