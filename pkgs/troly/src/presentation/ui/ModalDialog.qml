import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: modalRoot
    anchors.fill: parent
    color: "#8011111B"
    visible: false
    z: 999

    property string title: "Thiết Lập"
    default property alias content: bodyContainer.children
    signal closed()

    MouseArea {
        anchors.fill: parent
        onClicked: modalRoot.close()
    }

    function open() { modalRoot.visible = true; }
    function close() { modalRoot.visible = false; modalRoot.closed(); }

    Rectangle {
        id: card
        width: Math.min(parent.width - 32, 400)
        height: Math.min(parent.height - 48, 520)
        anchors.centerIn: parent
        radius: 12
        color: "#1E1E2E"
        border.color: "#313244"
        border.width: 1

        MouseArea {
            anchors.fill: parent
            // Chặn click xuyên qua nền backdrop
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Modal Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: modalRoot.title
                    color: "#CDD6F4"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                Text {
                    text: "×"
                    color: "#A6ADC8"
                    font.pixelSize: 20
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modalRoot.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#313244"
            }

            // Body container
            Item {
                id: bodyContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
