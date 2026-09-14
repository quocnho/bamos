import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: modalRoot
    anchors.fill: parent
    color: "#99000000"
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
        width: Math.min(parent.width - 32, 420)
        height: Math.min(parent.height - 48, 540)
        anchors.centerIn: parent
        radius: 14
        color: ThemeManager.cardBg
        border.color: ThemeManager.borderDim
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
                    color: ThemeManager.textPrimary
                    font.bold: true
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                Text {
                    text: "×"
                    color: ThemeManager.textSecondary
                    font.pixelSize: 22
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
                color: ThemeManager.borderDim
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
