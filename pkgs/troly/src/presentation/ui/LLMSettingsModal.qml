import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: llmDialog
    title: "📓 Thiết Lập Mô Hình LLM / SLM (llama.cpp)"

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                Text { text: "🧠"; font.pixelSize: 16 }
                Text {
                    text: "Chạy mô hình lượng hóa GGUF (Q4_K_M / Q8_0) trên llama-server cục bộ, offload GPU Vulkan."
                    color: "#A6ADC8"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Địa chỉ llama-server:"; color: "#CDD6F4"; Layout.fillWidth: true }
            TextField {
                id: serverUrlField
                text: typeof llmVM !== "undefined" ? llmVM.serverUrl : "http://127.0.0.1:9090"
                color: "#CDD6F4"
                background: Rectangle { color: "#313244"; radius: 6 }
                Layout.preferredWidth: 180
                onEditingFinished: {
                    if (typeof llmVM !== "undefined") llmVM.serverUrl = text;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Mô hình MoE Chuyên Biệt:"; color: "#CDD6F4"; Layout.fillWidth: true }
            ComboBox {
                id: modelCombo
                model: typeof llmVM !== "undefined" ? llmVM.availableModels : ["Qwen2.5-3B-Instruct (General)", "Qwen2.5-Coder-7B (Expert Code)", "Llama-3.2-3B (Linux/SysAdmin)", "Qwen2.5-3B-Instruct (Knowledge RAG)"]
                onActivated: function(index) {
                    if (typeof llmVM !== "undefined") llmVM.selectModel(index);
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Ý định đang kích hoạt:"; color: "#CDD6F4"; Layout.fillWidth: true }
            Text {
                text: typeof llmVM !== "undefined" ? llmVM.activeIntent : "GeneralChat"
                color: "#89B4FA"
                font.bold: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Context Window (tokens):"; color: "#CDD6F4"; Layout.fillWidth: true }
            Text {
                text: typeof llmVM !== "undefined" ? (llmVM.contextSize + " tokens") : "4096 tokens"
                color: "#A6ADC8"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "GPU Offload Layers:"; color: "#CDD6F4"; Layout.fillWidth: true }
            SpinBox {
                from: 0; to: 99
                value: typeof llmVM !== "undefined" ? llmVM.gpuLayers : 33
                onValueModified: {
                    if (typeof llmVM !== "undefined") llmVM.gpuLayers = value;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Nhiệt độ (Temperature):"; color: "#CDD6F4"; Layout.fillWidth: true }
            Text {
                text: typeof llmVM !== "undefined" ? Number(llmVM.temperature).toFixed(1) : "0.7"
                color: "#A6E3A1"
                font.bold: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Trạng thái:"; color: "#A6ADC8"; font.pixelSize: 11 }
            Text {
                text: typeof llmVM !== "undefined" ? llmVM.connectionStatus : "Sẵn sàng"
                color: (typeof llmVM !== "undefined" && llmVM.isConnected) ? "#A6E3A1" : "#F38BA8"
                font.pixelSize: 11
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#313244"
        }

        // 📥 Tính năng tải xuống file GGUF lưu trữ vào hệ thống
        Text {
            text: "📥 Tải xuống mô hình GGUF mới:"
            color: "#CDD6F4"
            font.bold: true
            font.pixelSize: 12
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            TextField {
                id: ggufUrlField
                placeholderText: "Nhập URL file .gguf (HuggingFace / Direct link)..."
                color: "#CDD6F4"
                background: Rectangle { color: "#313244"; radius: 6 }
                Layout.fillWidth: true
            }
            Button {
                text: (typeof llmVM !== "undefined" && llmVM.isDownloading) ? "Hủy" : "Tải xuống"
                highlighted: true
                onClicked: {
                    if (typeof llmVM !== "undefined") {
                        if (llmVM.isDownloading) {
                            llmVM.cancelGGUFDownload();
                        } else if (ggufUrlField.text.trim() !== "") {
                            llmVM.downloadGGUFModel(ggufUrlField.text.trim());
                        }
                    }
                }
            }
        }

        // Thanh tiến trình tải xuống
        ColumnLayout {
            Layout.fillWidth: true
            visible: typeof llmVM !== "undefined" && (llmVM.isDownloading || llmVM.downloadProgress > 0)
            spacing: 4

            ProgressBar {
                Layout.fillWidth: true
                value: typeof llmVM !== "undefined" ? llmVM.downloadProgress : 0.0
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: typeof llmVM !== "undefined" ? llmVM.downloadStatus : ""
                    color: "#A6ADC8"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: typeof llmVM !== "undefined" ? Math.round(llmVM.downloadProgress * 100) + "%" : "0%"
                    color: "#A6E3A1"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "Kiểm tra kết nối"
                onClicked: {
                    if (typeof llmVM !== "undefined") llmVM.testConnection();
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Đóng"
                onClicked: llmDialog.close()
            }
        }
    }
}
