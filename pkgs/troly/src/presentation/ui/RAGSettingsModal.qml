import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: ragDialog
    title: "📚 Thiết Lập Tri Thức RAG (Hybrid FTS5 + Vector)"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

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
                    text: "Hybrid RAG kết hợp FTS5 BM25 + sqlite-vec (FLOAT[384]) qua thuật toán RRF k=60 100% Air-gapped."
                    color: "#A6ADC8"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Động cơ Vector:"; color: "#CDD6F4"; Layout.fillWidth: true }
            Rectangle {
                width: 130
                height: 24
                radius: 4
                color: "#313244"
                Text {
                    anchors.centerIn: parent
                    text: "sqlite-vec (libvec0)"
                    color: "#A6E3A1"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Thuật toán hòa trộn thứ hạng:"; color: "#CDD6F4"; Layout.fillWidth: true }
            Text { text: "Reciprocal Rank Fusion (k=60)"; color: "#89B4FA"; font.bold: true }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Top-K Chunks tra cứu:"; color: "#CDD6F4"; Layout.fillWidth: true }
            SpinBox {
                from: 1; to: 15
                value: typeof ragVM !== "undefined" ? ragVM.topK : 5
                onValueChanged: {
                    if (typeof ragVM !== "undefined") ragVM.setTopK(value)
                }
            }
        }

        // Khung trạng thái lập chỉ mục (Asynchronous Document Ingestion)
        Rectangle {
            Layout.fillWidth: true
            height: 70
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                RowLayout {
                    Text { text: "Trạng thái nạp tài liệu:"; color: "#CDD6F4"; font.pixelSize: 11 }
                    Text {
                        text: (typeof ragVM !== "undefined" && ragVM.isIndexing) ? "Đang quét..." : "Sẵn sàng"
                        color: (typeof ragVM !== "undefined" && ragVM.isIndexing) ? "#F9E2AF" : "#A6E3A1"
                        font.bold: true
                        font.pixelSize: 11
                    }
                }

                Text {
                    text: typeof ragVM !== "undefined" ? ("Đã lập chỉ mục: " + ragVM.indexedFilesCount + " / " + ragVM.totalFilesCount + " tệp (" + ragVM.currentFileName + ")") : "Chưa có tiến trình quét"
                    color: "#A6ADC8"
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: (typeof ragVM !== "undefined" && ragVM.isIndexing) ? "Dừng quét" : "Quét thư mục /etc/nixos"
                onClicked: {
                    if (typeof ragVM !== "undefined") {
                        if (ragVM.isIndexing) ragVM.stopIndexing();
                        else ragVM.startIndexing("/etc/nixos");
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Đóng"
                onClicked: ragDialog.close()
            }
        }
    }
}
