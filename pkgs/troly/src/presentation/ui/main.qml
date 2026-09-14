import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    title: "Trợ Lý BamOS (C++20 Native Edge AI)"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    readonly property bool peekActive: typeof chatVM !== "undefined" ? chatVM.isPeekMode : true

    // Khởi tạo kích thước: Khi ở chế độ Mascot Pet thì nhỏ gọn 140x160 không viền hộp vuông
    width: peekActive ? 140 : 480
    height: peekActive ? 170 : 680

    Behavior on width {
        NumberAnimation { duration: 320; easing.type: Easing.OutBack }
    }
    Behavior on height {
        NumberAnimation { duration: 320; easing.type: Easing.OutBack }
    }

    // 📍 ĐỊNH VỊ TỌA ĐỘ BAN ĐẦU & KHÔI PHỤC VỊ TRÍ ĐÃ LƯU
    Component.onCompleted: {
        var screenW = Screen.desktopAvailableWidth;
        var screenH = Screen.desktopAvailableHeight;
        var defaultX = screenW - 160;
        var defaultY = screenH - 220;

        if (typeof chatVM !== "undefined") {
            var pos = chatVM.getSavedMascotPosition(defaultX, defaultY);
            root.x = pos.x;
            root.y = pos.y;
            // Tự động chào mừng nhí nhảnh khi khởi chạy
            chatVM.setPeekMode(true);
            chatVM.playSound("bark");
        } else {
            root.x = defaultX;
            root.y = defaultY;
        }
    }

    // 🐾 VÙNG 1: FLOATING 3D MASCOT PET (Không viền hộp vuông, nền trong suốt hoàn toàn)
    Item {
        id: peekContainer
        anchors.fill: parent
        visible: root.peekActive

        // Bong bóng thoại chào hỏi trên đầu chú cún
        Rectangle {
            id: mascotBubble
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(200, bubbleText.implicitWidth + 20)
            height: bubbleText.implicitHeight + 14
            radius: 12
            color: "#E6181825"
            border.color: "#89B4FA"
            border.width: 1.5
            visible: bubbleOpacityAnim.running || bubbleText.text !== ""
            opacity: 1.0

            Text {
                id: bubbleText
                anchors.centerIn: parent
                text: {
                    var honorific = typeof userProfileVM !== "undefined" ? userProfileVM.addressing : "Chủ nhân";
                    return "Xin chào " + honorific + ",\nchúc một ngày vui! Gâu gâu! 🐾";
                }
                font.bold: true
                font.pixelSize: 11
                color: "#A6E3A1"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            SequentialAnimation {
                id: bubbleOpacityAnim
                running: root.peekActive
                PauseAnimation { duration: 6000 }
                NumberAnimation { target: mascotBubble; property: "opacity"; to: 0.0; duration: 800 }
            }
        }

        // Chú cún 3D Stylized không có viền hộp bao quanh
        Mascot3DPOC {
            id: floating3dPet
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 8
            width: 120
            height: 120

            // Hoạt cảnh nhảy tung tăng khi xuất hiện
            SequentialAnimation {
                id: initialJumpAnim
                running: root.peekActive
                ParallelAnimation {
                    PropertyAnimation { target: floating3dPet; property: "y"; to: -16; duration: 250; easing.type: Easing.OutQuad }
                    PropertyAnimation { target: floating3dPet; property: "scale"; to: 1.15; duration: 250; easing.type: Easing.OutBack }
                }
                ParallelAnimation {
                    PropertyAnimation { target: floating3dPet; property: "y"; to: 0; duration: 250; easing.type: Easing.InQuad }
                    PropertyAnimation { target: floating3dPet; property: "scale"; to: 1.0; duration: 250; easing.type: Easing.OutBounce }
                }
            }
        }

        // Kéo thả tự do chú chó đến bất kỳ vị trí nào trên màn hình & Lưu tọa độ
        MouseArea {
            id: petDragArea
            anchors.fill: parent
            cursorShape: Qt.SizeAllCursor
            property point clickPos: "0,0"

            onPressed: function(mouse) {
                clickPos = Qt.point(mouse.x, mouse.y);
            }

            onPositionChanged: function(mouse) {
                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y);
                root.x += delta.x;
                root.y += delta.y;
            }

            onReleased: {
                if (typeof chatVM !== "undefined") {
                    chatVM.saveMascotPosition(root.x, root.y);
                }
            }

            onDoubleClicked: {
                // Nhấp đúp vào cún để mở rộng Full Chat
                if (typeof chatVM !== "undefined") {
                    chatVM.wakeFromPeek();
                }
            }
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

                // Trạng thái cún con nhỏ gọn bên góc & Nút chuyển chế độ 3D POC
                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 8
                    spacing: 6

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

                    Button {
                        text: mascot3dView.visible ? "2D" : "3D"
                        flat: true
                        font.pixelSize: 10
                        onClicked: {
                            mascot3dView.visible = !mascot3dView.visible;
                            petActor.visible = !mascot3dView.visible;
                        }
                    }
                }

                // Mascot 3D Stylized Mesh POC
                Mascot3DPOC {
                    id: mascot3dView
                    anchors.centerIn: parent
                    visible: false
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
                else if (panel === "evolving") evolvingModal.open();
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
        SelfEvolvingModal { id: evolvingModal }
        SystemInspectorModal { id: systemModal }
        WakaTrackerModal { id: wakaModal }
        ProfileModal { id: profileModal }
        AboutModal { id: aboutModal }
        SafetyConfirmationModal {
            id: safetyConfirmationModal
            visible: typeof actionVM !== "undefined" && actionVM.confirmationRequired
        }

        // Lớp phủ thông báo & bài tập mắt EyeLeo
        EyeLeoBreakOverlay { id: eyeleoOverlay }
    }
}
