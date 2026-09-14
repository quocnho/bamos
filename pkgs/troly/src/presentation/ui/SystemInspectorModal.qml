import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: systemDialog
    title: "🛡️ Giám Sát Hệ Thống & NixOS"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            height: 60
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                RowLayout {
                    Text { text: "RAM Sử Dụng:"; color: "#A6ADC8"; font.pixelSize: 12 }
                    Text { text: systemMonitorVM.ramUsage.toFixed(1) + "%"; color: "#89B4FA"; font.bold: true; font.pixelSize: 12 }
                }
                RowLayout {
                    Text { text: "Hệ điều hành:"; color: "#A6ADC8"; font.pixelSize: 12 }
                    Text { text: "BamOS (NixOS Flake C++20 Native)"; color: "#A6E3A1"; font.pixelSize: 12 }
                }
            }
        }

        Text {
            text: "Quản lý Dịch vụ Edge AI:"
            color: "#CDD6F4"
            font.bold: true
            font.pixelSize: 13
        }

        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 6
            color: "#181825"
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                Text { text: "llama-server.service"; color: "#CDD6F4"; Layout.fillWidth: true }
                Text { text: "Đang chạy (Active)"; color: "#A6E3A1"; font.pixelSize: 11 }
            }
        }

        Item { Layout.fillHeight: true }

        Button {
            text: "Đóng"
            Layout.alignment: Qt.AlignRight
            onClicked: systemDialog.close()
        }
    }
}
