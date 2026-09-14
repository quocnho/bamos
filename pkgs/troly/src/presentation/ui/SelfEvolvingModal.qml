import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: evolvingModal
    title: "🧬 Trung Tâm Tự Tiến Hóa (Self-Evolving Hub)"

    property var vm: typeof selfEvolvingVM !== "undefined" ? selfEvolvingVM : null

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: "Cơ chế tự tiến hóa 100% Offline (Air-gapped). Tinh chỉnh LoRA Adapter từ các phiên đối thoại mẫu vàng đạt chuẩn của bạn trên hệ thống NixOS."
            font.pixelSize: 12
            color: "#A6ADC8"
            wrapMode: Text.WordWrap
        }

        // Bảng trạng thái Dataset
        Rectangle {
            Layout.fillWidth: true
            height: 120
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "📦 Tổng mẫu vàng thu hoạch:"; color: "#CDD6F4"; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    Text { 
                        text: (evolvingModal.vm ? evolvingModal.vm.totalSamples : 4) + " tương tác"
                        color: "#89B4FA"; font.bold: true; font.pixelSize: 12 
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "⏳ Mẫu chờ huấn luyện:"; color: "#CDD6F4"; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    Text { 
                        text: (evolvingModal.vm ? evolvingModal.vm.pendingSamples : 4) + " mẫu"
                        color: "#F9E2AF"; font.bold: true; font.pixelSize: 12 
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "🕒 Lần cập nhật trọng số gần nhất:"; color: "#CDD6F4"; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    Text { 
                        text: evolvingModal.vm ? evolvingModal.vm.lastTrainedDate : "Chưa huấn luyện"
                        color: "#A6ADC8"; font.pixelSize: 11 
                    }
                }
            }
        }

        // Thông tin Tiến độ Huấn luyện
        Rectangle {
            Layout.fillWidth: true
            height: 110
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Text {
                    text: "Trạng thái Pipeline:"
                    color: "#CDD6F4"
                    font.bold: true
                    font.pixelSize: 12
                }

                Text {
                    id: statusLabel
                    Layout.fillWidth: true
                    text: evolvingModal.vm ? evolvingModal.vm.statusText : "Sẵn sàng (Idle)"
                    color: "#A6E3A1"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: "Current Loss: " + (evolvingModal.vm ? evolvingModal.vm.currentLoss.toFixed(4) : "0.0000")
                    color: "#F38BA8"
                    font.pixelSize: 11
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Nút hành động
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                Layout.fillWidth: true
                text: "📥 Xuất ChatML Dataset"
                onClicked: {
                    if (evolvingModal.vm) {
                        evolvingModal.vm.exportDataset("/tmp/troly_train_data.txt");
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                text: "⚡ Chạy Tinh Chỉnh LoRA"
                highlighted: true
                onClicked: {
                    if (evolvingModal.vm) {
                        evolvingModal.vm.triggerOfflineTraining();
                    }
                }
            }
        }
    }
}
