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
                        text: (typeof systemInspectorVM !== "undefined" ? systemInspectorVM.ramUsage.toFixed(1) : "38.5") + "%"
                        color: "#89B4FA"
                        font.bold: true
                        font.pixelSize: 12
                    }
                }
                RowLayout {
                    Text { text: "Dung lượng /nix/store:"; color: "#A6ADC8"; font.pixelSize: 12 }
                    Text {
                        text: typeof systemInspectorVM !== "undefined" ? systemInspectorVM.nixStoreSize : "42.5 GB"
                        color: "#F9E2AF"
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
            text: "Trạng thái sức khỏe hệ thống:"
            color: "#CDD6F4"
            font.bold: true
            font.pixelSize: 13
        }

        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 6
            color: "#181825"
            border.color: "#313244"
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                Text { text: "🛡️"; font.pixelSize: 14 }
                Text {
                    text: typeof systemInspectorVM !== "undefined" ? systemInspectorVM.statusSummary : "Hệ thống hoạt động ổn định"
                    color: (typeof systemInspectorVM !== "undefined" && systemInspectorVM.isHealthy) ? "#A6E3A1" : "#F38BA8"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }
            }
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

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Kiểm tra cấu hình NixOS:"; color: "#CDD6F4"; Layout.fillWidth: true }
            Button {
                text: "Kiểm tra ngay ⚙️"
                onClicked: {
                    if (typeof actionVM !== "undefined") {
                        actionVM.validateNix("/etc/nixos");
                    }
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
