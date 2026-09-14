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
                    Text {
                        text: (typeof systemMonitorVM !== "undefined" ? systemMonitorVM.ramUsage.toFixed(1) : "38.5") + "%"
                        color: "#89B4FA"
                        font.bold: true
                        font.pixelSize: 12
                    }
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

        RowLayout {
            Layout.fillWidth: true
            Text { text: "llama.cpp Local Server:"; color: "#CDD6F4"; Layout.fillWidth: true }
            Rectangle {
                width: 80
                height: 24
                radius: 6
                color: "#313244"
                Text {
                    anchors.centerIn: parent
                    text: "Đang chạy"
                    color: "#A6E3A1"
                    font.pixelSize: 11
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Hybrid Vector DB (SQLite WAL):"; color: "#CDD6F4"; Layout.fillWidth: true }
            Rectangle {
                width: 80
                height: 24
                radius: 6
                color: "#313244"
                Text {
                    anchors.centerIn: parent
                    text: "Sẵn sàng"
                    color: "#89B4FA"
                    font.pixelSize: 11
                }
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
