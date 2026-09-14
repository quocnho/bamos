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
            color: ThemeManager.cardBg
            border.color: ThemeManager.borderDim
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                Text { text: "⚡"; font.pixelSize: 16 }
                Text {
                    text: "Hybrid RAG kết hợp FTS5 BM25 + sqlite-vec (FLOAT[384]) qua thuật toán RRF k=60 100% Air-gapped."
                    color: ThemeManager.textSecondary
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Động cơ Vector:"; color: ThemeManager.textPrimary; Layout.fillWidth: true }
            Rectangle {
                width: 130
                height: 24
                radius: 4
                color: ThemeManager.inputBg
                border.color: ThemeManager.borderDim
                Text {
                    anchors.centerIn: parent
                    text: "sqlite-vec (libvec0)"
                    color: ThemeManager.primaryAccent
                    font.bold: true
                    font.pixelSize: 11
                }
            }
        }

        // ⚖️ Cân bằng Tìm kiếm Lai (Hybrid Search Alpha) - Giống assistant
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "⚖️ Trọng số tìm kiếm lai (Hybrid Search):"
                    color: ThemeManager.textPrimary
                    font.bold: true
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(alphaSlider.value * 100) + "% Vector (Ngữ nghĩa)"
                    color: ThemeManager.primaryAccent
                    font.bold: true
                    font.pixelSize: 11
                }
            }

            Text {
                text: "Kéo sang trái: ưu tiên từ khóa FTS5 chính xác (code, log) • Kéo sang phải: ưu tiên ngữ nghĩa vector sqlite-vec"
                color: ThemeManager.textSubtle
                font.pixelSize: 10
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Slider {
                id: alphaSlider
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                stepSize: 0.05
                value: typeof ragVM !== "undefined" ? ragVM.hybridAlpha : 0.65
                onMoved: {
                    if (typeof ragVM !== "undefined") ragVM.setHybridAlpha(value);
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Top-K Chunks tra cứu mỗi câu hỏi:"; color: ThemeManager.textPrimary; Layout.fillWidth: true }
            SpinBox {
                from: 1; to: 15
                value: typeof ragVM !== "undefined" ? ragVM.topK : 4
                onValueChanged: {
                    if (typeof ragVM !== "undefined") ragVM.setTopK(value)
                }
            }
        }

        // DropZone nạp tài liệu mới (Dropzone kéo thả tệp/thư mục)
        Rectangle {
            id: dropZoneRect
            Layout.fillWidth: true
            height: 64
            radius: 8
            color: isHovering ? ThemeManager.headerBg : ThemeManager.cardBg
            border.color: isHovering ? ThemeManager.borderActive : ThemeManager.borderDim
            border.width: isHovering ? 2 : 1

            property bool isHovering: false

            DropArea {
                anchors.fill: parent
                onEntered: function(drag) {
                    if (drag.hasUrls) dropZoneRect.isHovering = true;
                }
                onExited: {
                    dropZoneRect.isHovering = false;
                }
                onDropped: function(drop) {
                    dropZoneRect.isHovering = false;
                    if (drop.hasUrls && drop.urls.length > 0 && typeof ragVM !== "undefined") {
                        var path = drop.urls[0].toString();
                        if (path.indexOf("file://") === 0) path = path.substring(7);
                        ragVM.startIndexing(path);
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    text: "📁 Kéo thả tài liệu / thư mục vào đây để nạp tri thức"
                    color: ThemeManager.textPrimary
                    font.bold: true
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Hỗ trợ tệp mã nguồn (.cpp, .nix, .md, .py, .txt, .json, .sh...)"
                    color: ThemeManager.textSubtle
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Khung trạng thái lập chỉ mục (Asynchronous Document Ingestion)
        Rectangle {
            Layout.fillWidth: true
            height: 60
            radius: 8
            color: ThemeManager.inputBg
            border.color: ThemeManager.borderDim
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                RowLayout {
                    Text { text: "Trạng thái nạp:"; color: ThemeManager.textPrimary; font.pixelSize: 11 }
                    Text {
                        text: (typeof ragVM !== "undefined" && ragVM.isIndexing) ? "Đang lập chỉ mục..." : "Sẵn sàng"
                        color: (typeof ragVM !== "undefined" && ragVM.isIndexing) ? ThemeManager.secondaryAccent : ThemeManager.primaryAccent
                        font.bold: true
                        font.pixelSize: 11
                    }
                }

                Text {
                    text: typeof ragVM !== "undefined" ? ("Đã lập chỉ mục: " + ragVM.indexedFilesCount + " / " + ragVM.totalFilesCount + " tệp (" + ragVM.currentFileName + ")") : "Chưa có tiến trình quét"
                    color: ThemeManager.textSecondary
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
                text: (typeof ragVM !== "undefined" && ragVM.isIndexing) ? "Dừng quét" : "Nạp tri thức /etc/nixos"
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
