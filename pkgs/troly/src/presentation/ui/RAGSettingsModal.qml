import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: ragDialog
    title: "📚 Thiết Lập Tri Thức RAG (Hybrid FTS5 + Vector)"

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                Text { text: "⚡"; font.pixelSize: 16 }
                Text {
                    text: "SQLite WAL Database với full-text FTS5 và sqlite-vec. Hỗ trợ tra cứu siêu nhanh và tiết kiệm RAM."
                    color: "#A6ADC8"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Mô hình Embedding:"; color: "#CDD6F4"; Layout.fillWidth: true }
            ComboBox {
                model: ["nomic-embed-text-v1.5 (GGUF)", "bge-small-en-v1.5", "all-MiniLM-L6-v2"]
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Top-K Chunks tra cứu:"; color: "#CDD6F4"; Layout.fillWidth: true }
            SpinBox { from: 1; to: 15; value: 5 }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Ngưỡng tương đồng cosine:"; color: "#CDD6F4"; Layout.fillWidth: true }
            Text { text: "0.65"; color: "#89B4FA"; font.bold: true }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "Xoá Index RAG"
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Đóng"
                onClicked: ragDialog.close()
            }
        }
    }
}
