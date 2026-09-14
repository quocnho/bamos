import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: aboutDialog
    title: "ℹ️ Giới Thiệu BamOS AI (Troly)"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            height: 70
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                Text { text: "🐶"; font.pixelSize: 28 }
                ColumnLayout {
                    Text { text: "Troly - Native Edge AI Desktop"; color: "#89B4FA"; font.bold: true; font.pixelSize: 13 }
                    Text { text: "Phiên bản: 0.1.0-alpha (C++20 + Qt6 QML)"; color: "#A6ADC8"; font.pixelSize: 11 }
                    Text { text: "Kiến trúc: Clean Architecture (Zero WebKit Overhead)"; color: "#A6E3A1"; font.pixelSize: 11 }
                }
            }
        }

        Text {
            text: "Kế thừa trực tiếp từ gói pkgs/assistant trên hệ thống NixOS Flake. Tối ưu hóa 100% tài nguyên CPU/RAM và sẵn sàng mở rộng sang mô hình 3D Realtime Mascot."
            color: "#CDD6F4"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }

        Button {
            text: "Đóng"
            Layout.alignment: Qt.AlignRight
            onClicked: aboutDialog.close()
        }
    }
}
