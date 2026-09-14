import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    title: "Trợ Lý BamOS (C++20 Native Edge AI)"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    readonly property bool peekActive: typeof chatVM !== "undefined" ? chatVM.isPeekMode : false

    // Kích thước co giãn linh hoạt (Morphing) giữa Full Chat và Peek Tail
    width: peekActive ? 84 : 480
    height: peekActive ? 120 : 680

    Behavior on width {
        NumberAnimation { duration: 320; easing.type: Easing.OutBack }
    }
    Behavior on height {
        NumberAnimation { duration: 320; easing.type: Easing.OutBack }
    }

    // 🐾 VÙNG 1: PEEK TAIL WIDGET (Chế độ Núp Lùm Thò Đuôi Mép Màn Hình)
    Rectangle {
        id: peekContainer
        anchors.fill: parent
        visible: root.peekActive
        radius: 20
        color: "#E6181825"
        border.color: "#89B4FA"
        border.width: 1.5

        Item {
            id: tailActor
            anchors.centerIn: parent
            width: 70
            height: 70
            transformOrigin: Item.BottomRight

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "../../../assets/pet/cho chao.png"
                smooth: true
            }

            // Disney Easing: Đuôi vẫy đung đưa nhịp nhàng liên tục
            SequentialAnimation {
                running: root.peekActive
                loops: Animation.Infinite
                PropertyAnimation {
                    target: tailActor
                    property: "rotation"
                    from: -12
                    to: 16
                    duration: 480
                    easing.type: Easing.InOutQuad
                }
                PropertyAnimation {
                    target: tailActor
                    property: "rotation"
                    from: 16
                    to: -12
                    duration: 480
                    easing.type: Easing.InOutQuad
                }
            }

            // Tương tác chuột: Click đuôi cún ➔ Thức giấc, vồ chuột & bung mở cửa sổ
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof chatVM !== "undefined") {
                        chatVM.wakeFromPeek();
                    }
                }
            }
        }

        // Nhãn nhỏ mời gọi click
        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 6
            text: "Gâu! 🐾"
            font.bold: true
            font.pixelSize: 11
            color: "#A6E3A1"
        }
    }

    // 💬 VÙNG 2: FULL CHAT & SETTINGS WINDOW
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        visible: !root.peekActive
        radius: 16
        color: "#E61E1E2E" // Catppuccin Mocha Fluent Glassmorphism
        border.color: isWindowDropHover ? "#A6E3A1" : "#313244"
        border.width: isWindowDropHover ? 2 : 1

        property bool isWindowDropHover: false

        // DropArea toàn bộ cửa sổ nhận file/thư mục kéo thả từ Nautilus (Phương án A)
        DropArea {
            anchors.fill: parent
            onEntered: function(drag) {
                if (drag.hasUrls) {
                    bgContainer.isWindowDropHover = true;
                }
            }
            onExited: {
                bgContainer.isWindowDropHover = false;
            }
            onDropped: function(drop) {
                bgContainer.isWindowDropHover = false;
                if (drop.hasUrls && drop.urls.length > 0) {
                    var urlStr = drop.urls[0].toString();
                    if (urlStr.indexOf("file://") === 0) {
                        urlStr = urlStr.substring(7);
                    }
                    // Nếu là tệp có đuôi mở rộng -> Đính kèm vào thanh đính kèm
                    if (urlStr.indexOf(".") !== -1 && urlStr.lastIndexOf(".") > urlStr.lastIndexOf("/")) {
                        attachedBar.attachedFilePath = urlStr;
                    } else {
                        // Nếu là thư mục -> Gán vào bối cảnh thư mục Bone Context
                        boneContextBar.currentPath = urlStr;
                    }
                }
            }
        }

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
                    text: "RAM: " + (typeof systemMonitorVM !== "undefined" ? systemMonitorVM.ramUsage.toFixed(1) : "38.5") + "%"
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

                // Nút 🐾 Núp Lùm Thò Đuôi Mép Màn Hình
                Button {
                    text: "🐾"
                    flat: true
                    ToolTip.visible: hovered
                    ToolTip.text: "Núp lùm thò đuôi (Peek Tail)"
                    onClicked: {
                        if (typeof chatVM !== "undefined") {
                            chatVM.togglePeekMode();
                        }
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
                            var state = typeof chatVM !== "undefined" ? chatVM.mascotState : "idle";
                            if (state === "excited" || state === "playful_jump") return "../../../assets/pet/cho nhay.png";
                            if (state === "sleep") return "../../../assets/pet/cho ngu.png";
                            if (state === "greeting") return "../../../assets/pet/cho chao.png";
                            return "../../../assets/pet/cho dung.png";
                        }
                    }

                    // 12 Nguyên tắc hoạt hình Disney: Squash & Stretch nhịp thở tự nhiên (Idle Breathing)
                    SequentialAnimation {
                        id: idleAnim
                        running: (typeof chatVM !== "undefined" ? chatVM.mascotState : "idle") === "idle"
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

                    // Playful Jump & Excited Bounce khi cún đón trỏ chuột hoặc AI suy nghĩ
                    SequentialAnimation {
                        id: excitedAnim
                        running: typeof chatVM !== "undefined" && (chatVM.mascotState === "excited" || chatVM.mascotState === "playful_jump")
                        loops: (typeof chatVM !== "undefined" && chatVM.mascotState === "playful_jump") ? 2 : Animation.Infinite
                        onFinished: {
                            if (typeof chatVM !== "undefined" && chatVM.mascotState === "playful_jump") {
                                chatVM.setMascotState("idle");
                            }
                        }
                        ParallelAnimation {
                            PropertyAnimation {
                                target: petActor
                                property: "y"
                                to: -14
                                duration: 280
                                easing.type: Easing.OutQuad
                            }
                            PropertyAnimation {
                                target: petActor
                                property: "scale"
                                to: 1.12
                                duration: 280
                                easing.type: Easing.OutBack
                            }
                        }
                        ParallelAnimation {
                            PropertyAnimation {
                                target: petActor
                                property: "y"
                                to: 0
                                duration: 260
                                easing.type: Easing.InQuad
                            }
                            PropertyAnimation {
                                target: petActor
                                property: "scale"
                                to: 1.0
                                duration: 260
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
                            if (typeof chatVM !== "undefined") {
                                chatVM.setMascotState(chatVM.mascotState === "greeting" ? "idle" : "greeting");
                            }
                        }
                    }
                }

                // Bong bóng thoại chào mừng
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 10
                    width: greetingText.implicitWidth + 14
                    height: 24
                    radius: 12
                    color: "#313244"
                    border.color: "#89B4FA"
                    border.width: 1
                    visible: typeof chatVM !== "undefined" && (chatVM.mascotState === "greeting" || chatVM.mascotState === "playful_jump")

                    Text {
                        id: greetingText
                        anchors.centerIn: parent
                        text: typeof chatVM !== "undefined" ? chatVM.mascotGreeting : "Gâu gâu! Em chào chủ nhân ạ! 🐾"
                        font.pixelSize: 11
                        color: "#CDD6F4"
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
                        color: (typeof chatVM !== "undefined" && chatVM.isGenerating) ? "#F9E2AF" : ((typeof chatVM !== "undefined" && chatVM.mascotState === "sleep") ? "#6C7086" : "#A6E3A1")
                    }

                    Text {
                        text: {
                            var state = typeof chatVM !== "undefined" ? chatVM.mascotState : "idle";
                            if (state === "excited") return "Đang suy nghĩ...";
                            if (state === "playful_jump") return "Gâu gâu! Em đây!";
                            if (state === "greeting") return "Chào bạn!";
                            if (state === "sleep") return "Đang ngủ (0% CPU)";
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
                model: typeof chatVM !== "undefined" ? chatVM.messageHistory : []
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
                visible: typeof chatVM !== "undefined" && chatVM.isGenerating
                color: "#181825"
                radius: 8

                Text {
                    anchors.centerIn: parent
                    text: "Đang suy nghĩ... " + (typeof chatVM !== "undefined" ? chatVM.currentStreamingText : "")
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
                    if (typeof chatVM !== "undefined") {
                        chatVM.sendMessage(query);
                    }
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
                            if (typeof chatVM !== "undefined") {
                                chatVM.sendMessage(prompt);
                            }
                            text = "";
                        }
                    }
                }

                Button {
                    text: (typeof chatVM !== "undefined" && chatVM.isGenerating) ? "Dừng" : "Gửi"
                    onClicked: {
                        if (typeof chatVM !== "undefined") {
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

        // Lớp phủ thông báo & bài tập mắt EyeLeo
        EyeLeoBreakOverlay { id: eyeleoOverlay }
    }
}
