import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: profileDialog
    title: "👤 Hồ Sơ & Đánh Giá Năng Lực"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            height: 52
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                Text { text: "🧑‍💻"; font.pixelSize: 18 }
                ColumnLayout {
                    Text { text: "Xưng hô: Chủ nhân (quocnho)"; color: "#CDD6F4"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Lĩnh vực quan tâm: C++20 Systems, NixOS, Edge AI"; color: "#A6ADC8"; font.pixelSize: 11 }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Cách xưng hô:"; color: "#CDD6F4"; Layout.fillWidth: true }
            TextField {
                text: "Chủ nhân"
                color: "#CDD6F4"
            }
        }

        Item { Layout.fillHeight: true }

        Button {
            text: "Cập nhật Hồ sơ"
            Layout.alignment: Qt.AlignRight
            onClicked: profileDialog.close()
        }
    }
}
