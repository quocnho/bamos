import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 480
    height: 680
    title: "Trợ Lý BamOS (C++20 Native Edge AI)"
    flags: Qt.Window | Qt.FramelessWindowHint

    color: "transparent"

    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: 16
        color: "#E61E1E2E" // Catppuccin Mocha Fluent Glassmorphism
        border.color: "#313244"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header Bar & Window Controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "🐶 Trợ Lý BamOS"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#CDD6F4"
                }

                Rectangle {
                    height: 18
                    radius: 4
                    color: "#313244"
                    implicitWidth: subBadge.implicitWidth + 8
                    Text {
                        id: subBadge
                        anchors.centerIn: parent
                        text: "Offline C++20"
                        font.pixelSize: 10
                        color: "#A6E3A1"
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "RAM: " + systemMonitorVM.ramUsage.toFixed(1) + "%"
                    font.pixelSize: 11
                    color: "#A6ADC8"
                }

                Button {
                    id: btnSettings
                    text: "⚙️"
                    flat: true
                    onClicked: {
                        quickMenu.x = btnSettings.x - quickMenu.width + btnSettings.width;
                        quickMenu.y = btnSettings.y + btnSettings.height + 4;
                        quickMenu.visible = !quickMenu.visible;
                    }
                }

                Button {
                    text: "—"
                    flat: true
                    onClicked: root.showMinimized()
                }

                Button {
                    text: "×"
                    flat: true
                    onClicked: Qt.quit()
                }
            }

            // Thanh bối cảnh Thư mục (Bone Context Bar)
            BoneContextBar {
                id: boneContextBar
                Layout.fillWidth: true
                currentPath: "/etc/nixos"
            }

            // Thanh xem trước tệp đính kèm (+)
            AttachedPreviewBar {
                id: attachedBar
                Layout.fillWidth: true
            }

            // Mascot Pet Banner with Disney Animation & FSM
            Rectangle {
                id: mascotContainer
                Layout.fillWidth: true
                height: 130
                radius: 12
                color: "#181825"
                border.color: "#313244"
                border.width: 1
                clip: true

                Item {
                    id: petActor
                    anchors.centerIn: parent
                    width: 100
                    height: 100
                    transformOrigin: Item.Bottom

                    Image {
                        id: petImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: {
                            var state = chatVM.mascotState;
                            if (state === "excited") return "../../../assets/pet/cho nhay.svg";
                            if (state === "sleep") return "../../../assets/pet/cho ngu.svg";
                            if (state === "greeting") return "../../../assets/pet/cho chao.svg";
                            return "../../../assets/pet/cho dung.svg";
                        }
                    }

                    // 12 Nguyên tắc hoạt hình: Squash & Stretch nhịp thở tự nhiên (Idle Breathing)
                    SequentialAnimation {
                        id: idleAnim
                        running: chatVM.mascotState === "idle"
                        loops: Animation.Infinite
                        PropertyAnimation {
                            target: petActor
                            property: "scale"
                            from: 1.0
                            to: 1.04
                            duration: 1800
                            easing.type: Easing.InOutQuad
                        }
                        PropertyAnimation {
                            target: petActor
                            property: "scale"
                            from: 1.04
                            to: 1.0
                            duration: 1800
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // Anticipation & Excited Bounce khi đang suy nghĩ / trả lời
                    SequentialAnimation {
                        id: excitedAnim
                        running: chatVM.mascotState === "excited"
                        loops: Animation.Infinite
                        ParallelAnimation {
                            PropertyAnimation {
                                target: petActor
                                property: "y"
                                to: -8
                                duration: 320
                                easing.type: Easing.OutQuad
                            }
                            PropertyAnimation {
                                target: petActor
                                property: "scale"
                                to: 1.08
                                duration: 320
                                easing.type: Easing.OutBack
                            }
                        }
                        ParallelAnimation {
                            PropertyAnimation {
                                target: petActor
                                property: "y"
                                to: 0
                                duration: 280
                                easing.type: Easing.InQuad
                            }
                            PropertyAnimation {
                                target: petActor
                                property: "scale"
                                to: 1.0
                                duration: 280
                                easing.type: Easing.OutBounce
                            }
                        }
                    }

                    // Tương tác chạm chuột (Pet Poke Interaction)
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            chatVM.setMascotState(chatVM.mascotState === "greeting" ? "idle" : "greeting");
                        }
                    }
                }

                // Trạng thái cún con nhỏ gọn bên góc
                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 8
                    spacing: 4

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: chatVM.isGenerating ? "#F9E2AF" : (chatVM.mascotState === "sleep" ? "#6C7086" : "#A6E3A1")
                    }

                    Text {
                        text: {
                            if (chatVM.mascotState === "excited") return "Đang suy nghĩ...";
                            if (chatVM.mascotState === "greeting") return "Chào bạn!";
                            if (chatVM.mascotState === "sleep") return "Đang ngủ (0% CPU)";
                            return "Sẵn sàng hỗ trợ";
                        }
                        font.pixelSize: 10
                        color: "#A6ADC8"
                    }
                }
            }

            // Message History View
            ListView {
                id: chatListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: chatVM.messageHistory
                spacing: 8

                delegate: Rectangle {
                    required property var modelData
                    width: chatListView.width
                    height: contentCol.height + 16
                    radius: 8
                    color: modelData.role === "user" ? "#45475A" : "#313244"

                    Column {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Text {
                            text: modelData.role === "user" ? "Chủ nhân" : "Trợ Lý"
                            font.bold: true
                            font.pixelSize: 11
                            color: modelData.role === "user" ? "#89B4FA" : "#A6E3A1"
                        }

                        Text {
                            text: modelData.content
                            color: "#CDD6F4"
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                            width: parent.width
                        }
                    }
                }
            }

            // Streaming Indicator
            Rectangle {
                Layout.fillWidth: true
                height: 36
                visible: chatVM.isGenerating
                color: "#181825"
                radius: 8

                Text {
                    anchors.centerIn: parent
                    text: "Đang suy nghĩ... " + chatVM.currentStreamingText
                    color: "#F9E2AF"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    width: parent.width - 16
                }
            }

            // Smart Suggestion Chips
            SmartSuggestionsChips {
                Layout.fillWidth: true
                onChipSelected: function(query) {
                    inputField.text = query;
                    chatVM.sendMessage(query);
                    inputField.text = "";
                }
            }

            // Input Bar & Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "+"
                    implicitWidth: 36
                    onClicked: {
                        attachedBar.attachedFilePath = "/etc/nixos/pkgs/assistant/README.md";
                    }
                }

                TextField {
                    id: inputField
                    Layout.fillWidth: true
                    placeholderText: "Hỏi em, dán link hoặc chạy lệnh... (Enter)"
                    color: "#CDD6F4"
                    onAccepted: {
                        if (text.trim() !== "") {
                            var prompt = text;
                            if (attachedBar.attachedFilePath !== "") {
                                prompt = "[Tệp đính kèm: " + attachedBar.attachedFilePath + "]\n" + prompt;
                            }
                            if (boneContextBar.currentPath !== "") {
                                prompt = "[Bối cảnh: " + boneContextBar.currentPath + "]\n" + prompt;
                            }
                            chatVM.sendMessage(prompt);
                            text = "";
                        }
                    }
                }

                Button {
                    text: chatVM.isGenerating ? "Dừng" : "Gửi"
                    onClicked: {
                        if (chatVM.isGenerating) {
                            chatVM.abortGeneration();
                        } else if (inputField.text.trim() !== "") {
                            var prompt = inputField.text;
                            if (attachedBar.attachedFilePath !== "") {
                                prompt = "[Tệp đính kèm: " + attachedBar.attachedFilePath + "]\n" + prompt;
                            }
                            if (boneContextBar.currentPath !== "") {
                                prompt = "[Bối cảnh: " + boneContextBar.currentPath + "]\n" + prompt;
                            }
                            chatVM.sendMessage(prompt);
                            inputField.text = "";
                        }
                    }
                }
            }
        }

        // Quick Action Context Menu
        QuickActionMenu {
            id: quickMenu
            onPanelRequested: function(panel) {
                if (panel === "eyeleo") eyeleoModal.open();
                else if (panel === "rag") ragModal.open();
                else if (panel === "llm") llmModal.open();
                else if (panel === "system") systemModal.open();
                else if (panel === "waka") wakaModal.open();
                else if (panel === "profile") profileModal.open();
                else if (panel === "about") aboutModal.open();
            }
        }

        // Modals kế thừa từ assistant
        EyeLeoSettingsModal { id: eyeleoModal }
        RAGSettingsModal { id: ragModal }
        LLMSettingsModal { id: llmModal }
        SystemInspectorModal { id: systemModal }
        WakaTrackerModal { id: wakaModal }
        ProfileModal { id: profileModal }
        AboutModal { id: aboutModal }
    }
}
