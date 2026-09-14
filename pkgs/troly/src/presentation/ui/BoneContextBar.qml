import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: boneBar
    height: 32
    radius: 8
    color: "#24273A"
    border.color: isHoveredDrop ? "#A6E3A1" : "#F5A97F"
    border.width: isHoveredDrop ? 2 : 1
    visible: currentPath !== ""

    property string currentPath: "/etc/nixos"
    property bool isHoveredDrop: false
    signal cleared()
    signal pathSelected(string path)

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
            color: boneBar.isHoveredDrop ? "#A6E3A1" : "#F5A97F"
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

    // Vùng thả tệp / thư mục chuyên dụng của Bone Context
    DropArea {
        anchors.fill: parent
        onEntered: function(drag) {
            if (drag.hasUrls) {
                boneBar.isHoveredDrop = true;
            }
        }
        onExited: {
            boneBar.isHoveredDrop = false;
        }
        onDropped: function(drop) {
            boneBar.isHoveredDrop = false;
            if (drop.hasUrls && drop.urls.length > 0) {
                var urlStr = drop.urls[0].toString();
                // Bỏ prefix file:// nếu có
                if (urlStr.indexOf("file://") === 0) {
                    urlStr = urlStr.substring(7);
                }
                boneBar.currentPath = urlStr;
                boneBar.pathSelected(urlStr);
            }
        }
    }
}
