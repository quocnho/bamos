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
            Text { text: "Mô hình chính (SLM):"; color: "#CDD6F4"; Layout.fillWidth: true }
            ComboBox {
                model: ["Qwen2.5-3B-Instruct-Q4_K_M", "Qwen2.5-Coder-7B-Q4_K_M", "Llama-3.2-3B-Instruct"]
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Context Window (tokens):"; color: "#CDD6F4"; Layout.fillWidth: true }
            ComboBox {
                model: ["4096 tokens", "8192 tokens", "16384 tokens"]
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "GPU Offload Layers:"; color: "#CDD6F4"; Layout.fillWidth: true }
            SpinBox { from: 0; to: 99; value: 33 }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Nhiệt độ (Temperature):"; color: "#CDD6F4"; Layout.fillWidth: true }
            Text { text: "0.7"; color: "#A6E3A1"; font.bold: true }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "Kiểm tra kết nối"
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Lưu & Khởi Động Lại AI"
                onClicked: llmDialog.close()
            }
        }
    }
}
