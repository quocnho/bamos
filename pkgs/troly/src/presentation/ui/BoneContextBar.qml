import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: boneBar
    height: 32
    radius: 8
    color: "#24273A"
    border.color: "#F5A97F"
    border.width: 1
    visible: currentPath !== ""

    property string currentPath: "/etc/nixos"
    signal cleared()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 6

        Text {
            text: "🍖"
            font.pixelSize: 14
        }

        Text {
            text: "Bối cảnh: " + boneBar.currentPath
            color: "#F5A97F"
            font.pixelSize: 11
            font.bold: true
            elide: Text.ElideMiddle
            Layout.fillWidth: true
        }

        Text {
            text: "×"
            color: "#F5A97F"
            font.pixelSize: 16
            font.bold: true

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    boneBar.currentPath = "";
                    boneBar.cleared();
                }
            }
        }
    }
}
