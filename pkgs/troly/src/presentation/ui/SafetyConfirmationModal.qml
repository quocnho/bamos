import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: safetyModal
    title: "🛡️ Xác Nhận An Toàn Thực Thi Lệnh (Safety Guard)"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            height: 56
            radius: 8
            color: (typeof actionVM !== "undefined" && actionVM.riskLevel === "Dangerous") ? "#451B20" : "#382D16"
            border.color: (typeof actionVM !== "undefined" && actionVM.riskLevel === "Dangerous") ? "#F38BA8" : "#F9E2AF"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Text {
                    text: (typeof actionVM !== "undefined" && actionVM.riskLevel === "Dangerous") ? "🚨" : "⚠️"
                    font.pixelSize: 22
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: (typeof actionVM !== "undefined" && actionVM.riskLevel === "Dangerous")
                              ? "CẢNH BÁO RỦI RO CAO (DANGEROUS)"
                              : "CẢNH BÁO THẬN TRỌNG (CAUTION)"
                        color: (typeof actionVM !== "undefined" && actionVM.riskLevel === "Dangerous") ? "#F38BA8" : "#F9E2AF"
                        font.bold: true
                        font.pixelSize: 12
                    }
                    Text {
                        text: typeof actionVM !== "undefined" ? actionVM.riskReason : "Lệnh can thiệp sâu hệ thống"
                        color: "#CDD6F4"
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Text {
            text: "Lệnh Shell chuẩn bị được thực thi:"
            color: "#A6ADC8"
            font.pixelSize: 11
        }

        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 6
            color: "#11111B"
            border.color: "#313244"

            ScrollView {
                anchors.fill: parent
                anchors.margins: 8
                Text {
                    text: typeof actionVM !== "undefined" ? actionVM.pendingCommand : "chưa có lệnh"
                    color: "#A6E3A1"
                    font.family: "Monospace"
                    font.pixelSize: 12
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "❌ Từ chối"
                Layout.fillWidth: true
                onClicked: {
                    if (typeof actionVM !== "undefined") actionVM.rejectPendingCommand();
                    safetyModal.close();
                }
            }

            Button {
                text: "✅ Phê chuẩn & Thực thi"
                Layout.fillWidth: true
                onClicked: {
                    if (typeof actionVM !== "undefined") actionVM.confirmPendingCommand();
                    safetyModal.close();
                }
            }
        }
    }
}
